import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/db/legacy_cleanup.dart';
import 'core/notifications/notification_service.dart';
import 'core/platform/capabilities.dart';
import 'core/settings/settings_registry.dart';
import 'data/local/app_database.dart';
import 'data/local/drift_key_value_store.dart';
import 'data/local/local_row_upserter.dart';
import 'data/local/local_storage_metrics_service.dart';
import 'data/remote/cloudinary_storage_upload_transport.dart';
import 'data/remote/supabase_auth_repository.dart';
import 'data/remote/supabase_storage_metrics_service.dart';
import 'data/remote/supabase_storage_upload_transport.dart';
import 'data/remote/supabase_sync_transport.dart';
import 'data/sync/pending_upload_service.dart';
import 'data/sync/storage_upload_transport.dart';
import 'data/sync/sync_pull_service.dart';
import 'data/sync/sync_push_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/backup_v2/controller/backup_controller.dart';
import 'features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import 'features/reminders_v2/controller/reminder_controller.dart';
import 'features/settings/controller/settings_controller.dart';
import 'features/storage_usage/controller/storage_usage_controller.dart';
import 'features/sync/controller/sync_controller.dart';

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
  // --- v2 Drift init (the only database now) ---
  final dbV2 = AppDatabase();
  Get.put<AppDatabase>(dbV2, permanent: true);

  Get.put<AuthRepository>(SupabaseAuthRepository(), permanent: true);
  Get.put<AuthController>(
    AuthController(Get.find<AuthRepository>()),
    permanent: true,
  );

  // --- Legacy v1 database cleanup ---
  // Every v1 feature screen has been removed (this app is new enough
  // that there was no real production data to migrate — see
  // `LegacyDatabaseCleanup`'s own doc comment for the "not yet called"
  // note this call site replaces). Best-effort and idempotent: a device
  // that never had the v1 database installed just finds nothing to
  // delete. Deliberately not awaited before continuing startup — this
  // is disk housekeeping, not something any other registration below
  // depends on.
  unawaited(
    getApplicationDocumentsDirectory().then(LegacyDatabaseCleanup.deleteFrom),
  );

  // --- Sync engine (outbox pusher + cursor puller) ---
  // See SYNC.md for the design. Registered here (not lazily per-screen)
  // since the "Sync Now" affordance and its pending-outbox-count badge
  // need to exist app-wide, not just on whichever screen last opened it.
  final syncTransport = SupabaseSyncTransport();
  final storageTransport = CloudinaryStorageUploadTransport();
  Get.put<StorageUploadTransport>(storageTransport, permanent: true);
  Get.put<CloudinaryStorageUploadTransport>(storageTransport, permanent: true);
  // Keep SupabaseStorageUploadTransport registered for backward compatibility if needed
  Get.put<SupabaseStorageUploadTransport>(
    SupabaseStorageUploadTransport(),
    permanent: true,
  );
  Get.put<SyncController>(
    SyncController(
      db: dbV2,
      pushService: SyncPushService(dbV2.syncMetadataDao, syncTransport),
      pullService: SyncPullService(
        dbV2.syncMetadataDao,
        syncTransport,
        LocalRowUpserter(dbV2),
      ),
      uploadService: PendingUploadService(
        dbV2,
        dbV2.syncMetadataDao,
        storageTransport,
      ),
      authController: Get.find<AuthController>(),
      connectivityChanges: Connectivity().onConnectivityChanged,
    ),
    permanent: true,
  );

  // --- Settings registry ---
  // The real, restart-surviving `SettingsRegistry` backing store —
  // `DriftKeyValueStore`'s own doc comment explains why `hydrate()` must
  // be awaited here, before anything reads from it. Must exist before
  // `SettingsController` below, which reads from it synchronously in its
  // own `onInit`.
  final settingsStore = DriftKeyValueStore(dbV2.appSettingsDao);
  await settingsStore.hydrate();
  final settingsRegistry = SettingsRegistry(settingsStore);
  Get.put<SettingsRegistry>(settingsRegistry, permanent: true);

  // --- App-wide theme + language ---
  // See `SettingsController`'s own doc comment — this used to read/write
  // through v1's now-deleted `AppDatabase`/`SettingsDao`; it's the
  // `SettingsRegistry` above now, same as the pricing engine.
  Get.put<SettingsController>(
    SettingsController(settingsRegistry),
    permanent: true,
  );

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

  // --- Reminders + notifications (M4) ---
  // NotificationService.initialize() is awaited here (it's a safe no-op
  // on Windows/Web, and idempotent) so the Android permission prompt/
  // channel setup has already happened before ReminderController's
  // first reminder computation could try to show one. Both permanent —
  // see ReminderController's own doc comment for why it needs to keep
  // running even when the Reminders screen is never opened.
  final notificationService = NotificationService(
    PlatformCapabilities.detect(),
  );
  await notificationService.initialize();
  Get.put<ReminderController>(
    ReminderController(dbV2, notificationService),
    permanent: true,
  );

  // --- Storage usage metrics (drawer & cloud breakdown) ---
  final storageMetricsService = SupabaseStorageMetricsService();
  final localMetricsService = LocalStorageMetricsService(dbV2);
  Get.put<StorageUsageController>(
    StorageUsageController(
      remoteService: storageMetricsService,
      localService: localMetricsService,
      authController: Get.find<AuthController>(),
    ),
    permanent: true,
  );

  runApp(const App());
}
