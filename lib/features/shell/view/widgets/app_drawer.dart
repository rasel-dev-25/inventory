import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/database/app_database.dart';
import '../../controller/shell_controller.dart';
import '../../../settings/controller/settings_controller.dart';

class AppDrawer extends GetView<ShellController> {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final dataService = DataService(Get.find<AppDatabase>());
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kTeal),
            child: SizedBox(
              width: double.infinity,
              child: shopLogo(size: 24, color: Colors.white),
            ),
          ),
          _tile(Iconsax.category, 'overview'.tr, () => controller.switchTab(0)),
          _tile(
            Iconsax.hashtag,
            'dailySales'.tr,
            () => controller.switchTab(1),
          ),
          _tile(
            Iconsax.shop,
            'stockAndAssets'.tr,
            () => controller.switchTab(2),
          ),
          _tile(Iconsax.book, 'dues'.tr, () => controller.switchTab(3)),
          _tile(
            Iconsax.receipt,
            'expensesAndPurchases'.tr,
            () => controller.switchTab(4),
          ),
          _tile(Iconsax.chart, 'investor'.tr, () => controller.switchTab(5)),
          _tile(Iconsax.people, 'customers'.tr, () => controller.switchTab(6)),
          const Divider(),
          _sectionHeader('utilities'.tr),
          _tile(Iconsax.bookmark, 'quickCaptures'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.quickCapture);
          }),
          _tile(Iconsax.building, 'fixedAssets'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.assets);
          }),
          const Divider(),
          // ── M1 v2 preview — reads/writes the new synced database, kept
          // clearly separate from the v1 tabs above until the rest of the
          // app is migrated too (see CatalogScreen's doc comment).
          _sectionHeader('New (v2 preview)'),
          _tile(Iconsax.category_2, 'products'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.catalogV2);
          }),
          _tile(Iconsax.truck, 'purchaseEntry'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.purchaseEntryV2);
          }),
          _tile(Iconsax.hashtag, '${'dailySales'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.dailySalesV2);
          }),
          _tile(Iconsax.book, '${'dues'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.duesV2);
          }),
          _tile(Iconsax.user, 'account'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.accountSettings);
          }),
          const Divider(),
          _sectionHeader('data'.tr),
          _tile(Iconsax.export_1, 'exportData'.tr, () {
            Navigator.pop(context);
            dataService.exportData();
          }),
          _tile(Iconsax.import_1, 'importData'.tr, () {
            Navigator.pop(context);
            dataService.importData();
          }),
          _tile(Iconsax.microscope, 'seedSampleData'.tr, () {
            Navigator.pop(context);
            dataService.seedSampleData();
          }),
          const Divider(),
          Obx(
            () => SwitchListTile(
              secondary: Icon(
                settings.isDark.value ? Iconsax.moon : Iconsax.sun,
                color: kTeal,
              ),
              title: Text('darkTheme'.tr),
              value: settings.isDark.value,
              onChanged: (val) => settings.toggleDarkMode(val),
            ),
          ),
          Obx(
            () => SwitchListTile(
              secondary: const Icon(Iconsax.global, color: kTeal),
              title: Text('language'.tr),
              subtitle: Text(
                settings.currentLocale.value == 'bn'
                    ? 'bangla'.tr
                    : 'english'.tr,
              ),
              value: settings.currentLocale.value == 'bn',
              onChanged: (_) => settings.toggleLanguage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
