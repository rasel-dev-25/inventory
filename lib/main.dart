import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/database/app_database.dart';
import 'core/settings/settings_registry.dart';
import 'data/local/app_database.dart';
import 'data/local/drift_key_value_store.dart';
import 'data/remote/supabase_auth_repository.dart';
import 'data/remote/supabase_sync_transport.dart';
import 'data/sync/sync_pull_service.dart';
import 'data/sync/sync_push_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/backup_v2/controller/backup_controller.dart';
import 'features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import 'features/settings/controller/settings_controller.dart';
import 'features/sync/controller/sync_controller.dart';
import 'data/local/local_row_upserter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Supabase (M1 sync backend + auth) ---
  // Must happen before any AuthRepository/AuthController is constructed —
  // both read Supabase.instance.client, which only exists after this call
  // resolves. See ARCHITECTURE.md's "Supabase (Postgres) schema" section
  // for what's actually deployed behind this URL.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  Get.put<AuthRepository>(SupabaseAuthRepository(), permanent: true);
  Get.put<AuthController>(
    AuthController(Get.find<AuthRepository>()),
    permanent: true,
  );

  // --- v1 Drift init (still what every current screen reads/writes) ---
  final db = AppDatabase();
  Get.put<AppDatabase>(db, permanent: true);

  // --- v2 Drift init ---
  // Coexists with the v1 database above on a *different* file
  // ('al_ashab_v2' vs. the v1 file's 'inventory_db') — no conflict, no
  // shared state. Nothing reads from this yet; it is registered here so
  // the repositories/use cases landing in the next few PRs have it
  // available via DI without another main.dart change. Once every v1
  // screen is replaced, this is the point where `LegacyDatabaseCleanup`
  // (see `lib/core/db/legacy_cleanup.dart`) gets invoked and the `AppDatabase`
  // registration above comes out — not before, since v1 screens still
  // depend on that exact file.
  final dbV2 = AppDatabaseV2();
  Get.put<AppDatabaseV2>(dbV2, permanent: true);

  // --- Sync engine (outbox pusher + cursor puller) ---
  // See SYNC.md for the design. Registered here (not lazily per-screen)
  // since the "Sync Now" affordance and its pending-outbox-count badge
  // need to exist app-wide, not just on whichever screen last opened it.
  final syncTransport = SupabaseSyncTransport();
  Get.put<SyncController>(
    SyncController(
      db: dbV2,
      pushService: SyncPushService(dbV2.syncMetadataDao, syncTransport),
      pullService: SyncPullService(
        dbV2.syncMetadataDao,
        syncTransport,
        LocalRowUpserter(dbV2),
      ),
      authController: Get.find<AuthController>(),
      connectivityChanges: Connectivity().onConnectivityChanged,
    ),
    permanent: true,
  );

  // --- Settings service (v1) ---
  Get.put<SettingsController>(SettingsController(), permanent: true);

  // --- Settings registry (v2) ---
  // The real, restart-surviving `SettingsRegistry` backing store —
  // `DriftKeyValueStore`'s own doc comment explains why `hydrate()` must
  // be awaited here, before anything reads from it (the pricing engine's
  // `PricingSettingsController` is the first real caller).
  final settingsStore = DriftKeyValueStore(dbV2.appSettingsDao);
  await settingsStore.hydrate();
  final settingsRegistry = SettingsRegistry(settingsStore);
  Get.put<SettingsRegistry>(settingsRegistry, permanent: true);

  // --- Pricing engine (business_logic.md's overhead-markup suggestion) ---
  // Permanent, not lazy — see `PricingSettingsController`'s own doc
  // comment for why `CatalogController` needs to find this regardless of
  // whether the owner ever opened the Pricing Settings screen.
  Get.put<PricingSettingsController>(
    PricingSettingsController(dbV2, settingsRegistry),
    permanent: true,
  );

  // --- Backup/restore (v2, crash-safe) ---
  // Permanent so the drawer's "Backup Data (v2)"/"Restore Data (v2)"
  // actions can `Get.find` it without a dedicated screen/binding.
  Get.put<BackupController>(BackupController(dbV2), permanent: true);

  runApp(const App());
}
