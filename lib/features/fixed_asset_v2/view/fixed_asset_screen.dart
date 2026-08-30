import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../controller/fixed_asset_controller.dart';

/// The v2 Fixed Asset screen — direct cash purchase or convert-from-stock,
/// per `notes/business_logic.md`'s Fixed Asset section, backed by
/// [FixedAssetController].
class FixedAssetScreen extends GetView<FixedAssetController> {
  const FixedAssetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'fixedAssets'.tr} (v2)')),
      body: Obx(() {
        if (controller.assets.isEmpty) {
          return Center(child: Text('noAssetsYet'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.assets.length,
          itemBuilder: (context, index) {
            final asset = controller.assets[index];
            final fromStock =
                asset.sourceType == FixedAssetSource.convertedFromStock;
            return Dismissible(
              key: ValueKey(asset.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              confirmDismiss: (_) => _confirmDelete(context, asset.name),
              onDismissed: (_) => controller.deleteAsset(asset.id),
              child: Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: _assetThumbnail(asset.id),
                  title: Text(asset.name),
                  subtitle: Text(
                    fromStock ? 'convertFromStock'.tr : 'directPurchase'.tr,
                  ),
                  trailing: Text(
                    asset.value.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fixed_asset_fab',
        onPressed: () => _openSourceChoice(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openSourceChoice(BuildContext context) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('directPurchase'.tr),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text('convertFromStock'.tr),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice) {
      await _openConvertFromStockDialog(context);
    } else {
      await _openCashPurchaseDialog(context);
    }
  }

  Future<void> _openCashPurchaseDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? photoLocalPath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('directPurchase'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(labelText: 'assetName'.tr),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'nameRequired'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'assetValue'.tr),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await controller.captureFixedAssetPhoto();
                        if (path != null) {
                          setState(() => photoLocalPath = path);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        photoLocalPath == null
                            ? 'addAssetPhoto'.tr
                            : 'changeAssetPhoto'.tr,
                      ),
                    ),
                    if (photoLocalPath case final photoPath?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(
                          File(photoPath),
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 140,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Obx(
                      () => controller.errorMessage.value == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                controller.errorMessage.value!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.createFromCashPurchase(
                      name: nameController.text,
                      value: _parseMoneyOrNull(valueController.text)!,
                      dateAcquired: DateTime.now(),
                      photoLocalPath: photoLocalPath,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openConvertFromStockDialog(BuildContext context) async {
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? photoLocalPath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('convertFromStock'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: productId,
                        decoration: InputDecoration(
                          labelText: 'selectProduct'.tr,
                        ),
                        items: [
                          for (final p in controller.products)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${'stockLabel'.tr}${p.qty})',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          productId = v;
                          final product = controller.productById(v ?? '');
                          if (product != null && nameController.text.isEmpty) {
                            nameController.text = product.name;
                          }
                        }),
                        validator: (v) => v == null ? 'selectProduct'.tr : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'quantityToConvert'.tr,
                      ),
                      validator: (v) => double.tryParse(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'assetName'.tr),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await controller.captureFixedAssetPhoto();
                        if (path != null) {
                          setState(() => photoLocalPath = path);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        photoLocalPath == null
                            ? 'addAssetPhoto'.tr
                            : 'changeAssetPhoto'.tr,
                      ),
                    ),
                    if (photoLocalPath case final photoPath?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(
                          File(photoPath),
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 140,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Obx(
                      () => controller.errorMessage.value == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                controller.errorMessage.value!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.createFromStock(
                      productId: productId!,
                      qty: double.parse(qtyController.text),
                      name: nameController.text.trim().isEmpty
                          ? null
                          : nameController.text.trim(),
                      photoLocalPath: photoLocalPath,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Same confirm-before-dismiss pattern `CustomersScreen`'s
  /// `_confirmDelete` establishes — extra warranted here since, unlike a
  /// product or customer, this delete is *not* restorable (see
  /// `FixedAssetUseCases.delete`'s own doc comment).
  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr} $name?'),
        content: Text('cannotUndoNote'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Widget _assetThumbnail(String assetId) {
    final image = controller.primaryImageFor(assetId);
    final source = image == null ? null : controller.imageSourceFor(image);
    if (source == null) {
      return const CircleAvatar(child: Icon(Icons.business_center_outlined));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: source.startsWith('http')
          ? Image.network(source, width: 48, height: 48, fit: BoxFit.cover)
          : Image.file(File(source), width: 48, height: 48, fit: BoxFit.cover),
    );
  }
}

/// Same pattern as every other v2 form field — `Money` has no `tryParse`,
/// see `daily_sales_v2`'s doc comment for why every live-input field
/// wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
