import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/investor_repayment.dart';
import '../../../domain/entities/legacy_settlement.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/investor_metrics.dart';
import '../controller/investor_controller.dart';
import 'investor_form_sheet.dart';

/// Full-screen Investor Detail View providing:
/// 1. Investor profile and arrangement parameters.
/// 2. Old Ledger (খাতার হিসাব) installment repayment tracking and history.
/// 3. New Business real-time metrics (Cash Received, Bought, Sold, Profit, Stock Value, Profit Split).
/// 4. Add Investment (+ মূলধন গ্রহণ) and Repayment (- মূলধন/মুনাফা পরিশোধ) actions.
/// 5. Transactions history and list of products currently funded by this investor.
class InvestorDetailScreen extends GetView<InvestorController> {
  final String investorId;

  const InvestorDetailScreen({
    required this.investorId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final investor = controller.investorById(investorId);
      if (investor == null) {
        return Scaffold(
          appBar: AppBar(title: Text('investorDetail'.tr)),
          body: Center(child: Text('noInvestors'.tr)),
        );
      }

      final metrics = controller.metricsFor(investor);
      final settlement = controller.settlementFor(investor.id);
      final repayments = controller.repaymentsFor(investor.id);
      final products = controller.productsForInvestor(investor.id);

      return Scaffold(
        appBar: AppBar(
          title: Text(investor.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'editInvestor'.tr,
              onPressed: () => _openEditForm(context, investor),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Profile / Arrangement Summary Card ─────────────────────
              _buildProfileCard(context, investor),
              const SizedBox(height: AppSpacing.md),

              // ── 2. Old Ledger Settlement Card (if on file) ────────────────
              if (settlement != null) ...[
                _buildOldLedgerCard(context, settlement),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── 3. New Business Activity & Live Metrics Card ──────────────
              _buildNewActivityCard(context, investor, metrics, repayments),
              const SizedBox(height: AppSpacing.md),

              // ── 4. Products Funded by Investor ────────────────────────────
              _buildFundedProductsCard(context, products),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openEditForm(BuildContext context, Investor investor) async {
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvestorFormSheet(existing: investor),
    );
    if (result == null) return;

    await controller.updateInvestor(
      investor,
      name: result.name,
      contact: result.contact,
      investmentType: result.investmentType,
      profitSharePercent: result.profitSharePercent,
      capitalReturnTermDays: result.capitalReturnTermDays,
      profitPayoutCycle: result.profitPayoutCycle,
      initialCashInvestment: result.initialCashInvestment,
      notes: result.notes,
    );
  }

  // ── Profile / Arrangement Card ───────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, Investor investor) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(
                    investor.name.isNotEmpty ? investor.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investor.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (investor.contact != null && investor.contact!.isNotEmpty)
                        Text(
                          investor.contact!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                _badge(
                  _investmentTypeLabel(investor.investmentType),
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primary,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoColumn('profitShare'.tr, '${investor.profitSharePercent}%'),
                _infoColumn('profitPayoutCycle'.tr, _payoutCycleLabel(investor.profitPayoutCycle)),
                if (investor.capitalReturnTermDays != null)
                  _infoColumn('capitalReturnTermDays'.tr, '${investor.capitalReturnTermDays} ${'daysLater'.tr}'),
              ],
            ),
            if (investor.notes != null && investor.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${'notes'.tr}: ${investor.notes!}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Old Ledger (পুরনো খাতা) Card ──────────────────────────────────────────
  Widget _buildOldLedgerCard(BuildContext context, LegacySettlement settlement) {
    final theme = Theme.of(context);
    final isPending = settlement.status == LegacySettlementStatus.pending;

    final noteLines = (settlement.notes ?? '')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Card(
      elevation: 0,
      color: isPending
          ? Colors.amber.withValues(alpha: 0.08)
          : Colors.green.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isPending
              ? Colors.amber.shade600.withValues(alpha: 0.5)
              : Colors.green.shade600.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 20,
                      color: isPending ? Colors.amber.shade800 : Colors.green.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'oldLedgerAccount'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPending ? Colors.amber.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                _badge(
                  isPending ? 'legacySettlementPending'.tr : 'legacySettlementSettled'.tr,
                  isPending ? Colors.amber.shade100 : Colors.green.shade100,
                  isPending ? Colors.amber.shade900 : Colors.green.shade900,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _detailRow('totalHistoricalInvestment'.tr, settlement.totalHistoricalInvestment.format()),
            _detailRow('totalAlreadyReturned'.tr, settlement.totalAlreadyReturned.format(), color: Colors.green),
            _detailRow(
              'netSettlementAmount'.tr,
              settlement.netSettlementAmount.format(),
              bold: true,
              color: isPending ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text('payInstallment'.tr),
                      onPressed: () => _showPayOldLedgerDialog(context, settlement),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => _confirmMarkSettled(context, settlement),
                    child: Text('markSettled'.tr),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (noteLines.isNotEmpty) ...[
              Text(
                'oldLedgerPaymentHistory'.tr,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    for (final line in noteLines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── New Business & Live Activity Card ────────────────────────────────────
  Widget _buildNewActivityCard(
    BuildContext context,
    Investor investor,
    InvestorMetrics metrics,
    List<InvestorRepayment> repayments,
  ) {
    final theme = Theme.of(context);

    // Filter investment addition log entries from investor notes
    final investmentLogs = (investor.notes ?? '')
        .split('\n')
        .where((line) => line.trim().startsWith('+'))
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'newBusinessTransactions'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 4 Stats Grid (Bought / Sold / Profit / Stock)
            Row(
              children: [
                _statBox('bought'.tr, metrics.totalPurchasedCash.format(), Colors.blue),
                const SizedBox(width: 6),
                _statBox('sold'.tr, metrics.totalSoldRevenue.format(), Colors.green),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _statBox('profit'.tr, metrics.totalGrossProfit.format(), Colors.orange),
                const SizedBox(width: 6),
                _statBox('currentStockValue'.tr, metrics.currentStockValue.format(), Colors.purple),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Profit Split Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'profitSplit'.tr}:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '${'investorShare'.tr} (${investor.profitSharePercent}%): ${metrics.profitShare.format()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '| ${'shopShare'.tr}: ${(metrics.totalGrossProfit - metrics.profitShare).format()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Detailed Financial Rows
            if (!investor.initialCashInvestment.isZero)
              _detailRow('cashInvestedLabel'.tr, investor.initialCashInvestment.format(), color: Colors.teal.shade800),
            _detailRow('totalInvested'.tr, metrics.totalInvestment.format(), bold: true),
            _detailRow('totalRepaid'.tr, metrics.totalRepaidCapital.format(), color: Colors.green),
            _detailRow(
              'remainingBalance'.tr,
              metrics.remainingBalance.format(),
              bold: true,
              color: metrics.remainingBalance.isPositive ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(height: AppSpacing.md),

            // Two Action Buttons: + Add Investment | - Repay Capital/Profit
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_card_outlined, size: 18),
                    label: Text(
                      'addInvestment'.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showAddInvestmentDialog(context, investor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(
                      'newRepayment'.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showNewRepaymentDialog(context, investor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Unified Transactions History
            Text(
              'repayments'.tr,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (repayments.isEmpty && investmentLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'noRepayments'.tr,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              )
            else
              Column(
                children: [
                  // Investment additions log
                  for (final log in investmentLogs)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.teal.shade50,
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      title: Text(
                        'investmentReceived'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        log.substring(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),

                  // Repayments list
                  for (final r in repayments)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: r.type == RepaymentType.capitalReturn
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: r.type == RepaymentType.capitalReturn
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                      title: Text(
                        r.type == RepaymentType.capitalReturn
                            ? 'capitalReturn'.tr
                            : 'profitShareAmount'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(r.date),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '-${r.amount.format()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: r.type == RepaymentType.capitalReturn
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Products Funded Card ──────────────────────────────────────────────────
  Widget _buildFundedProductsCard(BuildContext context, List<Product> products) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${'fundedProducts'.tr} (${products.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'noProductsFunded'.tr,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = products[index];
                  final unitName = p.sellUnit.isNotEmpty ? p.sellUnit : p.unit;
                  final stockValue = p.costPrice * p.qty;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${p.category} • ${'stockLabel'.tr}${p.qty} $unitName • ${'buyPrice'.tr}: ${p.costPrice.format()}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stockValue.format(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${'sellPriceLabel'.tr}: ${p.suggestedSellPrice.format()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Dialog: Add Investment (বিনিয়োগ গ্রহণ / মূলধন জমা) ─────────────────
  Future<void> _showAddInvestmentDialog(BuildContext context, Investor investor) async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_card_outlined, color: Colors.teal.shade700),
                  const SizedBox(width: 8),
                  Text('addInvestment'.tr),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amtCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${'cashInvestmentAmount'.tr} *',
                        prefixText: '৳ ',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calculate_outlined),
                          onPressed: () async {
                            final res = await showCalculatorModal(
                              ctx,
                              initialValue: amtCtrl.text,
                              title: 'cashInvestmentAmount'.tr,
                            );
                            if (res != null) amtCtrl.text = res;
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'enterAmount'.tr;
                        try {
                          final m = Money.parse(v);
                          if (m.isZero || m.isNegative) return 'invalidQty'.tr;
                        } catch (_) {
                          return 'invalidQty'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: method,
                      decoration: InputDecoration(labelText: 'paymentMethod'.tr),
                      items: [
                        DropdownMenuItem(value: PaymentMethod.cash, child: Text('cash'.tr)),
                        DropdownMenuItem(value: PaymentMethod.mobileBanking, child: Text('mobile'.tr)),
                        DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('bank'.tr)),
                      ],
                      onChanged: (v) => setDialogState(() => method = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr,
                        hintText: 'e.g. অতিরিক্ত মূলধন জমা',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amt = Money.parse(amtCtrl.text);
                    final ok = await controller.addCashInvestment(
                      investorId: investor.id,
                      amount: amt,
                      paymentMethod: method,
                      note: noteCtrl.text,
                    );
                    if (ok && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('paymentSaved'.tr)),
                      );
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Pay Installment for Old Ledger ──────────────────────────────
  Future<void> _showPayOldLedgerDialog(BuildContext context, LegacySettlement settlement) async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text('payOldLedger'.tr),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'netSettlementAmount'.tr}: ${settlement.netSettlementAmount.format()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: amtCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${'repaymentAmount'.tr} *',
                    prefixText: '৳ ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate_outlined),
                      onPressed: () async {
                        final res = await showCalculatorModal(
                          ctx,
                          initialValue: amtCtrl.text,
                          title: 'repaymentAmount'.tr,
                        );
                        if (res != null) amtCtrl.text = res;
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'enterAmount'.tr;
                    try {
                      final m = Money.parse(v);
                      if (m.isZero || m.isNegative) return 'invalidQty'.tr;
                    } catch (_) {
                      return 'invalidQty'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'notes'.tr,
                    hintText: 'e.g. কিস্তি ১ / নগদ পরিশোধ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amt = Money.parse(amtCtrl.text);
                final ok = await controller.recordLegacySettlementPayment(
                  settlementId: settlement.id,
                  paymentAmount: amt,
                  note: noteCtrl.text,
                );
                if (ok && ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('paymentSaved'.tr)),
                  );
                }
              },
              child: Text('save'.tr),
            ),
          ],
        );
      },
    );
  }

  // ── Dialog: Confirm Full Settlement ──────────────────────────────────────
  Future<void> _confirmMarkSettled(BuildContext context, LegacySettlement settlement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('markSettled'.tr),
        content: Text('confirmMarkSettled'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('markSettled'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await controller.markLegacySettlementSettled(settlement.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('legacySettlementSettled'.tr)),
        );
      }
    }
  }

  // ── Dialog: New Repayment (Capital Return / Profit Share) ────────────────
  Future<void> _showNewRepaymentDialog(BuildContext context, Investor investor) async {
    final amtCtrl = TextEditingController();
    RepaymentType type = RepaymentType.capitalReturn;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('newRepayment'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amtCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${'repaymentAmount'.tr} *',
                        prefixText: '৳ ',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calculate_outlined),
                          onPressed: () async {
                            final res = await showCalculatorModal(
                              ctx,
                              initialValue: amtCtrl.text,
                              title: 'repaymentAmount'.tr,
                            );
                            if (res != null) amtCtrl.text = res;
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'enterAmount'.tr;
                        try {
                          final m = Money.parse(v);
                          if (m.isZero || m.isNegative) return 'invalidQty'.tr;
                        } catch (_) {
                          return 'invalidQty'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<RepaymentType>(
                      initialValue: type,
                      decoration: InputDecoration(labelText: 'type'.tr),
                      items: [
                        DropdownMenuItem(
                          value: RepaymentType.capitalReturn,
                          child: Text('capitalReturn'.tr),
                        ),
                        DropdownMenuItem(
                          value: RepaymentType.profitShare,
                          child: Text('profitShareAmount'.tr),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => type = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: method,
                      decoration: InputDecoration(labelText: 'paymentMethod'.tr),
                      items: [
                        DropdownMenuItem(value: PaymentMethod.cash, child: Text('cash'.tr)),
                        DropdownMenuItem(value: PaymentMethod.mobileBanking, child: Text('mobile'.tr)),
                        DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('bank'.tr)),
                      ],
                      onChanged: (v) => setDialogState(() => method = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amt = Money.parse(amtCtrl.text);
                    final ok = await controller.recordRepayment(
                      investorId: investor.id,
                      amount: amt,
                      type: type,
                      paymentMethod: method,
                    );
                    if (ok && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('paymentSaved'.tr)),
                      );
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────
  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _investmentTypeLabel(InvestmentType type) {
    return switch (type) {
      InvestmentType.cashLoan => 'cashLoan'.tr,
      InvestmentType.cashMudaraba => 'mudaraba'.tr,
      InvestmentType.cashMusharaka => 'musharaka'.tr,
      InvestmentType.goodsInKind => 'productConsignment'.tr,
    };
  }

  String _payoutCycleLabel(ProfitPayoutCycle cycle) {
    return switch (cycle) {
      ProfitPayoutCycle.daily => 'daily'.tr,
      ProfitPayoutCycle.monthly => 'monthly'.tr,
      ProfitPayoutCycle.perContract => 'perContract'.tr,
    };
  }
}
