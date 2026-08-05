# Architecture

This document is living — it started with M0 and gets extended as each
milestone lands. It is current through M4 and the v1 deletion (everything
through PR #29; the app is now v2-only). See
`notes/business_logic.md` for the business rules this architecture exists to
implement correctly, and `SYNC.md` for the offline sync engine's design in
detail.

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

`tool/check_layer_boundaries.sh` (also available as `.ps1` on Windows; run
in CI, see `tool/`) enforces the
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

The app has 582 fully-parity'd translation keys across `en_US`/`bn_BD`
built on GetX's `Translations` API, plus its routing and DI already wired
through `GetX`/`GetMaterialApp`. Replacing state-management frameworks
would not fix a single defect found in the pre-rewrite audit — every real
bug was in the data/business layer, not in GetX itself. GetX stays for DI,
routing, and i18n. What changed is scope: controllers are thin — they hold
`Rx` view state and call a use case — with no business math, no direct DB
access, and no `dart:io` calls inside a controller or a widget `build()`
method.

## Platform capability matrix

The app ships to Android (primary), Windows, and Web. Not every capability
exists on every platform:

| Feature | Android | Windows | Web |
|---|---|---|---|
| Local database (Drift) | native sqlite3 | native sqlite3 (`sqlite3_flutter_libs`) | WASM + OPFS |
| Sync (Supabase) | yes | yes | yes (REST transport) |
| Push notifications (M4) | yes | no-op | no-op |
| Camera / photo capture | **not implemented yet** — the `Products` table has `thumbnail_local_path`/`thumbnail_remote_url` columns and quick capture has `voiceNote`/`photoNote` types, but no capture or upload flow exists (no `image_picker`/`file_selector` dependency in `lib/`). Quick capture currently stores a free-text note as `fileLocalPath`. Native capture and the `SyncPendingUploads` image-upload queue are flagged as future work. |

`lib/core/platform/capabilities.dart` is the single place that resolves
these — no widget or controller may call `Platform.isWindows` or `kIsWeb`
directly. `lib/core/settings/feature_flags.dart` layers three independent
sources on top of raw capability: hard platform facts (push notifications),
an owner-configurable module toggle (rental/investor/orders/assets/barcode),
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
with declared defaults, backed by `DriftKeyValueStore`
(`lib/data/local/drift_key_value_store.dart`) — a Drift-backed store over
the `AppSettings` table, hydrated once in `main.dart` before anything reads
it. It replaces five speculative tables
(`AppSettings`/`BusinessSettings`/`TaxSettings`/`RentSettings`/`InvoiceSettings`)
that were proposed during planning — most of what they'd hold is scalar
configuration for one shop, not relational data. Real tables are reserved
for things that are actually rows, such as `rent_pricing_tiers`. It is the
single store for dark mode, language, and the pricing engine's
`OverheadSettings` — `SettingsController` (theme/language) and
`PricingSettingsController` both read/write through it.

## Quality gates (CI)

`.github/workflows/ci.yml` runs on every push/PR: `dart format --set-exit-if-changed`,
the layer-boundary script, `flutter analyze`, `flutter test`, and a debug
build for each of the three shipping targets. This is the real verification
gate — a PR is not "done" because it looks right, it is done because CI is
green.

**Known interim gap, tracked but not yet closed:** `analysis_options.yaml`
picked up a much stricter lint set in M0 (see "Why this rewrite exists"
above), but CI runs plain `flutter analyze` rather than `flutter analyze
--fatal-infos`. The original blocker — the then-present v1
`lib/features/**` tree — is gone since the v1 deletion, so today the only
thing standing between `--fatal-infos` and green CI is ~110 pre-existing
info-level lints across `lib/` and `test/` (mostly `directives_ordering`,
`prefer_final_locals`, `prefer_const_constructors`). Cleaning those up and
flipping the CI flag is a real but self-contained M4-hardening task, still
open.

**A real environment limitation, found and confirmed, not assumed:** a
`testWidgets` test that keeps an active `AppDatabase` `.watch()` stream
subscription alive across a `pumpWidget`/`pump` call deadlocks in this
sandbox's `flutter test` runner — reproduced in isolation (a listener on
`CategoryDao.watchAll` fires once correctly, then the very next
`pumpWidget` call never returns), and confirmed it is specifically the
active Drift stream subscription at fault, not the widget tree, GetX, or
the query itself (a `pumpWidget` with the same database merely held open,
no active listener, completes normally). Because of this, screens backed
by a live `watch()` stream (`CatalogScreen`, `PurchaseEntryScreen`, and
any future one built the same way) are verified via `flutter analyze`
plus real-database tests of the controller/use-case layer underneath them
(`test/data/usecases/`, `test/data/sync/`) — never via a `testWidgets`
test that pumps the screen itself against a real `AppDatabase`.
`test/features/auth/auth_gate_test.dart` already established the
alternative that does work: a hand-rolled fake stream
(`StreamController`) standing in for the real one, which is what any new
widget test for a database-backed screen should do too.

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

