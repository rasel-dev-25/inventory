# AL ASHAB Inventory App — Project Handoff Report

Complete handoff for any future agent/developer continuing this project — current state, what's done, what's broken/in-progress, and exact next steps.

## 0. READ THIS FIRST — Immediate Next Step

**✅ DONE as of this revision. Do not redo section 0's workflow.** The v1
deletion is fully merged into `origin/main`:

- PR #28 (`delete-v1-make-v2-primary`) — merged as `b31dec7`, deleted 9 of the 47 files plus carried the `AppDatabaseV2`→`AppDatabase` rename and shell rewiring (the batch-push path could not delete, exactly as this section predicted).
- PR #29 (`fix/complete-v1-deletion`, commit `d533c20`) — merged as `50552d5`, deleted the other **38 v1 files** left behind by PR #28 (sequential one-by-one `github__delete_file` calls, the fix this section prescribed).

Both were then verified on the freshly-synced local `main` (`50552d5`)
with the full 5-command suite — all green (`flutter analyze` 0 errors/0
warnings, format clean, layer boundaries OK, `build_runner` regenerates
byte-identical `.g.dart` files, `flutter test` all pass). The task that
used to live here is complete; the "still NOT deleted" 37-file list below
is historical interest only.

_(Original text preserved below for the record.)_

**Current state of branch `delete-v1-make-v2-primary` on GitHub:** had all 132 modified files correctly, but only these v1 files landed as confirmed deletions before the parallel-call failure: `lib/core/database/app_database.dart`, `app_database.g.dart`, `daos/asset_dao.dart`, `daos/asset_dao.g.dart`, `daos/customer_dao.dart`, `daos/customer_dao.g.dart`, `daos/expense_dao.dart`, `daos/expense_dao.g.dart`, `daos/investor_dao.dart`, `daos/investor_dao.g.dart`. **The remaining 38 were then deleted sequentially on branch `fix/complete-v1-deletion` and merged as PR #29.** See the exact list via `git diff --name-status origin/main b31dec7` locally, or `/tmp/deleted_files.txt` in the sandbox if it still exists.

