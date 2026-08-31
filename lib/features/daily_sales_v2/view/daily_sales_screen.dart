import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../controller/daily_sales_controller.dart';
import 'widgets/daily_sales_list.dart';
import 'widgets/daily_summary_metrics.dart';
import 'widgets/date_navigator.dart';
import 'widgets/sale_form_sheet.dart';

/// Backs the Daily Sales screen — clean date-navigated daily sales history,
/// cash vs. due breakdown for every transaction, daily performance metrics,
/// and a modal bottom-sheet sale entry flow.
class DailySalesScreen extends GetView<DailySalesController> {
  final VoidCallback? onMenuTap;

  const DailySalesScreen({super.key, this.onMenuTap});

  void _showAddSaleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SaleFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'dailySales'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        actions: [
          IconButton(
            tooltip: 'addSale'.tr,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddSaleSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSaleSheet(context),
        icon: const Icon(Icons.add),
        label: Text('addSale'.tr),
      ),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                const SizedBox(height: AppSpacing.md),
                Text('noProductsYet'.tr, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.update(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DateNavigator(controller: controller),
                const SizedBox(height: AppSpacing.sm),
                DailySummaryMetrics(controller: controller),
                const SizedBox(height: AppSpacing.md),
                DailySalesList(
                  controller: controller,
                  onAddSale: () => _showAddSaleSheet(context),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