**Owner onboarding (M1) resolves the earlier open item.** The
`shop_members` bootstrap policy note below was written before the
owner-onboarding flow existed. It now does: `0006_owner_onboarding_rpc.sql`
defines `create_shop_and_owner` (creating the shop and its first
membership row atomically in one RPC), `0007_revoke_anon_from_onboarding_rpcs.sql`
locks the onboarding RPCs down to the anon role only, and the client
flow lives in `lib/features/auth/` (see also `lib/data/remote/supabase_auth_repository.dart`).
Auth is Supabase Auth with email/password, owner sign-up plus staff
invite (the staff token path), and a session that gates the whole app
behind `AuthGate`.

**Verified against the real project**, not a local simulation — this
schema was applied directly to the live (previously empty) Supabase
project via `apply_migration`, then checked with `list_tables` (confirming
RLS enabled on all 25 tables) and hand-written `execute_sql` checks: a
live insert/attempted-update/attempted-delete proving the immutability
guarantee, a `check` constraint rejecting an investor fund source with no
investor id, and a foreign key rejecting a reference to a nonexistent
shop. Test rows were then removed with `TRUNCATE ... CASCADE` (which does
not fire the per-row immutability trigger) to leave the project clean.

## Feature inventory (as shipped through M4)

All feature folders live under `lib/features/` (the `_v2` folder-name
suffix is a deliberate leftover from when v1 coexisted — still accurate,
just ugly; see "Known gaps" below). Each folder is `controller/` +
`view/` (and sometimes `widgets/`).

**Shell (`shell/`)** — the app's only skeleton. `ShellScreen` embeds 5
screens directly via `IndexedStack` — Dashboard, Daily Sales, Stock, Dues,
Customers — picked as the highest-frequency daily actions per
`notes/business_logic.md`; `AppBottomNav` shows those 5, and `AppDrawer`
links to the remaining 13. The 5 embedded screens each take an optional
`onMenuTap` callback + conditional leading menu `IconButton`, because each
builds its own nested `Scaffold`/`AppBar` and Flutter's automatic
hamburger-icon injection only looks at a screen's own immediate `Scaffold`,
not an ancestor's. *(This 5-tab choice is a judgment call — see "Known
gaps".)*

**Behaviors / accounting (M1–M2):**
- `catalog/` — products, categories, barcode/SKU lookup (M4, see
  `lib/domain/services/barcode_lookup.dart`).
- `purchase_entry/` — mokam-trip purchase entry (multiple items, per-item
  `fundSource`, `isInKind`), saved by `SavePurchaseTripUseCase` with
  per-fund-source reconciliation (`lib/domain/services/purchase_reconciliation.dart`).
- `daily_sales_v2/` — the cash/due/rent transaction router from
  `business_logic.md` §গ, saved by `SaveSaleUseCase` (ledger entry +
  `Product.qty` decrement + due creation in one transaction).
- `stock_v2/` — inventory view/filters.
- `dues_v2/` — due lifecycle, payments (`PayDueUseCase`).
- `customers_v2/` — customers + orders tab.
- `investor_v2/` — investor metrics & repayments (`lib/domain/services/investor_metrics.dart`,
  `cash_balance_calculator.dart`), including `legacy_settlement_usecases.dart`.