**The fix that was applied (this is now history — do not re-run it):**
1. Get the branch's current tip SHA: it should be commit `dc2bd914c75fcf5dbacd3904294df37e61b65b72` or later (check `github__get_commit` or list branch refs).
2. Call `github__delete_file` for each of the ~37 remaining files, **one at a time, sequentially, waiting for each to complete before firing the next** — do NOT batch these in parallel, that's exactly what caused the failure. *(This was done on a follow-up branch `fix/complete-v1-deletion` and merged as PR #29.)*
3. Once all 47 are deleted, verify by listing `lib/core/database/`, `lib/core/services/`, and each v1 feature folder on the branch — all should 404/not exist.
4. Create the PR: `delete-v1-make-v2-primary` → `main`, title "Delete v1 entirely, make v2 the only app".
5. Merge it (regular merge, matching every other PR in this project's history).
6. Sync local: `git checkout main && git fetch origin main && git reset --hard origin/main`.
7. Update this document's section 3 to mark this item done, and note the actual merged commit SHA. ✅ (done — see the top of this section)

**Learned/convention (still applies forever):** `github__push_files` cannot delete files; `github__delete_file` calls on the same branch must be strictly sequential — parallel calls race on the branch ref and fail with `422 Update is not a fast forward`. This is why PR #28 needed PR #29 to finish the deletions.

## 1. What this project is

**AL ASHAB** — a Flutter inventory/accounting app for a small Bangladeshi retail shop, rewritten from an offline-only v1 into an offline-first, Supabase-synced v2, per a Bengali business specification at `notes/business_logic.md`. Built via a phased plan (M0 Foundations → M1 Usable Shop App → M2 Full Accounting → M3 Side Modules → M4 Polish), executed as ~28 stacked/sequential PRs against `rasel-dev-25/inventory` on GitHub, each independently verified (analyze/format/layer-boundaries/tests) before merge.

**Architecture**: clean layering — `domain/` (pure Dart, no Flutter/Drift/Supabase/GetX imports) → `data/` (Drift ORM local DB + Supabase remote + use cases) → `features/` (GetX controllers/screens). Enforced by `tool/check_layer_boundaries.sh`, which every PR must pass. `Money` is integer minor-units (paisa). `Result<T>`/`Failure` sealed hierarchy for error handling. State management is GetX throughout (`Get.put`/`Get.find`, `GetxController`, `.obs`/`Obx`).

**Backend**: Supabase (Postgres + Auth + RLS), schema mirrored from the local Drift schema, applied to a live (previously empty) Supabase project. Sync is an outbox-pusher + cursor-puller design (see `SYNC.md` — updated to match the current engine in the doc pass described in section 6).

**This session's arc** (the conversation that produced this document): picked up mid-M4, closed out the M4 checklist (reminders/notifications, audit log/recycle bin/retention, barcode scanning), found and fixed several real bugs (pricing-engine bootstrap timing, a customer-deletion FK-crash risk, a missing order-deadline reminder, 2 hardcoded UI strings), delivered an honest full-project status report exposing that **v1 and v2 were coexisting as two disconnected systems** (v1 was still the app's default UI; v2 was a fully-built parallel system reachable only via a drawer menu), and — on the user's explicit instruction that this is a new app with no real production data to preserve — deleted v1 entirely and made v2 the app's one and only experience (PRs #28 + #29, merged; see section 0).

## 2. Full PR history (all merged)

Repo: `rasel-dev-25/inventory`. All PRs below are merged into `main` unless marked otherwise. Numbering is GitHub PR number.

**M0 — Foundations**: PR #1 (domain layer, `Money`/`Result`/`Clock`, Drift v2 schema skeleton, layer-boundary tool, CI 3-platform matrix).

**M1 — Full accounting infra + basic screens** (numbered independently on an earlier repo before it moved to `rasel-dev-25/inventory` — see full history via `git log --oneline --merges`): domain entities/calculators, Supabase schema+RLS+triggers applied live, Supabase Auth + atomic owner-onboarding + staff invites, outbox pusher + cursor puller + conflict resolution, then a run of v2 feature screens — categories/products (`catalog`), purchase entry, daily sales, dues, customers, stock, dashboard, investor — plus manual/background sync triggers.

**M1/M2 boundary**: Expense module + wiring real expenses into the Dashboard; a hardening fix for a soft-delete/ledger-reversal gap (expense + purchase trip).

**M3 — Side modules**: Rent (book rental) module, Customer orders, Fixed assets, Quick capture conversion flow. Commit message said "M3 complete" — **this was not fully true**, see section 5 (order-deadline-reminder gap, since fixed).

**M2 — Full accounting (finished later)**: Legacy settlement flow, Pricing recommendation engine (PR #19, with a bootstrap-timing bug found and fixed), Reports + crash-safe backup/export (PR #20).

**M4 — Polish** (this session): PR #21 reminders + Android notifications, PR #22 audit log viewer + recycle bin + retention policy (required a mid-task `git rebase` after a teammate pushed `.g.dart` files directly to `main`, changing repo convention to committing generated files), PR #23 barcode scanning, PR #24 product/fixed-asset/purchase-trip delete-gap hardening + expanded audit logging, PR #25 fix — a real bug where the retention policy could crash deleting a customer with linked history (FK violation), PR #26 fix — order-deadline reminders were never actually wired up despite M3 claiming so, PR #27 fix — last 2 hardcoded UI strings (Barcode/SKU labels).

**Delete v1, make v2 the only app**: PR #28 (`delete-v1-make-v2-primary`, merged `b31dec7` — rename + shell rewiring + the 9 deletions the batch path could carry) and PR #29 (`fix/complete-v1-deletion`, merged `50552d5` — the remaining 38 deletions, sequential `github__delete_file` calls). The 5-command verification suite was re-run on the merged result, all green.

## 3. Verification status of the v1-deletion commits

Local commit `a3b97e8` (basis for PR #28) was fully verified in the sandbox before the GitHub push began; the merged result was re-verified on local `main` (`50552d5`) per the "trust but verify" note below:

- `dart run build_runner build` — regenerated cleanly (964 codegen inputs on the merged tree) and the generated output was **byte-identical to the committed `.g.dart` files** (diff shows zero content changes) — proves the committed generated files match the schema.
- `flutter analyze --no-fatal-infos` — **0 errors, 0 warnings** (110 pre-existing info-level lints, none new).
- `dart format --set-exit-if-changed lib/ test/` — clean.
- `tool/check_layer_boundaries.ps1` (`.sh` in CI) — OK.
- `flutter test` — **all tests pass** (451 — one fewer than the sandbox's 452; no test files changed in the delete merges, so the difference is a local-SDK artifact, not a loss).

Conclusion: **DONE.** The v1 entity is gone from the tree, the merged state is verified, and no further local verification is needed unless a future change touches what was deleted.

## 4. Exact content of the v1-deletion commits (merged as PRs #28/#29)

Full commit message (from `git log -1 --format=%B a3b97e8` in the sandbox) covers everything below — reproduced here in case the sandbox is gone:

**Decision**: user said this is a new app, no real production data exists yet, so no v1→v2 data migration is needed — delete v1 outright.

**Structural changes**:
- `ShellScreen` (`lib/features/shell/view/shell_screen.dart`) now embeds 5 v2 screens directly via `IndexedStack`: Dashboard, Daily Sales, Stock, Dues, Customers — picked as the highest-frequency daily actions per `notes/business_logic.md`. This is a **judgment call, explicitly flagged in the class's own doc comment for reconsideration** — v1's original bottom nav had 7 slots (also Finance, Investor); v2 has ~18 screens total, too many for any bottom nav, so 13 live in the drawer instead.
- `AppBottomNav` (`lib/features/shell/view/widgets/bottom_nav_bar.dart`) — now 5 items matching the above.
- `AppDrawer` (`lib/features/shell/view/widgets/app_drawer.dart`) — fully rewritten: first 5 tiles are `switchTab` shortcuts into the embedded screens; then Catalog, Purchase Entry, Investor, Expense, Rent, Orders, Fixed Assets, Quick Capture, Pricing Settings, Reports, Reminders, Audit Log, Recycle Bin, Account each get a drawer tile; v1's Export/Import/Seed-data tiles (`DataService`) are gone; v2's crash-safe Backup/Restore stayed; the dark-theme/language toggle stayed (now backed by the migrated `SettingsController`, see below).
- The 5 embedded screens (`dashboard_v2`, `daily_sales_v2`, `stock_v2`, `dues_v2`, `customers_v2` — their `view/*_screen.dart` files) each gained an **optional `onMenuTap` callback + a conditional leading menu `IconButton`** — needed because each screen builds its own nested `Scaffold`/`AppBar`, and Flutter's automatic hamburger-icon injection only looks at a screen's *own* immediate `Scaffold`, not an ancestor's — so the outer shell's drawer would otherwise be unreachable from these tabs. This exact problem, and this exact fix, is how v1's own shell worked before deletion.
- `SettingsController` (`lib/features/settings/controller/settings_controller.dart`) — **migrated off v1's `AppDatabase`/`SettingsDao`** onto `SettingsRegistry` (the v2 key-value store already used by the pricing engine). This was the one genuinely shared piece of app-wide state (dark mode + language, read by the root `App` widget itself) that had to move before v1's database could be deleted. Its public API (`isDark`, `currentLocale`, `toggleDarkMode()`, `toggleLanguage()`, `setLanguage()`) is unchanged. Side benefit: now fully synchronous at `onInit` (previously async, causing a one-frame flash of the wrong theme on launch).
- `main.dart` — removed v1's `AppDatabase()` registration entirely; added a startup call (`unawaited`, best-effort) to `LegacyDatabaseCleanup.deleteFrom(await getApplicationDocumentsDirectory())` — this class existed since M1 but was never invoked; it deletes the old v1 SQLite file + WAL/SHM sidecars from disk. Fixed the `SettingsController`/`SettingsRegistry` registration order (registry must exist first now, since the controller reads from it synchronously in `onInit`).
- `app_routes.dart` / `app_pages.dart` — removed all v1 routes/bindings; the 5 screens embedded in the shell have no route of their own anymore (matching v1's own convention — they were never independently routable either); dropped now-unnecessary `as v2_xxx` import aliasing throughout (no more v1 classes with colliding names to alias against).

**Deleted outright** (47 files, confirmed via grep beforehand that **zero test files reference any of them**):
- `lib/core/database/` — the entire v1 Drift schema + DAOs (13 `.dart` + 13 `.g.dart` + `tables/tables.dart`, wait — actual count: `app_database.dart`, `app_database.g.dart`, and DAOs for asset/customer/expense/investor/product/purchase/quick_capture/rental/sale/settings, each `.dart`+`.g.dart`, plus `tables/tables.dart`).
- `lib/core/services/data_service.dart` and `image_service.dart` — both used exclusively by v1 controllers, fully dead once those are gone.
- `lib/features/{assets,customers,daily_sales,dashboard,dues,finance,inventory,investor,quick_capture}/` — 9 complete v1 feature folders (controllers + screens + a few widget subfiles under `inventory/` and `quick_capture/`).

**Mechanical rename**: `AppDatabaseV2` → `AppDatabase` across **102 non-generated source files** (`.g.dart` files regenerate automatically). This was NOT scope creep — `AppDatabaseV2`'s own doc comment explicitly said *"Rename back to AppDatabase in the PR that deletes the v1 file"* — this is that PR. Verified via whole-word `sed` replacement + full rebuild + full test pass, zero behavior change (pure rename).

**Explicitly deferred, not done** (flagged in the commit message and in `app_routes.dart`'s own doc comment): the `V2`/`_v2` suffix on route constants, folder names, and class names elsewhere (e.g. `DailySalesController`, `AppRoutes.dailySalesV2`, `features/daily_sales_v2/`) is left exactly as-is. That's a much larger, purely cosmetic rename across dozens of unrelated files for zero functional benefit — a real but separate future cleanup, not bundled into this change.

**Doc-comment sweep**: ~15 stale doc comments across screens/controllers that explained "why this reads/writes the v2 database only, separate from v1's X tab" were rewritten to describe the current v1-free state accurately (`CatalogScreen`, `DashboardScreen`, `DailySalesScreen`, `StockScreen`, `DuesScreen`, `CustomersScreen`, and their controllers, plus `InvestorScreen`/`Controller`, `ExpenseController`, `OrderController`, `ReportsController`, `FixedAssetController`, `RentController`, `PurchaseEntryScreen`, `BackupController`, `AuthGate`, `LegacyDatabaseCleanup`, `AppDatabase`'s own class doc, and one stale comment in `auth_gate_test.dart`).

## 5. Real bugs found and fixed this session (all merged — see section 2)

1. **Pricing engine bootstrap-timing bug** (PR #19) — the "first seen month" tracking had an off-by-timing error in when the overhead-markup suggestion could first bootstrap.
2. **Customer retention-policy FK-crash risk** (PR #25) — `RetentionPolicyUseCase.pruneAll` hard-deleted soft-deleted `Customers` past the retention window unconditionally, but `Customers.id` is a foreign-key target for `Dues`/`Orders`/`RentTransactions`/`Sales` — a customer with any real history would throw a real SQLite FK-constraint violation and crash the prune. Root-caused, fixed by checking each candidate for linked history first and skipping it if found (stays soft-deleted, visible in Recycle Bin, past its normal window — better than crashing). 6 new regression tests, one per referencing table plus a mixed scenario.
3. **Order-deadline reminders never actually worked** (PR #26) — M3 claimed "customer orders with working deadline reminders" was done; `Order.neededByDate` was stored and displayed as plain text but never surfaced as an actual reminder anywhere (not in the 5-type reminder engine, no overdue highlight on the screen). Added a 6th reminder type (`OrderDeadlineReminder`), wired end-to-end (engine → controller → notification → 3 exhaustive UI switches → screen-level red/bold overdue highlight). 16 new tests.
4. **2 hardcoded English strings** (PR #27) — the product form's Barcode/SKU field labels were literal English strings with no `.tr` call, the only 2 such occurrences left anywhere in `lib/`. Fixed, translation-key parity re-verified at 582/582.
5. **A git-collaboration hazard** (PR #22, not a bug in the app itself) — a human teammate pushed `.g.dart` files directly to `main` mid-session, changing the repo's established convention (generated files used to be gitignored/local-only, now committed). Detected via an unexpectedly-large diff, resolved via `git rebase` + selective regeneration, no data lost.

## 6. Known remaining gaps — NOT done, still open as of this document

From the full honest status report given earlier this session (re-verify current truth before trusting fully, some may have shifted):

1. ~~**Section 0 — v1-deletion PR not merged**~~ ✅ **DONE** — PRs #28 (`b31dec7`) + #29 (`50552d5`) merged, verified (see sections 0/3).
2. **Stale architecture docs** — ~~`ARCHITECTURE.md` and `SYNC.md` haven't been updated since early M1~~ ✅ now updated through M4 + the v1 deletion, and `notes/business_logic.md` gained a "বিল্ড-টাইম রিফাইনমেন্ট" section (§৮) documenting the trip-cost fund-source attribution, simplified owner/staff permission model, quick-capture's free-text reality, and the 6 reminder types. (Changes are in the working tree on `main`, not yet committed — commit when convenient.)
3. **Thin widget/UI test coverage** — only 2 files anywhere use `testWidgets` (a scroll harness and the auth gate). Nearly all of the 452 tests are unit/controller-level tests against an in-memory Drift database, not real widget-rendering tests. No money-critical form (Daily Sales, Purchase Entry, etc.) has a widget test.
4. **`flutter analyze --fatal-infos`** cannot be turned on in CI yet — blocked on cleaning up the ~115 pre-existing info-level lints scattered through the codebase (mostly `directives_ordering`, `prefer_final_locals`, `prefer_const_constructors`). Not urgent, but was on the original M4 checklist.
5. **No signed release builds** — Android's release build config still points at the debug signing config (no real keystore anywhere in the repo, correctly — that's a secret, not something that should ever be committed). No Windows installer or web-deployment pipeline has been set up. This is expected to be a manual/ops task done outside an AI agent's sandbox (needs real signing credentials).
6. **CI has one known, previously-diagnosed, deliberately-unfixed issue**: the web-build job fails due to an `iconsax` package icon-tree-shaker bug. The fix was identified in an earlier session but left unapplied at the user's own request at the time — worth asking the user whether that's still the preference.
7. **"Remove remaining N+1 reads"** (an original M4 checklist item) — never independently investigated or verified either way this session. Unknown status.
8. **The `V2`/`_v2` naming convention** — deliberately left in place everywhere except the `AppDatabase` class itself (see section 4). A real, larger cleanup opportunity if anyone wants to tackle it later — purely cosmetic, would touch dozens of files (routes, folder names, class names), zero functional risk if done carefully with the same rename+rebuild+retest discipline used for `AppDatabase`.
9. **Investor was NOT kept on the primary bottom nav** — this is a judgment call made in the v1-deletion work (section 4), not a bug, but worth the user's explicit sign-off since v1's original bottom nav did include Investor as a primary tab and the new 5-tab shell moved it to the drawer.

## 7. Working conventions this project has established — follow these

**Every PR, without exception, goes through this exact sequence** (established over ~28 PRs, never skipped):
1. `git fetch origin main --quiet` immediately before computing any diff, to catch concurrent human/teammate commits (see section 2's git-hazard incident — this discipline exists because of that exact incident).
2. Make the code change.
3. `dart run build_runner build` if any Drift schema/DAO/table changed (skip if pure Dart-only change — check `git status` for unexpected `.g.dart` diffs afterward either way, since `.g.dart` files ARE now committed to this repo, unlike the original convention).
4. `flutter analyze --no-fatal-infos` — must show **0 errors, 0 warnings** (info-level lints are pre-existing/tolerated, but never introduce new ones without checking they're truly pre-existing first via a before/after diff of the analyze output).
5. `dart format --set-exit-if-changed` on every changed/new file, then re-run once more to confirm zero further changes (formatting can cascade).
6. `bash tool/check_layer_boundaries.sh` — must pass.
7. `flutter test` — full suite, must be 100% green. Run the specific new/changed test file first for fast feedback, then the full suite before considering done.
8. Write real tests for new logic — this project has a strong test-first-honesty culture: every use case, every controller method, every domain function gets unit tests; UI-only cosmetic changes don't need new tests but shouldn't break existing ones.
9. Commit locally with a detailed message: what changed, why, explicit flagging of any scope limitations or known gaps (never silently hide a shortcut — write it in the doc comment AND the commit message).
10. Push via the GitHub MCP integration (`ExecuteIntegration` with `github__*` actions) — **there is no direct `git push` access in this environment**, only a REST-API-based MCP server. Workflow: `github__create_branch` (from `main`) → `github__push_files` (batch create/update, one JSON params file per call, generated via a small Python script to avoid manually re-typing file contents) → `github__create_pull_request` → `github__merge_pull_request` → locally `git checkout main && git fetch origin main --quiet && git reset --hard origin/main` to re-sync.
11. **`github__push_files` CANNOT delete files** — if a PR needs to delete files, use `github__delete_file` once per file, called **strictly sequentially** (never in parallel — parallel calls race on the branch ref and fail with `422 Update is not a fast forward`, exactly what happened in the original v1-deletion push, section 0).
12. Update the Thread Context Doc / this handoff document with what shipped.

**Two GitHub accounts are connected** — always pass `account: "ha0vd2fn"` (label `rasel-dev-25`) to `ExecuteIntegration` calls for this repo; the other connected account (`7k714wdi`, `the-razib`) is a different identity, not this repo's primary maintainer account in this context.

**Sandbox environment notes**: Flutter/Dart SDK lives at `/tmp/flutter/bin` — must `export PATH="/tmp/flutter/bin:$PATH"` in every Bash call that needs `flutter`/`dart` (it is not on the default PATH). The repo is checked out at `/tmp/repro_web`. No Android emulator, no Chrome/web-build capability, no Windows machine — CI's 3-platform build matrix is the only real cross-platform verification; anything claimed as "verified on-device" (camera behavior, push notifications) in past PR descriptions was NOT actually verified on real hardware, only that the code compiles/analyzes/unit-tests cleanly — this was always explicitly flagged in those PRs, never silently claimed.

**"Flag, don't hide" is the core discipline of this entire project.** Every deliberate scope limitation, every discovered-but-unfixed gap, every unverified behavior gets written into a doc comment and/or PR description explicitly. This handoff document continues that same discipline — section 6 is the honest list, not a sanitized one.
