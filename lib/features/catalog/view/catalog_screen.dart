import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../domain/entities/product.dart';
import '../controller/catalog_controller.dart';
import 'product_form_sheet.dart';

/// The categories + products screen, reached from [AppDrawer] —
/// backed by [CatalogController]. Not one of `ShellScreen`'s 5 embedded
/// tabs (see that class's own doc comment): editing the catalog itself
/// is less frequent than the day-to-day screens that read from it.
class CatalogScreen extends GetView<CatalogController> {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('products'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'category'.tr),
              Tab(text: 'products'.tr),
            ],
          ),
        ),
        body: TabBarView(children: [_CategoriesTab(), _ProductsTab()]),
      ),
    );
  }
}

class _CategoriesTab extends GetView<CatalogController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sorted = [...controller.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Scaffold(
        body: sorted.isEmpty
            ? Center(child: Text('noCategoriesYet'.tr))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final category = sorted[index];
                  return ListTile(
                    title: Text(category.name),
                    onTap: () =>
                        _showRenameDialog(context, category.id, category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'moveUp'.tr,
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: index == 0
                              ? null
                              : () =>
                                    controller.moveCategory(category, up: true),
                        ),
                        IconButton(
                          tooltip: 'moveDown'.tr,
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: index == sorted.length - 1
                              ? null
                              : () => controller.moveCategory(
                                  category,
                                  up: false,
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'catalog_categories_fab',
          onPressed: () => _showRenameDialog(context, null, ''),
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    String? id,
    String initialName,
  ) async {
    final textController = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'addCategory'.tr : 'category'.tr),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(labelText: 'categoryName'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: textController.text),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    if (id == null) {
      await controller.createCategory(result);
    } else {
      await controller.renameCategory(id, result);
    }
  }
}

class _ProductsTab extends GetView<CatalogController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.products;
      return Scaffold(
        body: items.isEmpty
            ? Center(child: Text('noProductsYet'.tr))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  final productImage = controller.primaryImageFor(product.id);
                  final imageSource = productImage == null
                      ? null
                      : controller.imageSourceFor(productImage);
                  return Dismissible(
                    key: ValueKey(product.id),
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
                    confirmDismiss: (_) =>
                        _confirmDelete(context, product.name),
                    onDismissed: (_) => controller.deleteProduct(product.id),
                    child: ListTile(
                      leading: imageSource == null
                          ? const CircleAvatar(
                              child: Icon(Icons.inventory_2_outlined),
                            )
                          : GestureDetector(
                              onTap: () => showFullScreenImageViewer(
                                context,
                                imagePath: imageSource,
                                title: product.name,
                                subtitle: '${product.category} · ${product.suggestedSellPrice.format()}',
                                heroTag: 'product_image_${product.id}',
                              ),
                              child: Hero(
                                tag: 'product_image_${product.id}',
                                child: SafeImage(
                                  source: imageSource,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  fallbackIcon: Icons.inventory_2_outlined,
                                ),
                              ),
                            ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} · ${product.suggestedSellPrice.format()}',
                      ),
                      trailing: Text(
                        product.qty.toStringAsFixed(
                          product.qty == product.qty.roundToDouble() ? 0 : 2,
                        ),
                      ),
                      onTap: () => _openForm(context, existing: product),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'catalog_products_fab',
          onPressed: () => _openForm(context),
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Future<void> _openForm(BuildContext context, {Product? existing}) async {
    final result = await showModalBottomSheet<ProductFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductFormSheet(
        existing: existing,
        categories: controller.categories.map((c) => c.name).toList(),
        investors: controller.investors,
        units: controller.units.map((u) => u.name).toList(),
        onCreateCategory: (name) async {
          final ok = await controller.createCategory(name);
          return ok ? name.trim() : null;
        },
        overheadMarkupPercent: controller.overheadMarkupPercent,
        onCapturePhoto: controller.captureProductPhoto,
        existingPhotoPath: existing == null
            ? null
            : controller.primaryImageFor(existing.id)?.localPath,
      ),
    );
    if (result == null) return;

    if (existing == null) {
      await controller.createProduct(
        name: result.name,
        category: result.category,
        costPrice: result.costPrice,
        suggestedSellPrice: result.suggestedSellPrice,
        fundSource: result.fundSource,
        unit: result.unit,
        sellUnit: result.sellUnit,
        isRentable: result.isRentable,
        initialQty: result.initialQty,
        barcode: result.barcode,
        sku: result.sku,
        pageCount: result.pageCount,
        photoLocalPath: result.photoLocalPath,
      );
    } else {
      await controller.updateProduct(
        existing,
        name: result.name,
        category: result.category,
        costPrice: result.costPrice,
        suggestedSellPrice: result.suggestedSellPrice,
        qty: result.initialQty,
        fundSource: result.fundSource,
        unit: result.unit,
        sellUnit: result.sellUnit,
        isRentable: result.isRentable,
        barcode: result.barcode,
        sku: result.sku,
        pageCount: result.pageCount,
        photoLocalPath: result.photoLocalPath,
      );
    }
  }

  /// Same confirm-before-dismiss pattern `CustomersScreen`'s
  /// `_confirmDelete` establishes — a product delete is restorable from
  /// the Recycle Bin, but the swipe-to-dismiss gesture itself is
  /// destructive-looking enough to still warrant a pause.
  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr} $name?'),
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
}
