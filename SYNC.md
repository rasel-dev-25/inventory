# Offline sync engine (M1)

This is the design ARCHITECTURE.md's introduction points at. It covers
the outbox pusher, the cursor-based puller, and the conflict-resolution
policy each one uses — the three pieces after the M1 auth work
(`lib/features/auth/`) and the Postgres schema (`supabase/migrations/`).

## Why an outbox, not "just write to Supabase directly"

This app is offline-first: every local write happens against the local
Drift database (`lib/data/local/`) immediately, unconditionally,
regardless of connectivity. A local write is never blocked on, or
rolled back because of, a failed network call. Getting that data to
Supabase is a *separate*, retryable concern — the outbox pattern.

- **`SyncOutboxEntries`** (`lib/data/local/tables/sync.dart`) is the
  queue: one row per local business event, not per table row. A use case
  that (say) records a purchase trip resolves the trip/items/other-costs
  writes into concrete row payloads once, writes them to the local DB in
  one transaction (see `PurchaseDao.saveTrip`'s doc comment), and
  enqueues the same resolved payload as one outbox entry. The server
  never re-derives the business rule; it just applies rows.
- **`idempotencyKey`** is generated once per event and reused across
  every retry, so a flaky connection can never cause the same event to
  apply twice — see "Idempotency" below.

## The push side: `SyncPushService` + `apply_outbox_event`

`lib/data/sync/sync_push_service.dart` drains
`SyncMetadataDao.pendingEntries()` in `createdAt` order, one at a time,
and for each:

1. Marks the row `inFlight` (so a concurrent "sync now" tap can't
   double-send it).
2. Decodes its `payloadJson` into a list of `{table, row}` upserts
   (`lib/data/sync/outbox_event.dart`).
3. Runs every row through `ShopIdBridge.toRemote` (see "The shop_id
   bridge" below).
4. Calls the `apply_outbox_event` RPC
   (`supabase/migrations/0008_outbox_sync_rpc.sql`) with the event's
   `idempotencyKey` and the substituted upserts.
5. On success, deletes the outbox row (nothing left to retry — the
   server's own `processed_outbox_events` ledger is the permanent record
   an event happened, the local outbox row only needs to exist until
   it's sent). On failure, increments `attemptCount`, records
   `lastError`, and sets status back to `failed` so the next
   `pushPending()` call retries it.

Entries are processed strictly in order and one push waits for the
previous one to finish — a due-payment event on a customer must never
apply before the sale event that created the due, and
`apply_outbox_event`'s idempotency check only protects against retrying
the *same* event, not against two different events landing out of order.

### Why one generic RPC instead of one per business event

`apply_outbox_event(idempotency_key, upserts)` is deliberately generic —
it does not know what a "purchase trip" or a "due payment" is, only how
to upsert a JSON row into one of 22 allow-listed tables
(`apply_jsonb_upsert`). The alternative (a hand-written RPC per business
event type) would mean every new use case needs a new migration just to
sync. The safety a per-event RPC would give up front — you can only
write rows the RPC's own SQL explicitly constructs — comes from two
other places instead:

- **The table allow-list inside `apply_jsonb_upsert`.** Anything not on
  that list (notably `shops`/`shop_members`/`app_settings` — composite
  or bespoke keys, and their own dedicated flows) raises immediately.
  `lib/data/sync/sync_table_registry.dart` mirrors the same list
  client-side, but that copy is not the security boundary — it only
  decides what the *client* attempts; the server-side list is what
  actually can't be bypassed.
- **`SECURITY INVOKER`, not `SECURITY DEFINER`.** Unlike the onboarding
  RPCs in `0006_owner_onboarding_rpc.sql`, `apply_outbox_event` and
  `apply_jsonb_upsert` run as the calling user. Every dynamic `INSERT`
  they build still goes through that table's own
  `apply_standard_rls`/`apply_append_only_rls` policy — a staff device
  (view-only, per the working plan's permission model) gets exactly the
  same RLS rejection pushing through the outbox as it would calling the
  REST API directly. **Verified live**, not just reasoned about: a
  signed-in staff user's `apply_outbox_event` call was rejected with
  Postgres's own `42501` row-level-security violation, the same code a
  direct `POST /rest/v1/categories` would return.

### Idempotency

`processed_outbox_events(shop_id, idempotency_key primary key,
processed_at)` is checked first, before any table is touched; if the key
is already there, the function returns immediately as a silent no-op.
**Verified live**: pushed the same idempotency key twice with a
*different* payload the second time and confirmed the second payload
was silently ignored (the first payload's data is what persisted) —
then pushed a genuinely new event with a new key and confirmed that one
did apply. Append-only tables get a second, independent guard for the
"retried, but a different key" case: `apply_jsonb_upsert` uses
`ON CONFLICT (id) DO NOTHING` for those five tables (matching
`forbid_update_or_delete()`'s own restriction — a `DO UPDATE` would be
rejected by that trigger anyway), so a ledger row that made it through
on an earlier attempt whose ack was lost is a harmless no-op on retry,
not a hard failure.

## The pull side: `SyncPullService`

`lib/data/sync/sync_pull_service.dart` walks every table in
`SyncTableRegistry.syncableTables`, and for each:

1. Reads the stored cursor (`SyncCursors.lastSyncedAt`/`lastSyncedId`) —
   both null means "from the beginning."
2. Fetches up to 200 rows where `shop_id = <this device's real backend
   shop id>` and `(synced_at, id) > (cursor)`, ordered ascending by the
   same pair.
3. Runs every row through `ShopIdBridge.toLocal` and applies it to the
   local database via `LocalRowUpserter`.
4. Advances the cursor to the last row actually applied, then repeats
   until a page comes back smaller than the page size.

### Why `(synced_at, id)`, not a bare timestamp

Two rows can share the same `synced_at` down to the microsecond under
load (multiple inserts in the same statement, e.g. a purchase trip's
several items, all stamped by the same `clock_timestamp()` call — see
`set_created_at()`). A bare `synced_at > cursor` filter would then
silently skip whichever of the tied rows happens to sort first once the
cursor lands exactly on that timestamp. `id` (a UUIDv7 — see
ARCHITECTURE.md) is not itself time-ordered in a way that matters here;
it only needs to be a stable tie-breaker, which any total order on a
unique column provides.

### Conflict policy: the server always wins on pull

Stated explicitly rather than left implicit, since "conflict
resolution" can mean several different things: **a pulled row always
overwrites the local copy** for the 17 mutable tables (`ON CONFLICT (id)
DO UPDATE`), and **is silently skipped if already present** for the 5
append-only tables (`ON CONFLICT (id) DO NOTHING`). This is not a
heuristic tie-break — the server's `updated_at` is clock-authoritative
(`clock_timestamp()`, never client-supplied; see the `GREATEST(...)`
monotonicity guard in `0001_foundations.sql`), so by the time a row
reaches the pull side it has already gone through the one place a
timestamp actually gets decided. There is no "local wins" case in this
design: a local device's own pending changes for a row it hasn't pushed
yet live in the outbox, not in the local business table directly, so a
pull can never silently discard an unpushed local edit — it can only
ever advance a row past what this device has seen.

## The shop_id bridge

`lib/data/sync/shop_id_bridge.dart` is the fix for a real gap the M1
auth PR flagged rather than silently working around: local rows are
seeded at `onCreate` under a fixed local id, `defaultShopId`
(`lib/data/local/default_shop.dart`, a plain string, not a UUID) — set
long before a real backend shop exists, since this app creates its one
local `Shops` row at database-creation time, not at onboarding time (see
`default_shop.dart`'s own doc comment for why). Once onboarding
completes, `create_shop_and_owner` assigns a real backend UUID that is
never equal to `defaultShopId`.

Rather than rewriting every local row's `shopId` in place the moment
onboarding finishes — a real migration touching every one of the 22
syncable tables, for a value nothing local actually branches on, since
this is a single-shop-per-device app and every local query already
filters by the one row that exists — the substitution happens exactly
at the two points a row actually crosses the local/remote boundary:

- **Push** (`ShopIdBridge.toRemote`): a local row's `shop_id` is
  rewritten from `defaultShopId` to the real backend id before
  `apply_outbox_event` is called — the RPC's RLS checks compare the
  row's `shop_id` against `my_shop_id()`, which only ever returns the
  real id, so an unsubstituted push would be rejected by every table's
  own RLS policy regardless of who's calling it.
- **Pull** (`ShopIdBridge.toLocal`): the mirror-image substitution for a
  row just pulled down, before `LocalRowUpserter` writes it — every
  local foreign key ultimately traces back to the single `defaultShopId`
  `Shops` row, not to whatever real UUID the backend assigned.

Everywhere else in the app — every DAO, every screen, every local
query — keeps treating `defaultShopId` as this device's one true shop
id; only the sync boundary needs to know two ids exist at all.

## The enum case bridge

A second, unrelated boundary bug found the same way (reasoning through
what the generated code actually does, before it ever ran against real
synced data): Drift's `textEnum<T>()` columns store a Dart enum's
`.name` verbatim via the generated `EnumNameConverter` — e.g.
`PaymentMethod.mobileBanking` is stored locally as the literal string
`"mobileBanking"`. Every matching Postgres enum type in
`0001_foundations.sql`, though, was declared with the snake_case
spelling of the same identifier (`create type payment_method as enum
('cash', 'mobile_banking', 'bank_transfer')`). A raw pass-through sync
of any of the 21 enum-typed columns across 14 tables (see
`lib/data/sync/enum_column_registry.dart` for the exact list) would
therefore silently write a string neither side accepts:
`"mobileBanking"` is not a valid `payment_method` value in Postgres
(the push would fail outright), and `"mobile_banking"` pulled back into
local SQLite would fail `EnumNameConverter`'s `.byName()` lookup the
next time the app tried to read that column as a `PaymentMethod`
(a runtime crash, not a compile error, since the column is just `TEXT`
as far as SQLite itself is concerned).

`lib/data/sync/enum_case_bridge.dart` converts case (`camelCase` ↔
`snake_case`) for exactly the columns `EnumColumnRegistry` lists,
applied alongside `ShopIdBridge` on both push and pull. Deliberately an
explicit column allow-list, not a blind "this string looks like
camelCase, convert it" heuristic — a product or customer name could
coincidentally look like a single camelCase word (`"AlAshab"`), and
mangling free-text user data to fix a column that was never an enum
would be a worse bug than the one this fixes.

## What's verified vs. not

- **Server-side, live against the real deployed project**
  (`dzplxtidfsoovmocgikc`), not just written: a real signed-in owner
  pushed a two-table batch (`categories` + `products`) in one call and
  both rows landed atomically; a retried idempotency key with a changed
  payload was silently ignored while the original data persisted; a
  brand-new idempotency key with a real change did apply; an
  append-only row (`cash_ledger_entries`) re-sent under a new
  idempotency key hit `ON CONFLICT DO NOTHING` without erroring and
  without mutating the original row; a non-allow-listed table
  (`shop_members`) was rejected with the allow-list's own exception; a
  signed-in staff user's push was rejected by the underlying table's RLS
  policy (`42501`), not by any code this RPC added. All test rows
  cleaned up afterward.
- **The pull cursor filter, live against the real deployed project**:
  pushed 3 categories rows a fraction of a second apart, confirmed a
  bare fetch returns all 3 in `(synced_at, id)` order, then issued the
  exact `or=(synced_at.gt.X,and(synced_at.eq.X,id.gt.Y))` filter
  `SupabaseSyncTransport.fetchSince` builds using the second row's
  position as the cursor — confirmed it returns exactly and only the
  third row, not a `curl` invented for this write-up but the literal
  query shape the Dart code sends.
- **Client-side, pure Dart / real in-memory SQLite, no network**:
  `SyncPushService`/`SyncPullService` against a fake `SyncTransport` and
  a real `AppDatabaseV2.forTesting(NativeDatabase.memory())` — see
  `test/data/sync/`. Covers: successful push marks the entry done and
  removes it from the outbox; a failing push increments the attempt
  count and leaves the entry `failed` (retryable); pulled rows for both
  a mutable and an append-only table land in the local database with
  `shop_id` correctly rewritten back to `defaultShopId`; a second pull
  of the same remote rows does not duplicate or error; the cursor
  advances to the last row actually applied. This is also where the
  enum case-conversion bug and two `LocalRowUpserter` value-format bugs
  below were actually caught — by a real assertion failing, not by
  inspection.
- **Two more real bugs found by writing these tests, not by code
  review**, both in `lib/data/local/local_row_upserter.dart`:
  - **Local/remote column mismatches.** `categories` has
    `created_at`/`updated_at`/`synced_at` server-side but the local
    `Categories` table has none of the three — pulling a real remote row
    into a naive raw INSERT threw "no such column". Fixed by filtering
    each row down to whatever `PRAGMA table_info` reports as the local
    table's actual columns before building the statement.
  - **Date and boolean storage formats.** This project doesn't configure
    Drift's `storeDateTimesAsText`, so dates store locally as epoch
    `INTEGER` seconds; pulling a real ISO-8601 date string from
    PostgREST straight into that column stored a string SQLite accepted
    without complaint but Drift's own reader threw `int.parse` on the
    next read. Booleans have the same shape of problem in the other
    direction — SQLite/Drift store `0`/`1`, PostgREST returns a native
    JSON `true`/`false` the underlying `sqlite3` bindings won't bind
    directly. Fixed by coercing both based on the column's actual
    declared SQLite type from the same `PRAGMA table_info` call, not by
    guessing from the incoming value's Dart type alone.
- **Not yet covered**: no feature screens exist yet that actually
  enqueue an outbox event from a real use case (the DAOs built so far —
  `ProductDao`, `CustomerDao`, `InvestorDao`, `PurchaseDao` — write
  directly to the local database and do not yet call
  `SyncMetadataDao.enqueue()`). Wiring that up is the next M1 step once
  feature screens exist to drive it; until then this engine has been
  verified with hand-constructed events, not organically produced ones.
- **Not yet covered**: `SyncPendingUploads` (image upload queue) has no
  push logic yet — tracked separately, since it uploads raw bytes to
  Storage rather than JSON rows through `apply_outbox_event`.
- **Not yet covered**: a sync status indicator in the UI, and background
  scheduling of push/pull (both are still manually invoked service
  methods with no caller yet).
