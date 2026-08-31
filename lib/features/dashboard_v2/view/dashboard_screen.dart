import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/notification_bell_action.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/services/dashboard_calculator.dart';
import '../../reminders_v2/controller/reminder_controller.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/dashboard_controller.dart';
import 'widgets/payable_obligations_sheet.dart';

/// The Dashboard screen — Day/All-time toggle over the totals
/// `notes/business_logic.md` §ঝ specifies, backed by
/// [DashboardController.totals] → `computeDashboardTotals`. One of the 6
/// screens `ShellScreen` embeds directly.
class DashboardScreen extends GetView<DashboardController> {
  final VoidCallback? onMenuTap;

  const DashboardScreen({super.key, this.onMenuTap});

  void _navigateToTab(int tabIndex) {
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().switchTab(tabIndex);
    }
  }

  void _showPayableObligations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayableObligationsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReminderRegistered = Get.isRegistered<ReminderController>();
    final reminderController =
        isReminderRegistered ? Get.find<ReminderController>() : null;

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'overview'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        actions: const [
          NotificationBellAction(),
          SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final totals = controller.totals;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // 0. Smart Reminder & Low Stock Alert Banner
            if (reminderController != null)
              Obx(() {
                final hasActive = reminderController.hasAnyActiveAlerts;
                final allResolved = reminderController.allResolvedToday;
                final summary = reminderController.activeAlertSummaryText;
                final theme = Theme.of(context);

                if (!hasActive && !allResolved) return const SizedBox.shrink();

                if (allResolved) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '✓ সকল অ্যালার্ট চেক করা হয়েছে (সব ঠিক আছে)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                reminderController.unresolveAll(),
                            child: Text(
                              'পুনরায় চালু',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final overdue = reminderController.activeOverdueCount > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: overdue
                        ? theme.colorScheme.errorContainer.withValues(alpha: 0.85)
                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: overdue
                          ? theme.colorScheme.error.withValues(alpha: 0.4)
                          : theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          overdue
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                          size: 22,
                          color: overdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.toNamed(AppRoutes.remindersV2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    summary,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: overdue
                                          ? theme.colorScheme.onErrorContainer
                                          : theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'দেখুন',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: overdue
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: overdue
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ── Tick / Resolve Button ──
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            reminderController.markAllResolved();
                            Get.snackbar(
                              'অ্যালার্ট চেক করা হয়েছে',
                              'নোটিফিকেশনগুলো সম্পন্ন হিসেবে চিহ্নিত করা হয়েছে।',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Colors.green.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'টিক দিন',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: Text(
                      controller.isDayView.value
                          ? 'dayView'.tr
                          : 'allTimeView'.tr,
                    ),
                    selected: controller.isDayView.value,
                    onSelected: (_) => controller.toggleView(),
                  ),
                  IconButton(
                    tooltip: 'date'.tr,
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDate:
                            controller.selectedDay.value ?? DateTime.now(),
                      );
                      if (picked != null) controller.selectDay(picked);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 1. Total Cash (মোট ক্যাশ)
            _DashboardCard(
              label: 'totalCash'.tr,
              value: totals.totalCash,
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.teal,
              highlightNegative: true,
            ),

            // 2. Stock Value (স্টক মূল্য -> Stock Tab)
            _DashboardCard(
              label: 'stockValue'.tr,
              value: totals.stockValue,
              icon: Icons.inventory_2_outlined,
              color: Colors.indigo,
              onTap: () => _navigateToTab(2),
            ),

            // 3. Total Sale (মোট বিক্রি -> Daily Sales Tab)
            _DashboardCard(
              label: 'totalSale'.tr,
              value: totals.totalSaleRevenue,
              icon: Icons.point_of_sale_outlined,
              color: Colors.green.shade700,
              onTap: () => _navigateToTab(1),
            ),

            // 4. Total Purchase (মোট কেনা -> Purchase Entry Tab)
            _DashboardCard(
              label: 'totalPurchase'.tr,
              value: totals.totalPurchaseCashOut,
              icon: Icons.shopping_bag_outlined,
              color: Colors.blueGrey,
              onTap: () => _navigateToTab(5),
            ),

            // 5. Total Due (মোট বাকি -> Dues Tab)
            _DashboardCard(
              label: 'totalDue'.tr,
              value: totals.totalDue,
              icon: Icons.receipt_long_outlined,
              color: Colors.orange.shade800,
              onTap: () => _navigateToTab(3),
            ),

            // 6. Total Expense (মোট খরচ -> Expense Screen)
            _DashboardCard(
              label: 'totalExpense'.tr,
              value: totals.totalExpense,
              icon: Icons.money_off_outlined,
              color: Colors.redAccent.shade700,
              onTap: () => Get.toNamed(AppRoutes.expenseV2),
            ),

            // 7. To Give Away / Obligations (পরিশোধের জন্য -> Investor & Rent Obligations Sheet)
            _DashboardCard(
              label: 'toGiveAway'.tr,
              value: totals.totalPayableObligations.isPositive
                  ? totals.totalPayableObligations
                  : totals.totalInvestorRemaining,
              subtitle: _buildObligationsSubtitle(controller.isDayView.value, totals),
              icon: Icons.handshake_outlined,
              color: Colors.deepPurple,
              onTap: () => _showPayableObligations(context),
            ),

            // 8. Net Profit / Net Loss (নেট লাভ / ক্ষতি)
            _DashboardCard(
              label: 'netProfit'.tr,
              value: totals.netProfit,
              icon: totals.netProfit.isNegative
                  ? Icons.trending_down
                  : Icons.trending_up,
              color: totals.netProfit.isNegative
                  ? Colors.red
                  : Colors.green.shade700,
              highlightNegative: true,
              negativeLabel: 'netLoss'.tr,
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        tooltip: 'quickCaptures'.tr,
        onPressed: () => Get.toNamed(AppRoutes.quickCaptureV2),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String label;
  final Money value;
  final IconData icon;
  final Color color;
  final bool highlightNegative;
  final String? negativeLabel;
  final String? subtitle;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlightNegative = false,
    this.negativeLabel,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = highlightNegative && value.isNegative;
    final displayColor =
        isNegative ? Theme.of(context).colorScheme.error : color;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: displayColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNegative && negativeLabel != null
                          ? negativeLabel!
                          : label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.format(),
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isNegative
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: displayColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _buildObligationsSubtitle(bool isDayView, DashboardTotals totals) {
  if (isDayView) {
    if (totals.dailyTotalObligation.isPositive) {
      if (totals.dailyInvestorObligation.isPositive &&
          totals.dailyRentObligation.isPositive) {
        return '${'dailyPayback'.tr}: ${totals.dailyTotalObligation.format()} (${'investor'.tr}: ${totals.dailyInvestorObligation.format()} + ${'rent'.tr}: ${totals.dailyRentObligation.format()})';
      } else if (totals.dailyInvestorObligation.isPositive) {
        return '${'dailyPayback'.tr}: ${totals.dailyInvestorObligation.format()}';
      } else {
        return '${'dailyRentShare'.tr}: ${totals.dailyRentObligation.format()}';
      }
    }
  } else {
    if (totals.monthlyShopRent.isPositive &&
        totals.totalInvestorRemaining.isPositive) {
      return '${'investor'.tr}: ${totals.totalInvestorRemaining.format()} • ${'rentRemaining'.tr}: ${totals.rentRemainingThisMonth.format()}';
    } else if (totals.monthlyShopRent.isPositive) {
      return '${'rentRemaining'.tr}: ${totals.rentRemainingThisMonth.format()} (${'monthly'.tr}: ${totals.monthlyShopRent.format()})';
    }
  }
  return null;
}
