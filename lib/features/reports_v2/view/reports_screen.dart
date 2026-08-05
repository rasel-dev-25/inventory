import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../controller/reports_controller.dart';

/// The v2 Reports screen — a period-selectable accounting summary
/// (`ReportsController.totals`, via the exact same
/// `computeDashboardTotals` the Dashboard uses) plus per-investor
/// profit-share owed and a "what sold" breakdown, both scoped to
/// whichever period is selected. See `CatalogScreen`'s doc comment for
/// why this reads the v2 database only.
class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('reportsTitle'.tr)),
      body: Obx(() {
        final totals = controller.totals;
        final investorShares = controller.investorShares;
        final productSales = controller.productSales;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _PeriodSelector(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'reportPnlSectionTitle'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ReportCard(label: 'totalSale'.tr, value: totals.totalSaleRevenue),
            _ReportCard(
              label: 'totalPurchase'.tr,
              value: totals.totalPurchaseCashOut,
            ),
            _ReportCard(
              label: 'totalExpense'.tr,
              value: controller.totalExpenses,
            ),
            _ReportCard(
              label: 'netProfit'.tr,
              value: totals.netProfit,
              highlightNegative: true,
              emphasize: true,
            ),
            _ReportCard(
              label: 'totalCash'.tr,
              value: totals.totalCash,
              highlightNegative: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'investorShareSectionTitle'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (investorShares.isEmpty)
              Text('noInvestors'.tr)
            else
              for (final row in investorShares)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.investor.name),
                  subtitle: Text(
                    '${'grossProfit'.tr}: ${row.grossProfit.format()}',
                  ),
                  trailing: Text(
                    row.profitShare.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'productSalesSectionTitle'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (productSales.isEmpty)
              Text('noSalesThisPeriod'.tr)
            else
              for (final row in productSales)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_productName(row.productId)),
                  subtitle: Text('${'qtySold'.tr}: ${row.qtySold}'),
                  trailing: Text(
                    row.revenue.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
          ],
        );
      }),
    );
  }

  String _productName(String productId) {
    final product = controller.products
        .where((p) => p.id == productId)
        .firstOrNull;
    return product?.name ?? productId;
  }
}

class _PeriodSelector extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ReportPeriod>(
            segments: [
              ButtonSegment(value: ReportPeriod.today, label: Text('today'.tr)),
              ButtonSegment(
                value: ReportPeriod.thisWeek,
                label: Text('thisWeek'.tr),
              ),
              ButtonSegment(
                value: ReportPeriod.thisMonth,
                label: Text('thisMonth'.tr),
              ),
              ButtonSegment(
                value: ReportPeriod.custom,
                label: Text('customRange'.tr),
              ),
            ],
            selected: {controller.period.value},
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == ReportPeriod.custom) {
                _pickCustomRange(context);
              } else {
                controller.selectPeriod(value);
              }
            },
          ),
          if (controller.period.value == ReportPeriod.custom &&
              controller.customRange.value != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => _pickCustomRange(context),
                child: Text(
                  '${_formatDate(controller.customRange.value!.start)} — '
                  '${_formatDate(controller.customRange.value!.end.subtract(const Duration(days: 1)))}',
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );
    if (picked == null) return;
    final start = DateTime.utc(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    // The picker's end date is inclusive; DateRange's end is exclusive, so
    // this must be the day *after* the picked end date to include it.
    final end = DateTime.utc(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    ).add(const Duration(days: 1));
    controller.setCustomRange(start, end);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ReportCard extends StatelessWidget {
  final String label;
  final Money value;
  final bool highlightNegative;
  final bool emphasize;

  const _ReportCard({
    required this.label,
    required this.value,
    this.highlightNegative = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = highlightNegative && value.isNegative;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value.format(),
              style:
                  (emphasize
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isNegative
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
