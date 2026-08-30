import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/product.dart';
import '../../catalog/view/product_form_sheet.dart';
import '../controller/stock_controller.dart';

/// The upgraded Stock screen — horizontal category & investor filter chips,
/// real-time summary metrics, rich stock product cards, detail modals, and direct
/// product creation with opening stock, barcode scanning, and photos.
class StockScreen extends GetView<StockController> {
  final VoidCallback? onMenuTap;

  const StockScreen({super.key, this.onMenuTap});

  Future<void> _openProductForm(
    BuildContext context, {
    Product? existing,
  }) async {
    final result = await showModalBottomSheet<ProductFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ProductFormSheet(
        existing: existing,
        categories: controller.categories.map((c) => c.name).toList(),
        investors: controller.investors,
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
        isRentable: result.isRentable,
        barcode: result.barcode,
        sku: result.sku,
        pageCount: result.pageCount,
        photoLocalPath: result.photoLocalPath,
      );
    }
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('addCategory'.tr),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'categoryName'.tr,
            hintText: 'e.g. Attar, Books, Dates',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(textController.text.trim()),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await controller.createCategory(name);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${'delete'.tr} ${product.name}?'),
        content: Text('deleteProductConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.softDeleteProduct(product.id);
    }
  }

  void _showProductDetails(BuildContext context, Product product) {
    final image = controller.primaryImageFor(product.id);
    final imageSource = image == null ? null : controller.imageSourceFor(image);
    final unitProfit = product.suggestedSellPrice - product.costPrice;
    final totalCost = product.costPrice * product.qty;
    final totalSale = product.suggestedSellPrice * product.qty;
    final totalPotentialProfit = totalSale - totalCost;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (imageSource != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: imageSource.startsWith('http')
                        ? Image.network(
                            imageSource,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(imageSource),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),

            // Metrics Grid
            Row(
              children: [
                _detailTile(
                  context,
                  label: 'costLabel'.tr,
                  value: product.costPrice.format(),
                  icon: Icons.shopping_bag_outlined,
                ),
                _detailTile(
                  context,
                  label: 'sellPriceLabel'.tr,
                  value: product.suggestedSellPrice.format(),
                  icon: Icons.sell_outlined,
                ),
                _detailTile(
                  context,
                  label: 'profitMargin'.tr,
                  value: unitProfit.format(),
                  icon: Icons.trending_up,
                  color: unitProfit.isNegative ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _detailTile(
                  context,
                  label: 'stockLabel'.tr,
                  value:
                      '${product.qty.toStringAsFixed(product.qty == product.qty.roundToDouble() ? 0 : 2)} pcs',
                  icon: Icons.inventory_outlined,
                  color: product.qty <= 0
                      ? Colors.red
                      : (product.qty <= 5 ? Colors.orange : Colors.green),
                ),
                _detailTile(
                  context,
                  label: 'stockValue'.tr,
                  value: totalCost.format(),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _detailTile(
                  context,
                  label: 'potentialProfit'.tr,
                  value: totalPotentialProfit.format(),
                  icon: Icons.monetization_on_outlined,
                  color: totalPotentialProfit.isNegative
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Metadata List
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: Text('fundSource'.tr),
              subtitle: Text(
                product.fundSource.isShop
                    ? 'shop'.tr
                    : controller.investorName(product.fundSource.investorId!),
              ),
            ),
            if (product.barcode != null && product.barcode!.isNotEmpty)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code),
                title: Text('barcode'.tr),
                subtitle: Text(product.barcode!),
              ),
            if (product.sku != null && product.sku!.isNotEmpty)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag),
                title: Text('sku'.tr),
                subtitle: Text(product.sku!),
              ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDelete(context, product);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      'delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openProductForm(context, existing: product);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text('edit'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'stockAndAssets'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        final items = controller.filteredProducts;
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // 1. Category Filter Chips
            _CategoryChips(onAddCategory: () => _showAddCategoryDialog(context)),
            const SizedBox(height: AppSpacing.xs),

            // 2. Investor Filter Chips
            const _InvestorChips(),
            const SizedBox(height: AppSpacing.md),

            // 3. Summary Cards
            const _StockSummaryCard(),
            const SizedBox(height: AppSpacing.md),

            // 4. Products List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'products'.tr} (${items.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (controller.selectedCategory.value != null ||
                    controller.selectedFundFilter.value != null)
                  TextButton(
                    onPressed: () {
                      controller.selectedCategory.value = null;
                      controller.selectedFundFilter.value = null;
                    },
                    child: Text('clearFilter'.tr),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // 5. Products List
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'noProductsYet'.tr,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _openProductForm(context),
                        icon: const Icon(Icons.add),
                        label: Text('addNewProduct'.tr),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final product in items)
                _ProductCard(
                  product: product,
                  onTap: () => _showProductDetails(context, product),
                  onEdit: () => _openProductForm(context, existing: product),
                  onDelete: () => _confirmDelete(context, product),
                ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'stock_fab',
        tooltip: 'addNewProduct'.tr,
        onPressed: () => _openProductForm(context),
        icon: const Icon(Icons.add),
        label: Text('addNewProduct'.tr),
      ),
    );
  }
}

