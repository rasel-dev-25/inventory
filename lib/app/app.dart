import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'translations/app_translations.dart';
import '../features/settings/controller/settings_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Al Ashab',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.shell,
        getPages: AppPages.pages,
        translations: AppTranslations(),
        locale: settings.currentLocale.value == 'bn'
            ? const Locale('bn', 'BD')
            : const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.isDark.value ? ThemeMode.dark : ThemeMode.light,
      ),
    );
  }
}
