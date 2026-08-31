import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
        final isDay = controller.isDayView.value;
        final selectedDate = controller.selectedDay.value ?? DateTime.now();

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // 0. Smart Reminder & Low Stock Alert Banner
            if (reminderController != null)
              _buildSmartAlertBanner(context, reminderController),

            // 1. Date & View Segmented Toggle Bar
            _buildDateAndFilterBar(context, isDay, selectedDate),
            const SizedBox(height: AppSpacing.sm),

            // 2. Executive Hero Financial Health Card (Cash & Profit/Loss)
            _buildExecutiveFinancialCard(context, totals),
            const SizedBox(height: AppSpacing.md),

            // 3. Quick Business Action Shortcuts
            _buildQuickActions(context),
            const SizedBox(height: AppSpacing.md),

            // 4. Core Business Operations (2x2 Grid)
            _buildSectionHeader(context, title: 'businessOperations'.tr),
            const SizedBox(height: 6),
            _buildOperationsGrid(context, totals),
            const SizedBox(height: AppSpacing.md),

            // 5. Liabilities & Expenses Section
            _buildSectionHeader(context, title: 'liabilitiesAndExpenses'.tr),
            const SizedBox(height: 6),
            _buildObligationsAndExpenses(context, totals),

            const SizedBox(height: 80), // Bottom padding for FAB
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        tooltip: 'quickCaptures'.tr,
        onPressed: () => Get.toNamed(AppRoutes.quickCaptureV2),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  // ── 0. Smart Reminder & Alert Banner ──────────────────────────────────────
  Widget _buildSmartAlertBanner(
    BuildContext context,
    ReminderController reminderController,
  ) {
    return Obx(() {
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
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.green.shade200, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ সকল অ্যালার্ট চেক করা হয়েছে',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => reminderController.unresolveAll(),
                  child: Text(
                    'পুনরায় চালু',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.9)
              : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: overdue
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : Colors.amber.shade300,
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                overdue ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                size: 20,
                color: overdue ? theme.colorScheme.error : Colors.amber.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.remindersV2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: overdue
                                ? theme.colorScheme.onErrorContainer
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'দেখুন',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: overdue ? theme.colorScheme.error : Colors.amber.shade900,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: overdue ? theme.colorScheme.error : Colors.amber.shade900,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
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
                      size: 14,
                      color: Colors.green.shade800,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ঠিক দিন',
                      style: TextStyle(
                        fontSize: 11.5,
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
    });
  }

  // ── 1. Date & View Segmented Toggle Bar ───────────────────────────────────
  Widget _buildDateAndFilterBar(
    BuildContext context,
    bool isDay,
    DateTime selectedDate,
  ) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('d MMM yyyy').format(selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Segmented View Toggle
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewPill(
                context,
                title: 'dayView'.tr,
                selected: isDay,
                onTap: () {
                  if (!isDay) controller.toggleView();
                },
              ),
              _buildViewPill(
                context,
                title: 'allTimeView'.tr,
                selected: !isDay,
                onTap: () {
                  if (isDay) controller.toggleView();
                },
              ),
            ],
          ),
        ),

        // Date Picker Button
        if (isDay)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDate: controller.selectedDay.value ?? DateTime.now(),
              );
              if (picked != null) controller.selectDay(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildViewPill(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── 2. Executive Hero Financial Health Card (Total Cash & Net Profit) ─────
  Widget _buildExecutiveFinancialCard(BuildContext context, DashboardTotals totals) {
    final theme = Theme.of(context);
    final isCashNegative = totals.totalCash.isNegative;
    final isProfitNegative = totals.netProfit.isNegative;

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
      child: Row(
        children: [
          // Total Cash
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (isCashNegative ? Colors.red : Colors.teal).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: isCashNegative ? Colors.red.shade700 : Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'totalCash'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  totals.totalCash.format(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCashNegative ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Center Divider
          Container(
            width: 1,
            height: 44,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.md),

          // Net Profit / Net Loss
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (isProfitNegative ? Colors.red : Colors.green).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isProfitNegative ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        size: 14,
                        color: isProfitNegative ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isProfitNegative ? 'netLoss'.tr : 'netProfit'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  totals.netProfit.format(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isProfitNegative ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Quick Business Action Shortcuts ────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionPill(
            context,
            icon: Icons.point_of_sale_rounded,
            label: 'newSaleAction'.tr,
            color: Colors.green.shade700,
            bgColor: Colors.green.shade50,
            onTap: () => _navigateToTab(1),
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context,
            icon: Icons.add_shopping_cart_rounded,
            label: 'newPurchaseAction'.tr,
            color: Colors.blue.shade700,
            bgColor: Colors.blue.shade50,
            onTap: () => _navigateToTab(5),
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context,
            icon: Icons.receipt_long_rounded,
            label: 'collectDueAction'.tr,
            color: Colors.orange.shade800,
            bgColor: Colors.orange.shade50,
            onTap: () => _navigateToTab(3),
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context,
            icon: Icons.money_off_rounded,
            label: 'addExpenseAction'.tr,
            color: Colors.red.shade700,
            bgColor: Colors.red.shade50,
            onTap: () => Get.toNamed(AppRoutes.expenseV2),
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context,
            icon: Icons.menu_book_rounded,
            label: 'rent'.tr,
            color: Colors.teal.shade700,
            bgColor: Colors.teal.shade50,
            onTap: () => Get.toNamed(AppRoutes.rentV2),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Core Business Operations (2x2 Grid) ────────────────────────────────
  Widget _buildOperationsGrid(BuildContext context, DashboardTotals totals) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ModernDashboardCard(
                label: 'totalSale'.tr,
                value: totals.totalSaleRevenue,
                icon: Icons.point_of_sale_outlined,
                color: Colors.green.shade700,
                onTap: () => _navigateToTab(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ModernDashboardCard(
                label: 'totalPurchase'.tr,
                value: totals.totalPurchaseCashOut,
                icon: Icons.shopping_bag_outlined,
                color: Colors.blue.shade700,
                onTap: () => _navigateToTab(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ModernDashboardCard(
                label: 'stockValue'.tr,
                value: totals.stockValue,
                icon: Icons.inventory_2_outlined,
                color: Colors.indigo.shade700,
                onTap: () => _navigateToTab(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ModernDashboardCard(
                label: 'totalDue'.tr,
                value: totals.totalDue,
                icon: Icons.receipt_long_outlined,
                color: Colors.orange.shade800,
                onTap: () => _navigateToTab(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 5. Liabilities & Expenses Section ─────────────────────────────────────
  Widget _buildObligationsAndExpenses(
    BuildContext context,
    DashboardTotals totals,
  ) {
    return Column(
      children: [
        // Total Expense Card
        _ModernDashboardCard(
          label: 'totalExpense'.tr,
          value: totals.totalExpense,
          icon: Icons.money_off_outlined,
          color: Colors.red.shade700,
          onTap: () => Get.toNamed(AppRoutes.expenseV2),
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Payable Obligations (To Give Away)
        _ModernDashboardCard(
          label: 'toGiveAway'.tr,
          value: totals.totalPayableObligations.isPositive
              ? totals.totalPayableObligations
              : totals.totalInvestorRemaining,
          subtitle: _buildObligationsSubtitle(controller.isDayView.value, totals),
          icon: Icons.handshake_outlined,
          color: Colors.deepPurple.shade700,
          onTap: () => _showPayableObligations(context),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Sleek modern card widget for dashboard metrics
class _ModernDashboardCard extends StatelessWidget {
  final String label;
  final Money value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isFullWidth;

  const _ModernDashboardCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.format(),
                      style: TextStyle(
                        fontSize: isFullWidth ? 16 : 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.outlineVariant,
                  size: 18,
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
