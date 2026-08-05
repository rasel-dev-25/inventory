import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings/settings_registry.dart';

/// App-wide theme + language, read by [App] itself (`app/app.dart`) —
/// this has to exist before any screen does, which is why it's a
/// permanent `GetxService`, not a per-screen controller.
///
/// Backed by [SettingsRegistry] (the same v2 key-value store the pricing
/// engine uses), not a bespoke DAO of its own — previously this read/
/// wrote through v1's `AppDatabase`/`SettingsDao`, the last thing still
/// pointed at that database once every v1 feature screen was removed.
/// [SettingsRegistry] must already be registered (`main.dart` does this
/// before constructing this class) since [_isDarkKey]/[_localeKey] are
/// read synchronously via [SettingsRegistry.get] in [onInit], not
/// awaited from a DAO call — a plain key-value read, not a query.
class SettingsController extends GetxService {
  final SettingsRegistry _settings;

  SettingsController(this._settings);

  static final _isDarkKey = SettingKey.boolean('isDark', defaultValue: false);
  static final _localeKey = SettingKey.string('locale', defaultValue: 'en');

  final isDark = false.obs;
  final currentLocale = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    isDark.value = _settings.get(_isDarkKey);
    currentLocale.value = _settings.get(_localeKey);
    _applyTheme();
    _applyLocale();
  }

  void toggleDarkMode(bool val) {
    isDark.value = val;
    _settings.set(_isDarkKey, val);
    _applyTheme();
  }

  void toggleLanguage() {
    final next = currentLocale.value == 'en' ? 'bn' : 'en';
    currentLocale.value = next;
    _settings.set(_localeKey, next);
    _applyLocale();
  }

  void setLanguage(String code) {
    currentLocale.value = code;
    _settings.set(_localeKey, code);
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
