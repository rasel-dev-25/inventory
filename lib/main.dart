import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'data/local/app_database.dart';
import 'features/settings/controller/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // --- Settings service ---
  Get.put<SettingsController>(SettingsController(), permanent: true);

  runApp(const App());
}
