import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../controller/dashboard_controller.dart';

/// The Dashboard screen — Day/All-time toggle over the totals
/// `notes/business_logic.md` §ঝ specifies, backed by
/// [DashboardController.totals] → `computeDashboardTotals`. One of the 5
/// screens `ShellScreen` embeds directly — see that class's own doc
/// comment for why [onMenuTap] exists: this screen builds its own
/// `Scaffold`/`AppBar`, so the outer shell's drawer needs an explicit way
/// in, the same convention v1's shell screens used.
class DashboardScreen extends GetView<DashboardController> {
  final VoidCallback? onMenuTap;

  const DashboardScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('overview'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
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

  const _DashboardCard({
    required this.label,
    required this.value,
    this.highlightNegative = false,
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
          ],
        ),
      ),
    );
  }
}
