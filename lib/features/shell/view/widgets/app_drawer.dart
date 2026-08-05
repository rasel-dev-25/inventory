import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../backup_v2/controller/backup_controller.dart';
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
          _tile(Iconsax.people, '${'customers'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.customersV2);
          }),
          _tile(Iconsax.shop, '${'stockAndAssets'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.stockV2);
          }),
          _tile(Iconsax.category, '${'overview'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.dashboardV2);
          }),
          _tile(Iconsax.chart, '${'investor'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.investorV2);
          }),
          _tile(Iconsax.receipt, '${'expenses'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.expenseV2);
          }),
          _tile(Iconsax.book_1, '${'rent'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.rentV2);
          }),
          _tile(Iconsax.bookmark_2, '${'orders'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.orderV2);
          }),
          _tile(Iconsax.building, '${'fixedAssets'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.fixedAssetV2);
          }),
          _tile(Iconsax.microphone, '${'quickCaptures'.tr} (v2)', () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.quickCaptureV2);
          }),
          _tile(Iconsax.chart_2, 'pricingSettingsTitle'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.pricingSettingsV2);
          }),
          _tile(Iconsax.chart_1, 'reportsTitle'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.reportsV2);
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
          _tile(Iconsax.cloud_add, 'backupDataV2'.tr, () {
            Navigator.pop(context);
            Get.find<BackupController>().exportAndShare();
          }),
          _tile(Iconsax.cloud_lightning, 'restoreDataV2'.tr, () {
            Navigator.pop(context);
            _restoreV2();
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

  /// Lists candidate `backup_v2_*.json` files, lets the owner pick one via
  /// a `Get.dialog` (context-independent — deliberate, since the drawer
  /// that triggered this has already closed by the time any of these
  /// dialogs would show), confirms the destructive replace, then restores.
  Future<void> _restoreV2() async {
    final controller = Get.find<BackupController>();
    final files = await controller.listBackupFiles();
    if (files.isEmpty) {
      Get.snackbar(
        '',
        'noBackupFilesFoundV2'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selected = await Get.dialog<File>(
      SimpleDialog(
        title: Text('selectBackupFileV2'.tr),
        children: files.map((f) {
          final name = f.path.split(Platform.pathSeparator).last;
          return SimpleDialogOption(
            child: Text(name),
            onPressed: () => Get.back(result: f),
          );
        }).toList(),
      ),
    );
    if (selected == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('restoreConfirmTitle'.tr),
        content: Text('restoreConfirmMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('restoreDataV2'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.restoreFrom(selected);
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
