import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'features/settings/controller/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Drift init ---
  final db = AppDatabase();
  Get.put<AppDatabase>(db, permanent: true);

  // --- Settings service ---
  Get.put<SettingsController>(SettingsController(), permanent: true);

  runApp(const App());
}
