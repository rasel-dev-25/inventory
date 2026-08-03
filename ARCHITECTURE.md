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

## What's deliberately not here yet

This document covers the M0 foundation only. Drift schema v2 (UUID keys,
ledger/movement tables, sync tables), the Supabase schema and RLS policies,
the outbox/puller sync engine, and the feature screens land in M1 onward,
each with its own PR and its own addition to this document.
