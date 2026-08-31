import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/notification_bell_action.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/product.dart';
import '../../catalog/view/product_form_sheet.dart';
import '../controller/stock_controller.dart';

/// The upgraded, clean, organized Stock screen — live search, status filters,
/// modern financial overview, clean category carousel, and sleek product cards.
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
                  GestureDetector(
                    onTap: () => showFullScreenImageViewer(
                      context,
                      imagePath: imageSource,
                      title: product.name,
                      subtitle: product.category,
                      heroTag: 'product_sheet_image_${product.id}',
                    ),
                    child: Hero(
                      tag: 'product_sheet_image_${product.id}',
                      child: SafeImage(
                        source: imageSource,
                        width: 60,
                        height: 60,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        fallbackIcon: Icons.inventory_2_outlined,
                      ),
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
                      '${product.qty.toStringAsFixed(product.qty == product.qty.roundToDouble() ? 0 : 2)} ${product.sellUnit}',
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'stockAndAssets'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        actions: [
          Obx(() {
            final hasFilter = controller.selectedCategory.value != null ||
                controller.selectedFundFilter.value != null ||
                controller.stockStatusFilter.value != 'all' ||
                controller.searchQuery.value.isNotEmpty;
            if (!hasFilter) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              tooltip: 'clearFilter'.tr,
              onPressed: controller.resetFilters,
            );
          }),
          const NotificationBellAction(),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final items = controller.filteredProducts;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // 1. Stock Overview Financial Metrics
            const _StockSummaryCard(),
            const SizedBox(height: AppSpacing.sm),

            // 2. Search & Stock Status Filter Bar
            _buildSearchAndFilters(context),
            const SizedBox(height: AppSpacing.sm),

            // 3. Category & Investor Carousel
            _CategoryAndInvestorCarousel(
              onAddCategory: () => _showAddCategoryDialog(context),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 4. Products List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'products'.tr} (${items.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (controller.selectedCategory.value != null ||
                      controller.selectedFundFilter.value != null ||
                      controller.stockStatusFilter.value != 'all' ||
                      controller.searchQuery.value.isNotEmpty)
                    InkWell(
                      onTap: controller.resetFilters,
                      child: Text(
                        'clearFilter'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),

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
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        controller.searchQuery.value.isNotEmpty ||
                                controller.selectedCategory.value != null ||
                                controller.stockStatusFilter.value != 'all'
                            ? 'কোনো পণ্য খুঁজে পাওয়া যায়নি'
                            : 'noProductsYet'.tr,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _openProductForm(context),
                        icon: const Icon(Icons.add_rounded),
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

            const SizedBox(height: 80), // FAB bottom padding
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'stock_fab',
        tooltip: 'addNewProduct'.tr,
        onPressed: () => _openProductForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('addNewProduct'.tr),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Input
        TextField(
          onChanged: controller.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'searchStockHint'.tr,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => controller.setSearchQuery(''),
                  )
                : const SizedBox.shrink()),
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Quick Stock Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() {
            final current = controller.stockStatusFilter.value;
            final inStock = controller.inStockCount;
            final lowStock = controller.lowStockCount;
            final outStock = controller.outOfStockCount;

            final statusOptions = [
              {'key': 'all', 'label': 'সব (${controller.products.length})', 'icon': Icons.tune_rounded, 'color': theme.colorScheme.primary},
              {'key': 'in_stock', 'label': 'স্টক আছে ($inStock)', 'icon': Icons.check_circle_outline, 'color': Colors.green.shade700},
              {'key': 'low_stock', 'label': 'কম স্টক ($lowStock)', 'icon': Icons.warning_amber_rounded, 'color': Colors.orange.shade800},
              {'key': 'out_of_stock', 'label': 'স্টক নেই ($outStock)', 'icon': Icons.cancel_outlined, 'color': Colors.red.shade700},
            ];

            return Row(
              children: statusOptions.map((opt) {
                final isSelected = current == opt['key'];
                final color = opt['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(
                      opt['icon'] as IconData,
                      size: 13,
                      color: isSelected ? theme.colorScheme.onPrimary : color,
                    ),
                    label: Text(opt['label'] as String),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: color,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onSelected: (_) => controller.setStockStatusFilter(opt['key'] as String),
                  ),
                );
              }).toList(),
            );
          }),
        ),
      ],
    );
  }
}

/// Unified, clean Category & Investor chips horizontal carousel.
class _CategoryAndInvestorCarousel extends GetView<StockController> {
  final VoidCallback onAddCategory;

