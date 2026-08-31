import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/money/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../controller/dashboard_controller.dart';

/// Modal bottom sheet showing comprehensive breakdown of all shop liabilities & payables:
/// 1. Investor capital & profit repayments (total remaining + daily target)
/// 2. Shop rent obligations (monthly rent, paid so far, remaining this month, daily share)
/// 3. Daily combined target run-rate recommendations
class PayableObligationsSheet extends StatelessWidget {
  final DashboardController controller;

  const PayableObligationsSheet({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = controller.totals;
    final investorDetails = controller.investorObligationDetails;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.handshake_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'payableObligationsTitle'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'payableObligationsSubtitle'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Summary Cards (Total Payable & Daily Run-rate) ─────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade700,
                            Colors.deepPurple.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'totalPayable'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totals.totalPayableObligations.format(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade700,
                            Colors.teal.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'combinedDailyTarget'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totals.dailyTotalObligation.format()} / ${'day'.tr}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 1: Investor Obligations ─────────────────────────────
              _buildSectionCard(
                context,
                title: 'investorObligations'.tr,
                icon: Icons.groups_outlined,
                color: Colors.deepPurple,
                totalAmount: totals.totalInvestorRemaining.format(),
                dailyAmount: totals.dailyInvestorObligation.isPositive
                    ? '${totals.dailyInvestorObligation.format()} / ${'day'.tr}'
                    : null,
                actionLabel: 'manageInvestors'.tr,
                onAction: () {
                  Navigator.of(context).pop();
                  Get.toNamed(AppRoutes.investorV2);
                },
                children: [
                  if (investorDetails.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'noInvestorObligations'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    for (final inv in investorDetails)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  Colors.deepPurple.withValues(alpha: 0.1),
                              child: Text(
                                inv.investor.name.isNotEmpty
                                    ? inv.investor.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.investor.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (inv.termDays != null)
                                    Text(
                                      '${inv.termDays} ${'daysLater'.tr} • ${'dailyPayback'.tr}: ${inv.dailyObligation.format()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              inv.remainingBalance.format(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Section 2: Shop Rent & Recurring Overhead ────────────────────
              _buildSectionCard(
                context,
                title: 'shopRentObligations'.tr,
                icon: Icons.storefront_outlined,
                color: Colors.indigo,
                totalAmount: totals.rentRemainingThisMonth.isPositive
                    ? '${totals.rentRemainingThisMonth.format()} (${'remaining'.tr})'
                    : (totals.monthlyShopRent.isPositive
                        ? 'paidFull'.tr
                        : 'notConfigured'.tr),
                dailyAmount: totals.dailyRentObligation.isPositive
                    ? '${totals.dailyRentObligation.format()} / ${'day'.tr}'
                    : null,
                actionLabel: totals.rentRemainingThisMonth.isPositive || totals.monthlyShopRent.isPositive
                    ? 'payMonthlyRent'.tr
                    : 'editRentSettings'.tr,
                onAction: () {
                  if (totals.monthlyShopRent.isZero) {
                    Navigator.of(context).pop();
                    Get.toNamed(AppRoutes.pricingSettingsV2);
                  } else {
                    _showPayRentDialog(context);
                  }
                },
                secondaryActionLabel: totals.monthlyShopRent.isPositive ? 'editRentSettings'.tr : null,
                onSecondaryAction: totals.monthlyShopRent.isPositive
                    ? () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.pricingSettingsV2);
                      }
                    : null,
                children: [
                  if (totals.monthlyShopRent.isPositive && totals.rentRemainingThisMonth.isZero)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'currentMonthRentPaid'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _rentDetailRow(
                    'monthlyConfiguredRent'.tr,
                    totals.monthlyShopRent.format(),
                  ),
                  _rentDetailRow(
                    'rentPaidThisMonth'.tr,
                    totals.rentPaidThisMonth.format(),
                    color: Colors.green.shade700,
                  ),
                  _rentDetailRow(
                    'rentRemainingThisMonth'.tr,
                    totals.rentRemainingThisMonth.format(),
                    color: totals.rentRemainingThisMonth.isPositive
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    isBold: true,
                  ),
                  _rentDetailRow(
                    'dailyRentShare'.tr,
                    '${totals.dailyRentObligation.format()} / ${'day'.tr}',
                    color: Colors.indigo.shade700,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Section 3: Daily Target Tip ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'dailyObligationTip'.trParams({
                          'amount': totals.dailyTotalObligation.format(),
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String totalAmount,
    required String actionLabel,
    required VoidCallback onAction,
    required List<Widget> children,
    String? dailyAmount,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    if (dailyAmount != null)
                      Text(
                        dailyAmount,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ...children,
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                  TextButton(
                    onPressed: onSecondaryAction,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      secondaryActionLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rentDetailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPayRentDialog(BuildContext context) {
    final totals = controller.totals;
    final defaultAmount = totals.rentRemainingThisMonth.isPositive
        ? totals.rentRemainingThisMonth
        : (totals.monthlyShopRent.isPositive
            ? totals.monthlyShopRent
            : Money.zero());

    final amountCtrl = TextEditingController(
      text: defaultAmount.isPositive ? defaultAmount.format(showSymbol: false) : '',
    );
    final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());
    final noteCtrl = TextEditingController(text: 'দোকান ভাড়া - $currentMonthName');
    PaymentMethod selectedMethod = PaymentMethod.cash;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'payRentTitle'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                Text(
                  'payRentSubtitle'.tr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'enterRentAmount'.tr,
                    prefixText: '৳ ',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'paymentMethod'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SegmentedButton<PaymentMethod>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: PaymentMethod.cash, label: Text('cash'.tr)),
                    ButtonSegment(value: PaymentMethod.mobileBanking, label: Text('mobile'.tr)),
                    ButtonSegment(value: PaymentMethod.bankTransfer, label: Text('bank'.tr)),
                  ],
                  selected: {selectedMethod},
                  onSelectionChanged: (s) => setModalState(() => selectedMethod = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'rentNote'.tr,
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    final entered = _parseMoneyOrNull(amountCtrl.text);
                    if (entered == null || !entered.isPositive) return;
                    final ok = await controller.payRent(
                      amount: entered,
                      paymentMethod: selectedMethod,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    );
                    if (ok && dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('rentPaymentSuccess'.tr)),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('payMonthlyRent'.tr),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
