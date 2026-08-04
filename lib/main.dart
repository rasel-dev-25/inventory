import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/database/app_database.dart';
import 'data/local/app_database.dart';
import 'data/remote/supabase_auth_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/settings/controller/settings_controller.dart';

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

  // --- Settings service ---
  Get.put<SettingsController>(SettingsController(), permanent: true);

  runApp(const App());
}
