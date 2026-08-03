import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/settings_dao.dart';

class SettingsController extends GetxService {
  final SettingsDao _dao = Get.find<AppDatabase>().settingsDao;

  final isDark = false.obs;
  final currentLocale = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    isDark.value = await _dao.getBool('isDark', defaultValue: false);
    currentLocale.value = await _dao.getValue('locale') ?? 'en';
    _applyTheme();
    _applyLocale();
  }

  Future<void> toggleDarkMode(bool val) async {
    isDark.value = val;
    await _dao.setBool('isDark', val);
    _applyTheme();
  }

  Future<void> toggleLanguage() async {
    final next = currentLocale.value == 'en' ? 'bn' : 'en';
    currentLocale.value = next;
    await _dao.setValue('locale', next);
    _applyLocale();
  }

  Future<void> setLanguage(String code) async {
    currentLocale.value = code;
    await _dao.setValue('locale', code);
    _applyLocale();
  }

  void _applyTheme() {
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  void _applyLocale() {
    final locale = currentLocale.value == 'bn'
        ? const Locale('bn', 'BD')
        : const Locale('en', 'US');
    Get.updateLocale(locale);
  }
}
