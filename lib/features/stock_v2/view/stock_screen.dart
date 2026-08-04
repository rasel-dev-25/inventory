import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/entities/product.dart';
import '../controller/stock_controller.dart';

/// The v2 Stock screen — category/investor filters, per-filter cost/
/// sale-value/profit totals, and a top-sellers/slow-movers view, per
/// `notes/business_logic.md` §খ. See `CatalogScreen`'s doc comment for why
/// this reads the v2 database only, separate from v1's Inventory tab.
class StockScreen extends GetView<StockController> {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'stockAndAssets'.tr} (v2)')),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return Center(child: Text('noProductsYet'.tr));
        }
        final items = controller.filteredProducts;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _FilterRow(),
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(),
            const SizedBox(height: AppSpacing.lg),
            _MovementSection(
              title: 'topSellers'.tr,
              products: controller.topSellers,
              quantityLabel: (p) =>
                  '${'qty'.tr}: ${controller.soldQtyByProduct[p.id]?.toStringAsFixed(0) ?? '0'}',
            ),
            const SizedBox(height: AppSpacing.lg),
            _MovementSection(
              title: 'slowMovers'.tr,
              products: controller.slowMovers,
              quantityLabel: (p) =>
                  '${'stockLabel'.tr}${p.qty.toStringAsFixed(0)}',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${'products'.tr} (${items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final product in items) _ProductRow(product: product),
          ],
        );
      }),
    );
  }
}

class _FilterRow extends GetView<StockController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: controller.selectedCategory.value,
              decoration: InputDecoration(
                labelText: 'filterByCategory'.tr,
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('allCategories'.tr)),
                for (final c in controller.categories)
                  DropdownMenuItem(value: c.name, child: Text(c.name)),
              ],
              onChanged: (v) => controller.selectedCategory.value = v,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: controller.selectedFundFilter.value,
              decoration: InputDecoration(
                labelText: 'filterByInvestor'.tr,
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('allInvestors'.tr)),
                DropdownMenuItem(
                  value: shopFundFilterValue,
                  child: Text('shop'.tr),
                ),
                for (final i in controller.investors)
                  DropdownMenuItem(value: i.id, child: Text(i.name)),
              ],
              onChanged: (v) => controller.selectedFundFilter.value = v,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends GetView<StockController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(
                context,
                'totalCostValue'.tr,
                controller.totalCostValue.format(),
              ),
              _stat(
                context,
                'potentialSaleValue'.tr,
                controller.potentialSaleValue.format(),
              ),
              _stat(
                context,
                'potentialProfit'.tr,
                controller.potentialProfit.format(),
                color: controller.potentialProfit.isNegative
                    ? Theme.of(context).colorScheme.error
                    : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MovementSection extends StatelessWidget {
  final String title;
  final List<Product> products;
  final String Function(Product) quantityLabel;

  const _MovementSection({
    required this.title,
    required this.products,
    required this.quantityLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final product in products)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(product.name),
            subtitle: Text(product.category),
            trailing: Text(quantityLabel(product)),
          ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text(
        '${product.category} · ${'costLabel'.tr}: ${product.costPrice.format()}'
        ' · ${'sellPriceLabel'.tr}: ${product.suggestedSellPrice.format()}',
      ),
      trailing: Text(
        product.qty.toStringAsFixed(
          product.qty == product.qty.roundToDouble() ? 0 : 2,
        ),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