  const _CategoryAndInvestorCarousel({required this.onAddCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final selectedCat = controller.selectedCategory.value;
      final categories = controller.categories;
      final selectedFund = controller.selectedFundFilter.value;
      final investors = controller.investors;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Category Add Button
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 14, color: theme.colorScheme.primary),
              label: Text(
                'addCategory'.tr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              onPressed: onAddCategory,
            ),
            const SizedBox(width: 6),

            // All Categories Chip
            ChoiceChip(
              label: Text('${'allCategories'.tr} (${controller.products.length})'),
              selected: selectedCat == null,
              showCheckmark: false,
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surface,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: selectedCat == null ? FontWeight.bold : FontWeight.normal,
                color: selectedCat == null
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: selectedCat == null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              onSelected: (_) => controller.selectedCategory.value = null,
            ),
            const SizedBox(width: 6),

            // Category Chips
            for (final cat in categories) ...[
              ChoiceChip(
                label: Text('${cat.name} (${controller.countForCategory(cat.name)})'),
                selected: selectedCat == cat.name,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primaryContainer,
                backgroundColor: theme.colorScheme.surface,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selectedCat == cat.name ? FontWeight.bold : FontWeight.normal,
                  color: selectedCat == cat.name
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: selectedCat == cat.name
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                onSelected: (val) => controller.selectedCategory.value = val ? cat.name : null,
              ),
              const SizedBox(width: 6),
            ],

            // Divider before investors if investors exist
            if (investors.isNotEmpty) ...[
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.colorScheme.outlineVariant,
              ),
              for (final inv in investors) ...[
                ChoiceChip(
                  avatar: Icon(
                    Icons.handshake_outlined,
                    size: 13,
                    color: selectedFund == inv.id ? Colors.orange.shade900 : Colors.orange.shade800,
                  ),
                  label: Text('${inv.name} (${controller.countForFundSource(inv.id)})'),
                  selected: selectedFund == inv.id,
                  showCheckmark: false,
                  selectedColor: Colors.orange.shade100,
                  backgroundColor: theme.colorScheme.surface,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selectedFund == inv.id ? FontWeight.bold : FontWeight.normal,
                    color: selectedFund == inv.id ? Colors.orange.shade900 : Colors.orange.shade800,
                  ),
                  side: BorderSide(
                    color: selectedFund == inv.id ? Colors.orange.shade600 : Colors.orange.shade200,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  onSelected: (val) => controller.selectedFundFilter.value = val ? inv.id : null,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ],
        ),
      );
    });
  }
}

/// Modern Stock Overview Financial Dashboard Card
class _StockSummaryCard extends GetView<StockController> {
  const _StockSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final count = controller.filteredProducts.length;
      final costValue = controller.totalCostValue.format();
      final profitValue = controller.potentialProfit.format();
      final isProfitNegative = controller.potentialProfit.isNegative;

      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatColumn(
                  context,
                  label: 'products'.tr,
                  value: '$count',
                  color: theme.colorScheme.primary,
                  icon: Icons.inventory_2_outlined,
                ),
                Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                _buildStatColumn(
                  context,
                  label: 'stockValue'.tr,
                  value: costValue,
                  color: theme.colorScheme.onSurface,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                _buildStatColumn(
                  context,
                  label: 'potentialProfit'.tr,
                  value: profitValue,
                  color: isProfitNegative ? Colors.red.shade700 : Colors.green.shade700,
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Clean, modern product tile representation
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
    final theme = Theme.of(context);
    final image = controller.primaryImageFor(product.id);
    final imageSource = image == null ? null : controller.imageSourceFor(image);

    final isOutOfStock = product.qty <= 0;
    final isLowStock = product.qty > 0 && product.qty <= 5;
    final stockColor = isOutOfStock
        ? Colors.red.shade700
        : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Product Image or Icon Container
              if (imageSource != null)
                GestureDetector(
                  onTap: () => showFullScreenImageViewer(
                    context,
                    imagePath: imageSource,
                    title: product.name,
                    subtitle: product.category,
                    heroTag: 'stock_card_image_${product.id}',
                  ),
                  child: Hero(
                    tag: 'stock_card_image_${product.id}',
                    child: SafeImage(
                      source: imageSource,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(8),
                      fallbackIcon: Icons.inventory_2_outlined,
                    ),
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Category Tag
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Buy & Sell Prices
                    Row(
                      children: [
                        Text(
                          '${'buy'.tr}: ${product.costPrice.format()}/${product.unit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•  ${'sell'.tr}: ${product.suggestedSellPrice.format()}/${product.sellUnit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Stock Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: stockColor.withValues(alpha: 0.25), width: 0.6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOutOfStock
                                    ? Icons.cancel_outlined
                                    : (isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                                size: 11,
                                color: stockColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isOutOfStock
                                    ? 'outOfStock'.tr
                                    : '${'stockLabel'.tr} ${product.qty.toStringAsFixed(product.qty == product.qty.roundToDouble() ? 0 : 2)} ${product.sellUnit}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: stockColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!product.fundSource.isShop) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200, width: 0.6),
                            ),
                            child: Text(
                              controller.investorName(product.fundSource.investorId!),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.outline),
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
                        const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text('delete'.tr, style: const TextStyle(color: Colors.red)),
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
