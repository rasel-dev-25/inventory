import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design/tokens.dart';
import '../../controller/daily_sales_controller.dart';

/// Metric summary cards for total sales, cash received, due sales, and net profit for the selected date.
class DailySummaryMetrics extends StatelessWidget {
  final DailySalesController controller;

  const DailySummaryMetrics({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalSales = controller.totalSalesAmount;
      final totalCash = controller.totalCashAmount;
      final totalDue = controller.totalDueAmount;
      final totalProfit = controller.totalProfitAmount;
      final totalUnits = controller.totalUnitsSold;
      final txCount = controller.totalTransactionsCount;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  title: 'totalSales'.tr,
                  value: totalSales.format(),
                  subtitle:
                      '$txCount (${totalUnits.toStringAsFixed(totalUnits == totalUnits.roundToDouble() ? 0 : 1)} ${'unitPcs'.tr})',
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricCard(
                  context,
                  title: 'totalProfit'.tr,
                  value: totalProfit.format(),
                  subtitle: totalProfit.isNegative ? 'Loss' : 'Net Profit',
                  icon: Icons.trending_up,
                  color:
                      totalProfit.isNegative ? Colors.red : Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  title: 'cashReceived'.tr,
                  value: totalCash.format(),
                  subtitle: 'Cash collected',
                  icon: Icons.payments_outlined,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricCard(
                  context,
                  title: 'dueSales'.tr,
                  value: totalDue.format(),
                  subtitle: 'Uncollected debt',
                  icon: Icons.credit_card_outlined,
                  color: totalDue.isPositive
                      ? Colors.orange.shade800
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
