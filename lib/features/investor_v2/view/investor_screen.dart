import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/legacy_settlement.dart';
import '../controller/investor_controller.dart';
import 'investor_form_sheet.dart';

/// The Investor screen — list + per-investor metrics
/// (`notes/business_logic.md` §ঙ) and repayment recording, backed by
/// [InvestorController].
class InvestorScreen extends GetView<InvestorController> {
  const InvestorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'investor'.tr} (v2)')),
      body: Obx(() {
        if (controller.investors.isEmpty) {
          return Center(child: Text('noInvestors'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.investors.length,
          itemBuilder: (context, index) {
            final investor = controller.investors[index];
            return _InvestorCard(investor: investor);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Investor? existing}) async {
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => InvestorFormSheet(existing: existing),
    );
    if (result == null) return;

    if (existing == null) {
      final newInvestorId = await controller.createInvestor(
        name: result.name,
        contact: result.contact,
        investmentType: result.investmentType,
        profitSharePercent: result.profitSharePercent,
        capitalReturnTermDays: result.capitalReturnTermDays,
        profitPayoutCycle: result.profitPayoutCycle,
        notes: result.notes,
      );
      // Only ever set when `InvestorFormSheet`'s "has an old ledger-book
      // account?" toggle was on — see `LegacySettlementFormResult`'s doc
      // comment. Created as a second, separate write rather than folded
      // into `createInvestor` itself, since the investor and its (at
      // most one) legacy settlement are genuinely different aggregates
      // with independent validation.
      final legacy = result.legacySettlement;
      if (newInvestorId != null && legacy != null) {
        await controller.createLegacySettlement(
          investorId: newInvestorId,
          totalHistoricalInvestment: legacy.totalHistoricalInvestment,
          totalAlreadyReturned: legacy.totalAlreadyReturned,
          settlementDate: legacy.settlementDate,
          notes: legacy.notes,
        );
      }
    } else {
      await controller.updateInvestor(
        existing,
        name: result.name,
        contact: result.contact,
        investmentType: result.investmentType,
        profitSharePercent: result.profitSharePercent,
        capitalReturnTermDays: result.capitalReturnTermDays,
        profitPayoutCycle: result.profitPayoutCycle,
        notes: result.notes,
      );
    }
  }
}

class _InvestorCard extends GetView<InvestorController> {
  final Investor investor;
  const _InvestorCard({required this.investor});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final metrics = controller.metricsFor(investor);
      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        investor.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _investmentTypeLabel(investor.investmentType),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (controller.settlementFor(investor.id)?.status ==
                    LegacySettlementStatus.pending) ...[
                  const SizedBox(height: 2),
                  Text(
                    'legacySettlementPending'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(context, 'totalInvested'.tr, metrics.totalInvestment),
                    _stat(
                      context,
                      'remainingBalance'.tr,
                      metrics.remainingBalance,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _stat(BuildContext context, String label, Money value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value.format(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InvestorDetailSheet(investor: investor),
    );
  }
}

String _investmentTypeLabel(InvestmentType type) {
  return switch (type) {
    InvestmentType.cashLoan => 'cashLoan'.tr,
    InvestmentType.cashMudaraba => 'mudaraba'.tr,
    InvestmentType.cashMusharaka => 'musharaka'.tr,
    InvestmentType.goodsInKind => 'productConsignment'.tr,
  };
}

class _InvestorDetailSheet extends GetView<InvestorController> {
  final Investor investor;
  const _InvestorDetailSheet({required this.investor});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final metrics = controller.metricsFor(investor);
      final history = controller.repaymentsFor(investor.id);
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      investor.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'editInvestor'.tr,
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editInvestor(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _row(context, 'totalInvested'.tr, metrics.totalInvestment),
              _row(context, 'currentStockValue'.tr, metrics.currentStockValue),
              _row(context, 'totalBought'.tr, metrics.totalPurchasedCash),
              _row(context, 'totalSold'.tr, metrics.totalSoldRevenue),
              _row(context, 'profitShareAmount'.tr, metrics.profitShare),
              _row(context, 'totalRepaid'.tr, metrics.totalRepaidCapital),
              _row(
                context,
                'remainingBalance'.tr,
                metrics.remainingBalance,
                emphasize: true,
              ),
              if (controller.settlementFor(investor.id) case final settlement?)
                _LegacySettlementSection(settlement: settlement),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => _showRepayDialog(context),
                child: Text('repay'.tr),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'repayments'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (history.isEmpty)
                Text('noRepayments'.tr)
              else
                for (final repayment in history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      repayment.type == RepaymentType.capitalReturn
                          ? 'capitalReturn'.tr
                          : 'profitShareAmount'.tr,
                    ),
                    subtitle: Text(
                      repayment.date.toLocal().toString().split(' ').first,
                    ),
                    trailing: Text(repayment.amount.format()),
                  ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _editInvestor(BuildContext context) async {
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
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
      notes: result.notes,
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    Money value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value.format(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: emphasize && value.isNegative
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRepayDialog(BuildContext context) async {
    final amountController = TextEditingController();
    RepaymentType type = RepaymentType.capitalReturn;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('addRepayment'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'repaymentAmount'.tr,
                      ),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<RepaymentType>(
                      segments: [
                        ButtonSegment(
                          value: RepaymentType.capitalReturn,
                          label: Text('capitalReturn'.tr),
                        ),
                        ButtonSegment(
                          value: RepaymentType.profitShare,
                          label: Text('profitShareAmount'.tr),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setState(() => type = s.first),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<PaymentMethod>(
                      segments: [
                        ButtonSegment(
                          value: PaymentMethod.cash,
                          label: Text('cash'.tr),
                        ),
                        ButtonSegment(
                          value: PaymentMethod.mobileBanking,
                          label: Text('mobile'.tr),
                        ),
                        ButtonSegment(
                          value: PaymentMethod.bankTransfer,
                          label: Text('bank'.tr),
                        ),
                      ],
                      selected: {method},
                      onSelectionChanged: (s) =>
                          setState(() => method = s.first),
                    ),
                    Obx(
                      () => controller.errorMessage.value == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                controller.errorMessage.value!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = _parseMoneyOrNull(
                              amountController.text,
                            )!;
                            final ok = await controller.recordRepayment(
                              investorId: investor.id,
                              amount: amount,
                              type: type,
                              paymentMethod: method,
                            );
                            if (ok && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            } else {
                              setState(() {});
                            }
                          },
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('repay'.tr),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Same pattern as `daily_sales_v2`/`dues_v2`'s `_parseMoneyOrNull` —
/// `Money` has no `tryParse`, see those files' doc comments for why every
/// live-input field wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}

/// The read-only §৬ memo for an investor's old ledger-book account, plus
/// (only while [LegacySettlementStatus.pending]) the one-time "Mark
/// Settled" action. Never editable after creation — see
/// `LegacySettlement`'s own class doc comment.
class _LegacySettlementSection extends GetView<InvestorController> {
  final LegacySettlement settlement;
  const _LegacySettlementSection({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final isPending = settlement.status == LegacySettlementStatus.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        Text(
          'legacySettlementSectionTitle'.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _row(
          context,
          'totalHistoricalInvestment'.tr,
          settlement.totalHistoricalInvestment,
        ),
        _row(
          context,
          'totalAlreadyReturned'.tr,
          settlement.totalAlreadyReturned,
        ),
        _row(
          context,
          'netSettlementAmount'.tr,
          settlement.netSettlementAmount,
          emphasize: true,
        ),
        if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(settlement.notes!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          isPending
              ? 'legacySettlementPending'.tr
              : 'legacySettlementSettled'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isPending
                ? Theme.of(context).colorScheme.error
                : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!isPending) ...[
          const SizedBox(height: 4),
          Text(
            'legacySettlementAlreadySettledNote'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (isPending) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => _confirmMarkSettled(context),
            child: Text('markSettled'.tr),
          ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    Money value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value.format(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkSettled(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('markSettled'.tr),
        content: Text('confirmMarkSettled'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('markSettled'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.markLegacySettlementSettled(settlement.id);
    }
  }
}