- `expense_v2/` — monthly rent / daily-other expenses.
- `dashboard_v2/` — the Total-Cash / profit cards
  (`lib/domain/services/dashboard_calculator.dart`), day/All-time toggle.
- `pricing_settings_v2/` — the overhead-markup pricing engine
  (`lib/domain/services/pricing_engine.dart`), auto-bootstrapped after the
  first monthly close.
- `reports_v2/` — period reports + crash-safe backup/restore
  (`lib/data/local/backup_service.dart`, `backup_v2/`).

**Side modules (M3):**
- `rent_v2/` — book rentals: pricing tiers, issue/return/mark-stolen
  (`lib/domain/services/rent_lifecycle.dart`,
  `lib/data/usecases/issue_rent_usecase.dart`,
  `return_rent_usecase.dart`, `mark_rent_stolen_usecase.dart`).
- `order_v2/` — customer orders with deadline reminders.
- `fixed_asset_v2/` — fixed assets (shop-cash purchase or stock conversion).
- `quick_capture_v2/` — quick voice/photo *note* capture flow. Note: the
  capture is currently a free-text note standing in for a real voice/photo
  file — the `voiceNote`/`photoNote` types exist but native capture is not
  implemented (see "Known gaps").

**Polish / M4:**
- `reminders_v2/` — the 6-type reminder engine
  (`lib/domain/services/reminder_engine.dart`: due balance, investor capital
  return, investor profit payout, suspicious customer, overdue rent, order
  deadline) surfaced via `lib/core/notifications/notification_service.dart`
  (Android notifications; no-op elsewhere).
- `audit_log_v2/` + `recycle_bin_v2/` — audit log viewer, soft-delete
  recycle bin, and the retention policy (`lib/data/usecases/audit_log_usecases.dart`).
- `sync/` — the `SyncController` (manual "Sync Now" + periodic timer +
  connectivity-regained auto-sync, pending-outbox-count badge).
- `settings/` + `auth/` — theme/language (`SettingsController`) and
  Supabase auth.

The use cases that back these live in `lib/data/usecases/` (21 files,
including `sync_enqueue_helper.dart` which is how every feature's writes
reach the outbox).

## The v1 that used to be here

Until PR #28/#29 the same repo carried a parallel v1 app
(`lib/core/database/` Drift schema + DAOs, `lib/core/services/data_service.dart`
and `image_service.dart`, and 9 v1 feature folders under `lib/features/`)
that was still the default UI at launch. Per the owner's explicit decision
(no real production data to preserve), v1 was removed outright rather than
migrated, and `AppDatabaseV2` was mechanically renamed to `AppDatabase`.
`LegacyDatabaseCleanup` (`lib/core/db/legacy_cleanup.dart`) deletes the old
v1 SQLite file + WAL/SHM sidecars from disk, best-effort and idempotent,
once at startup. There is no v1 left in the tree.

## Known gaps (honest, current)

- **`_v2` naming debt** — route constants, folder names, controller/class
  names still carry the `V2` suffix even though nothing needs
  disambiguating anymore. Pure cosmetic; deferred as a separate cleanup
  (see `app_routes.dart`'s own doc comment).
- **Camera/photo capture is not built** — product thumbnails and
  quick-capture media exist only as schema/UI types; `SyncPendingUploads`
  has no push logic (see SYNC.md).
- **Widget/UI test coverage is thin** — only 2 of ~60 test files use
  `testWidgets`; the Drift-stream deadlock documented above is the reason.
- **`--fatal-infos` still off in CI** (~110 pre-existing info lints).
- **No signed release builds** — Android uses the debug signing config;
  Windows-installer and web-deployment pipelines don't exist.

## What's not here (and never will be, in this project's framing)

Nothing further lands at the architectural level for now — the vanilla
feature backlog is closed. Future work is the "Known gaps" list plus any
new business requests from `notes/business_logic.md`.
