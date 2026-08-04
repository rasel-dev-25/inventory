# Architecture

This document is living — it started with M0 and gets extended as each
milestone lands. See `notes/business_logic.md` for the business rules this
architecture exists to implement correctly, and `SYNC.md` (added in M1) for
the offline sync engine's design in detail.

## Why this rewrite exists

The v1 codebase stored money as `double`, dates as free-text
`dd-MM-yyyy` strings compared by string equality, had zero database
transactions around multi-write operations, and had no foreign keys at
all — entities were joined by matching name strings. Two of the app's most
important numbers (the dashboard's "net profit" and "total cash") were
computed with formulas that quietly diverged from what the business
document actually specifies. None of that was a matter of missing
features; it was a foundation that could not carry the business's real
financial logic without silently producing wrong numbers. This rewrite
starts from a foundation designed so that class of bug cannot recur.

## Layering

```
lib/
  core/      infrastructure with zero business knowledge
  domain/    pure Dart — no Flutter, no Drift, no Supabase imports, ever
  data/      local (Drift) + remote (Supabase) + sync, behind repository interfaces
  features/  one folder per feature: controller/ + view/ + widgets/
```

**The rule that matters most: `lib/domain/` never imports Flutter, Drift,
or Supabase.** Every calculation the business document specifies —
`calculateGrossProfitPerSale`, `calculateShopNetProfit`, purchase-trip
reconciliation, rent pricing, the cash-ledger balance — is a plain Dart
function or a small pure-Dart class in `domain/services/`, testable with
`dart test` and no widget/database ceremony. This is the direct fix for the
v1 bug where the same profit formula was inlined three different ways in
three different controllers and quietly drifted. If a money formula needs
to change, there is exactly one file to change, and one test suite that
must still pass.

`domain/usecases/` sits just above the services: a use case
(`CompleteSaleUseCase`, `SavePurchaseTripUseCase`, `ReturnRentedBookUseCase`,
`PayDueUseCase`) owns a transaction boundary and orchestrates repositories
and services. Controllers call use cases; they never touch a repository or
a DAO directly, and they never contain business math.

`lib/core/check_layer_boundaries.sh` (run in CI, see `tool/`) enforces the
domain-purity rule mechanically — a `flutter analyze`-clean PR can still be
rejected by CI if `lib/domain/**` imports something it shouldn't.

## Shared kernel vs. feature modules

Each feature module owns its own `data/domain/presentation` slice, but a
few entities are genuinely shared across modules — `Customer` is used by
sales, dues, rent, and orders; `Product` by inventory, sales, and purchase.
Those live in a shared kernel (`lib/domain/entities/`, `lib/data/local` core
tables) rather than being copied into each module. Copying them would
recreate the exact defect class we removed — the old app's `Product`
carried an `investor` *name string* rather than a foreign key, so renaming
an investor silently broke historical attribution. One definition, real
foreign keys, no drift between "copies" of the same entity.

## Why GetX stays

The v1 app has 378 fully-parity'd translation keys across `en_US`/`bn_BD`
built on GetX's `Translations` API, plus its routing and DI already wired
through `GetX`/`GetMaterialApp`. Replacing state-management frameworks
would not fix a single defect found in the v1 audit — every real bug was in
the data/business layer, not in GetX itself. GetX stays for DI, routing,
and i18n. What changes is scope: controllers become thin — they hold `Rx`
view state and call a use case — with no business math, no direct DB
access, and no `dart:io` calls inside a controller or a widget `build()`
method (all three were found in the v1 audit).

## Platform capability matrix

The app ships to Android (primary), Windows, and Web. Not every capability
exists on every platform:

| Feature | Android | Windows | Web |
|---|---|---|---|
| Local database (Drift) | native sqlite3 | native sqlite3 (`sqlite3_flutter_libs`) | WASM + OPFS |
| Camera capture | yes | file picker fallback (`file_selector`) | file picker fallback |
| Microphone / voice note | yes | **disabled**, explained in UI | **disabled**, explained in UI |
| Image compression (`flutter_image_compress`) | yes | yes | limited/no native codec support — falls back to uploading the picked file at its original size, with a size cap |

`lib/core/platform/capabilities.dart` is the single place that resolves
these — no widget or controller may call `Platform.isWindows` or `kIsWeb`
directly. `lib/core/settings/feature_flags.dart` layers three independent
sources on top of raw capability: hard platform facts (camera/mic), an
owner-configurable module toggle (rental/investor/orders/assets/barcode),
and one spec-driven automatic condition (the pricing engine stays hidden
until the shop's first monthly close, per `business_logic.md` §৬).

## Money

`lib/core/money/money.dart` is the only type allowed to carry a monetary
value across a layer boundary; a raw `int` minor-unit value must not cross
one un-wrapped. It intentionally has no `double`-based constructor except
one clearly-named escape hatch
(`Money.fromDoubleMajorUnitsForLegacyImportOnly`) reserved for one-off
import/export tooling. `Money.allocate()` implements the largest-remainder
method so splitting an amount by weights (an investor's profit-share
percentage, a purchase trip's per-fund-source split) never leaks or gains a
paisa to independent rounding — see `test/core/money_test.dart` for the
proof. Formatting uses South Asian (lakh/crore) digit grouping, matching
how amounts are actually written in Bangladesh, rather than Western
thousands grouping.

Postgres mirrors this with `BIGINT` minor-unit columns (never `NUMERIC` or
`MONEY` — see the M0 research notes in the project's working doc for why),
and Drift mirrors it with `IntColumn`.

## Time

`lib/core/time/clock.dart` is the only sanctioned source of "now" — no
business logic may call `DateTime.now()` directly. This is what makes
date-dependent rules (due reminders, rent-overdue checks, "today's
dashboard") deterministically testable with `FixedClock`, and it is the
seam that separates "the device's clock", which the sync engine must never
trust for conflict resolution, from "the user-facing business date", which
stays editable and is unrelated to sync ordering.

## Errors

`lib/core/error/` defines a closed `Failure` taxonomy and a `Result<T>`
(`Ok`/`Err`) type. Every repository and use-case method returns
`Result<T>` instead of throwing, and every `switch` over `Failure` is
exhaustiveness-checked by the compiler — a new failure kind cannot be added
without every handler in the app consciously deciding what to do with it.
This replaces the v1 pattern of `catch (Object e) { showSnackbar(...) }`,
which discarded the stack trace and, in `data_service.dart`'s import flow,
could leave the database cleared with no recovery if the batch insert
failed partway through.

## Settings and feature flags

`lib/core/settings/settings_registry.dart` is a typed key-value registry
with declared defaults, backed by `KeyValueStore` (in-memory for now; a
Drift-backed implementation lands in M1, using the same `AppSettings`
table the v1 app already had). This replaces five speculative tables
(`AppSettings`/`BusinessSettings`/`TaxSettings`/`RentSettings`/`InvoiceSettings`)
that were proposed during planning — most of what they'd hold is scalar
configuration for one shop, not relational data. Real tables are reserved
for things that are actually rows, such as `rent_pricing_tiers`.

## Quality gates (CI)

`.github/workflows/ci.yml` runs on every push/PR: `dart format --set-exit-if-changed`,
the layer-boundary script, `flutter analyze`, `flutter test`, and a debug
build for each of the three shipping targets. This is the real verification
gate — a PR is not "done" because it looks right, it is done because CI is
green.

**Known interim gap, tracked for M4:** `analysis_options.yaml` picked up a
much stricter lint set in M0 (see "Why this rewrite exists" above), but CI
runs plain `flutter analyze` rather than `flutter analyze --fatal-infos`.
Turning that on today would fail the build on the still-untouched v1
`lib/features/**` tree, which this PR does not modify. `--fatal-infos`
becomes the real gate once that tree is migrated/replaced module by module
through M1–M3 — tracked as an M4 hardening task, not dropped.

## The v2 local schema (`lib/data/local/`)

Every table from `notes/business_logic.md` plus the sync/audit/ledger
infrastructure lives in `lib/data/local/tables/`, wired up in
`app_database.dart`. A few cross-cutting rules run through all of it:

**Append-only tables** (`CashLedgerEntries`, `StockMovements`,
`InvestorRepayments`, `DuePayments`, `AuditLogEntries`): no `updatedAt`, no
`deletedAt`, and no update/delete method is ever called on them from Dart.
These are the tables Total Cash, the payment-method sub-balances, and
`Products.qty`'s ground truth are derived from. A mistaken entry gets a
reversal row, never an edit — see `tables/ledger.dart`'s doc comment for
the full reasoning, which is a direct fix for the v1 dashboard's ad hoc,
wrong Total Cash formula.

**Mutable entities** (`Products`, `Customers`, `Investors`, `Sales`,
`PurchaseTrips`, ...): normal rows with `updatedAt`/`deletedAt`, resolved
by guarded last-write-wins during sync (see `SYNC.md`, M1).

**When a cached column is and isn't justified.** `Products.qty` and
`Dues.paidAmountMinor`/`status` are stored, denormalized values — which is
exactly the pattern that caused v1's investor-totals bug (cached figures
recomputed by *some* code paths and forgotten by others, so they silently
drifted). The difference here: each of these is written by exactly *one*
disciplined use case, in the *same transaction* as the append-only row it's
derived from (`Products.qty` alongside a `StockMovements` insert;
`Dues.paidAmountMinor` alongside a `DuePayments` insert) — and each is
always mechanically re-derivable by summing its source table if it's ever
suspected of drifting. That combination (single writer, same transaction,
rebuildable) is what makes a cache safe. `RentTransactions`' "available
copies" deliberately has *no* cached column at all — it's a cheap indexed
`COUNT`, cheap enough that caching it would only add drift risk for no
real performance win. When adding a new derived figure, default to
computing it on read; only cache it once there's a *measured* reason to,
and only behind the single-writer-same-transaction rule above.

**Polymorphic references** (`Dues.sourceId` → a `Sales.id` or a
`RentTransactions.id`; `CashLedgerEntries.sourceId`/`StockMovements.sourceId`
→ whichever table caused the entry): Drift cannot express a conditional
foreign key, so these are plain `text()` columns, and the correct target
table is enforced by whichever use case writes them — not by the schema.

**Enums are real Dart enums, stored via Drift's `textEnum<T>()`** (not a
free-text column compared by string literal, which is what let the v1
schema's `Sale.type`/`Customer.type`/`Investors.contractType` drift into
inconsistency). Every enum used this way lives in
`lib/domain/entities/enums.dart` and must be imported directly into
`app_database.dart` itself — Dart imports are not transitive, so a table
file importing `enums.dart` does not make those types visible to the
generated `database.g.dart` part file; only `app_database.dart`'s own
imports do.

**Verification note:** this schema was checked against real Drift codegen
(`dart run build_runner build`) and a runtime smoke test against an
in-memory SQLite database — including an actual foreign-key-violation
check — before being committed, not just written and hoped. `dart analyze`
was clean and `REFERENCES` constraints were confirmed present in the
generated SQL. DAOs, repositories, and the `onCreate` seed migration are
the next PR; this one is schema-only.

## The Supabase (Postgres) schema (`supabase/migrations/`)

Mirrors `lib/data/local/tables/` table-for-table, with three differences
that follow directly from being the multi-device server side rather than
a single local file:

- **`shops` + `shop_members(shop_id, user_id, role)` are new** — a local
  device only needs to know its own role, but Postgres needs the full
  membership list to enforce RLS for every member. `role` is `owner` or
  `staff`; per the confirmed permission model, this is deliberately a
  single flat rule with no per-table exceptions (see the RLS paragraph
  below), not a capability matrix.
- **The three sync-infrastructure tables are *not* mirrored**
  (`SyncOutboxEntries`, `SyncPendingUploads`, `SyncCursors` stay local-only)
  — they are the client's own bookkeeping for what it has and hasn't
  pushed/pulled yet, not business data with anything to sync *to*.
- **Types are Postgres-native equivalents of the same concepts**: `uuid`
  primary keys (still client-generated UUIDv7, never server-assigned),
  `bigint` minor-unit money (never `numeric` or `money` — see the
  original sync research), `timestamptz` for every date, and native
  Postgres `enum` types matching `lib/domain/entities/enums.dart`
  one-for-one (e.g. `payment_method`, `fund_source_type`) rather than
  free text — the same reasoning as the local schema's `textEnum<T>()`.

**RLS: one rule, applied identically everywhere.** Owner gets full
`SELECT`/`INSERT`/`UPDATE`/`DELETE` scoped to their shop; staff gets
`SELECT`-only scoped to their shop. No table has an exception. This is
enforced by two stored procedures defined once in migration `0001`
(`apply_standard_rls` for mutable tables, `apply_append_only_rls` for the
ledger/audit tables) and then *called* — never hand-copied — against
every table, so the policy can't drift table-to-table the way a
hand-written copy-pasted policy set eventually would. Child tables with no
`shop_id` of their own (`product_images`, `purchase_items`,
`purchase_other_costs`, `due_payments`) get a bespoke policy that scopes
through their parent instead — documented inline at each one.

**Append-only tables get defense in depth, not just one guard.** The same
five tables that are append-only locally
(`cash_ledger_entries`/`stock_movements`/`investor_repayments`/
`due_payments`/`audit_log_entries`) get *two* independent enforcements in
Postgres: `apply_append_only_rls` creates no `UPDATE`/`DELETE` policy at
all (Postgres RLS defaults to deny when no policy exists for an
operation), and a `forbid_update_or_delete` trigger raises an exception
if either is somehow attempted anyway. Verified for real, not just
written: inserted a live row, attempted an `UPDATE` and a `DELETE`
against it directly on the deployed project, and confirmed both were
rejected and the row was unchanged.

**`updated_at` is server-authoritative**, via a `set_updated_at` trigger
using `clock_timestamp()` (wall-clock at execution) rather than `now()`
(fixed at transaction start) — a slow transaction must not appear to
predate a fast one that committed after it started — with a
`GREATEST(old + 1µs, clock_timestamp())` guard for per-row monotonicity
under clock skew. Every syncable table has a `(shop_id, synced_at, id)`
index for the pull-since-cursor query the outbox/puller design (still to
come) will use.

**Known open item, flagged rather than silently resolved:** the
`shop_members` bootstrap policy (a fresh shop's first member becomes its
owner) is a reasonable MVP rule for a single-shop app, but the real
owner-onboarding flow doesn't exist yet (auth screens are a later M1
task). Revisit `supabase/migrations/0002_shops_and_members_rls.sql` once
that flow is built — shop creation and the first membership row may need
to move into an Edge Function so they happen atomically instead of as two
separate client-issued statements.

**Verified against the real project**, not a local simulation — this
schema was applied directly to the live (previously empty) Supabase
project via `apply_migration`, then checked with `list_tables` (confirming
RLS enabled on all 25 tables) and hand-written `execute_sql` checks: a
live insert/attempted-update/attempted-delete proving the immutability
guarantee, a `check` constraint rejecting an investor fund source with no
investor id, and a foreign key rejecting a reference to a nonexistent
shop. Test rows were then removed with `TRUNCATE ... CASCADE` (which does
not fire the per-row immutability trigger) to leave the project clean.

## What's deliberately not here yet

The outbox pusher, the cursor-based puller, conflict resolution, Supabase
Auth wiring (sign-in, owner onboarding, staff invitation), and every
feature screen land in M1 onward, each with its own PR and its own
addition to this document.
