import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../backup_v2/controller/backup_controller.dart';
import '../../../settings/controller/settings_controller.dart';
import '../../../storage_usage/view/widgets/drawer_storage_summary_widget.dart';
import '../../controller/shell_controller.dart';

/// Everything that isn't one of `ShellScreen`'s 5 embedded tabs — see
/// that class's own doc comment for which 5 those are. The first 5
/// tiles here are shortcuts into those same tabs (`switchTab`, matching
/// v1's own drawer convention of mirroring the bottom nav); everything
/// below the first divider is a screen with no bottom-nav slot at all.
class AppDrawer extends GetView<ShellController> {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
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
          const DrawerStorageSummaryWidget(),
          _tile(Iconsax.category, 'overview'.tr, () => controller.switchTab(0)),
          _tile(
            Iconsax.hashtag,
            'dailySales'.tr,
            () => controller.switchTab(1),
          ),
          _tile(Iconsax.box, 'stock'.tr, () => controller.switchTab(2)),
          _tile(Iconsax.book, 'dues'.tr, () => controller.switchTab(3)),
          _tile(Iconsax.people, 'customers'.tr, () => controller.switchTab(4)),
          _tile(
            Iconsax.truck,
            'purchaseEntry'.tr,
            () => controller.switchTab(5),
          ),
          const Divider(),
          _tile(Iconsax.category_2, 'products'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.catalogV2);
          }),
          _tile(Iconsax.chart, 'investor'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.investorV2);
          }),
          _tile(Iconsax.receipt, 'expenses'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.expenseV2);
          }),
          _tile(Iconsax.book_1, 'rent'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.rentV2);
          }),
          _tile(Iconsax.bookmark_2, 'orders'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.orderV2);
          }),
          _tile(Iconsax.building, 'fixedAssets'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.fixedAssetV2);
          }),
          _tile(Iconsax.microphone, 'quickCaptures'.tr, () {
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
          _tile(Iconsax.notification, 'remindersTitle'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.remindersV2);
          }),
          _tile(Iconsax.document_text, 'auditLogTitle'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.auditLogV2);
          }),
          _tile(Iconsax.trash, 'recycleBinTitle'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.recycleBinV2);
          }),
          _tile(Iconsax.user, 'account'.tr, () {
            Navigator.pop(context);
            Get.toNamed(AppRoutes.accountSettings);
          }),
          const Divider(),
          _sectionHeader('data'.tr),
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
