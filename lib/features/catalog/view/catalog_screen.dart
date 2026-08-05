import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/entities/product.dart';
import '../controller/catalog_controller.dart';
import 'product_form_sheet.dart';

/// The v2 categories + products screen — reads from [AppDatabaseV2] via
/// [CatalogController], reached from the v1 shell's drawer as a clearly
/// separate "New" section rather than replacing the v1 Inventory tab.
///
/// Deliberately not wired into the v1 shell's tab bar: v1's Daily
/// Sales/Dues/Finance/Dashboard screens all read products from the
/// *v1* database, a completely separate file from the v2 one this
/// screen reads/writes. Replacing the v1 Inventory tab with this screen
/// would silently split one shop's catalog into two disconnected
/// copies — a product created here would not be sellable from v1's
/// Daily Sales screen. That reconciliation is out of scope until v1's
/// remaining screens are themselves migrated to v2.
class CatalogScreen extends GetView<CatalogController> {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${'products'.tr} (v2)'),
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
                  return ListTile(
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
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
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
        overheadMarkupPercent: controller.overheadMarkupPercent,
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
        isRentable: result.isRentable,
        barcode: result.barcode,
        sku: result.sku,
        pageCount: result.pageCount,
      );
    } else {
      await controller.updateProduct(
        existing,
        name: result.name,
        category: result.category,
        costPrice: result.costPrice,
        suggestedSellPrice: result.suggestedSellPrice,
        fundSource: result.fundSource,
        isRentable: result.isRentable,
        barcode: result.barcode,
        sku: result.sku,
        pageCount: result.pageCount,
      );
    }
  }
}