class _CategoryChips extends GetView<StockController> {
  final VoidCallback onAddCategory;

  const _CategoryChips({required this.onAddCategory});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      final categories = controller.categories;
      final totalCount = controller.products.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'filterByCategory'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
              ),
              InkWell(
                onTap: onAddCategory,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'addCategory'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('${'allCategories'.tr} ($totalCount)'),
                  selected: selected == null,
                  onSelected: (_) => controller.selectedCategory.value = null,
                ),
                const SizedBox(width: 6),
                for (final cat in categories) ...[
                  ChoiceChip(
                    label: Text(
                      '${cat.name} (${controller.countForCategory(cat.name)})',
                    ),
                    selected: selected == cat.name,
                    onSelected: (val) => controller.selectedCategory.value =
                        val ? cat.name : null,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _InvestorChips extends GetView<StockController> {
  const _InvestorChips();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedFundFilter.value;
      final investors = controller.investors;
      final shopCount = controller.countForFundSource(shopFundFilterValue);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'filterByInvestor'.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('allInvestors'.tr),
                  selected: selected == null,
                  onSelected: (_) =>
                      controller.selectedFundFilter.value = null,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: Text('${'shop'.tr} ($shopCount)'),
                  selected: selected == shopFundFilterValue,
                  onSelected: (val) => controller.selectedFundFilter.value =
                      val ? shopFundFilterValue : null,
                ),
                const SizedBox(width: 6),
                for (final inv in investors) ...[
                  ChoiceChip(
                    label: Text(
                      '${inv.name} (${controller.countForFundSource(inv.id)})',
                    ),
                    selected: selected == inv.id,
                    onSelected: (val) => controller.selectedFundFilter.value =
                        val ? inv.id : null,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _StockSummaryCard extends GetView<StockController> {
  const _StockSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.filteredProducts.length;
      final value = controller.totalCostValue.format();
      final profit = controller.potentialProfit.format();
      final isProfitNegative = controller.potentialProfit.isNegative;

      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _statItem(context, label: 'products'.tr, value: '$count'),
            Container(width: 1, height: 32, color: Colors.grey.shade300),
            _statItem(context, label: 'stockValue'.tr, value: value),
            Container(width: 1, height: 32, color: Colors.grey.shade300),
            _statItem(
              context,
              label: 'potentialProfit'.tr,
              value: profit,
              color: isProfitNegative ? Colors.red : Colors.green.shade700,
            ),
          ],
        ),
      );
    });
  }

  Widget _statItem(
    BuildContext context, {
    required String label,
    required String value,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends GetView<StockController> {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final image = controller.primaryImageFor(product.id);
    final imageSource = image == null ? null : controller.imageSourceFor(image);

    final isOutOfStock = product.qty <= 0;
    final isLowStock = product.qty > 0 && product.qty <= 5;
    final stockColor = isOutOfStock
        ? Colors.red
        : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOutOfStock
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Product Image or Icon
              if (imageSource != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageSource.startsWith('http')
                      ? Image.network(
                          imageSource,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(imageSource),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${'buy'.tr}: ${product.costPrice.format()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '  •  ${'sell'.tr}: ${product.suggestedSellPrice.format()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOutOfStock
                                ? 'outOfStock'.tr
                                : '${'stockLabel'.tr} ${product.qty.toStringAsFixed(product.qty == product.qty.roundToDouble() ? 0 : 2)} pcs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'details') onTap();
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('productDetails'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('edit'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('delete'.tr,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
