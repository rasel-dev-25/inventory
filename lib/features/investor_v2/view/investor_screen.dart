import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';
import '../controller/investor_controller.dart';
import 'investor_detail_screen.dart';
import 'investor_form_sheet.dart';

/// The Investor screen — list + rich per-investor cards,
/// backed by [InvestorController].
class InvestorScreen extends GetView<InvestorController> {
  const InvestorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'investor'.tr),
        actions: [
          IconButton(
            tooltip: 'addInvestor'.tr,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.investors.isEmpty) {
          return Center(child: Text('noInvestors'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: controller.investors.length,
          itemBuilder: (context, index) {
            final investor = controller.investors[index];
            return _InvestorCard(investor: investor);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'investor_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Investor? existing}) async {
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        initialCashInvestment: result.initialCashInvestment,
        notes: result.notes,
      );
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
        initialCashInvestment: result.initialCashInvestment,
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
    final theme = Theme.of(context);

    return Obx(() {
      final metrics = controller.metricsFor(investor);
      final settlement = controller.settlementFor(investor.id);
      final hasPendingLegacy = settlement?.status == LegacySettlementStatus.pending;

      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: hasPendingLegacy
                ? Colors.amber.shade400
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: hasPendingLegacy ? 1.2 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            Get.to(() => InvestorDetailScreen(investorId: investor.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Name + Contact + Type Badge ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(
                        investor.name.isNotEmpty ? investor.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
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

                // ── Old Ledger Warning Alert Banner (if pending) ────────────
                if (hasPendingLegacy && settlement != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${'oldLedgerDue'.tr}: ${settlement.netSettlementAmount.format()}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        Text(
                          'legacySettlementPending'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),

                // ── 3 Stat Boxes: Bought / Sold / Profit (from Old App) ──────
                Row(
                  children: [
                    _statBox('bought'.tr, metrics.totalPurchasedCash.format(), Colors.blue),
                    const SizedBox(width: 4),
                    _statBox('sold'.tr, metrics.totalSoldRevenue.format(), Colors.green),
                    const SizedBox(width: 4),
                    _statBox('profit'.tr, metrics.totalGrossProfit.format(), Colors.orange),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Profit Split Bar ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.amber.shade200, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${'profitSplit'.tr}:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                      ),
                      Text(
                        '${'investorShare'.tr} (${investor.profitSharePercent}%): ${metrics.profitShare.format()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '| ${'shopShare'.tr}: ${(metrics.totalGrossProfit - metrics.profitShare).format()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Bottom Summary Row: Stock / Remaining / Repaid ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'inStockLabel'.tr}${metrics.currentStockValue.format()}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${'repaidLabel'.tr}${metrics.totalRepaidCapital.format()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${'remainingBalance'.tr}: ${metrics.remainingBalance.format()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: metrics.remainingBalance.isPositive
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
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

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
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

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
