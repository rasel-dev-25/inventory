import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../controller/dashboard_controller.dart';

/// The v2 Dashboard screen — Day/All-time toggle over the totals
/// `notes/business_logic.md` §ঝ specifies, backed by
/// [DashboardController.totals] → `computeDashboardTotals`. See
/// `CatalogScreen`'s doc comment for why this reads the v2 database only,
/// separate from v1's Dashboard tab.
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'overview'.tr} (v2)')),
      body: Obx(() {
        final totals = controller.totals;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilterChip(
                label: Text(
                  controller.isDayView.value ? 'dayView'.tr : 'allTimeView'.tr,
                ),
                selected: controller.isDayView.value,
                onSelected: (_) => controller.toggleView(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DashboardCard(
              label: 'totalCash'.tr,
              value: totals.totalCash,
              highlightNegative: true,
            ),
            _DashboardCard(label: 'stockValue'.tr, value: totals.stockValue),
            _DashboardCard(
              label: 'totalSale'.tr,
              value: totals.totalSaleRevenue,
            ),
            _DashboardCard(
              label: 'totalPurchase'.tr,
              value: totals.totalPurchaseCashOut,
            ),
            _DashboardCard(
              label: 'netProfit'.tr,
              value: totals.netProfit,
              highlightNegative: true,
              footnote: 'netProfitFootnote'.tr,
            ),
          ],
        );
      }),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String label;
  final Money value;
  final bool highlightNegative;
  final String? footnote;

  const _DashboardCard({
    required this.label,
    required this.value,
    this.highlightNegative = false,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = highlightNegative && value.isNegative;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value.format(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNegative ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            if (footnote != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  footnote!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
