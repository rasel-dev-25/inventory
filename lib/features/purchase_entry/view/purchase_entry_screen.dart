import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/purchase.dart';
import '../controller/purchase_entry_controller.dart';
import 'purchase_trip_form_sheet.dart';

/// The Purchase Entry screen — modern, clean, organized financial overview and trip history.
class PurchaseEntryScreen extends GetView<PurchaseEntryController> {
  final VoidCallback? onMenuTap;

  const PurchaseEntryScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'purchaseEntry'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        final allTrips = controller.recentTrips;
        if (allTrips.isEmpty) {
          return _buildEmptyState(context);
        }

        final filteredTrips = controller.filteredTrips;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // ── Financial Overview Cards Strip ─────────────────────────────
            _buildFinancialOverview(context),

            const SizedBox(height: AppSpacing.md),

            // ── Search & Fund Filter Bar ───────────────────────────────────
            _buildSearchAndFilterBar(context),

            const SizedBox(height: AppSpacing.sm),

            // ── Section Title ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'savedPurchases'.tr} (${filteredTrips.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Purchase Trip Cards List ───────────────────────────────────
            if (filteredTrips.isEmpty)
              _buildNoFilterResults(context)
            else
              for (final trip in filteredTrips)
                _ModernTripCard(
                  trip: trip,
                  onEdit: () => _openTripSheet(context, trip: trip),
                ),

            const SizedBox(height: 80), // padding for FAB
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'purchase_entry_fab',
        onPressed: () => _openTripSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('addPurchase'.tr),
      ),
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    final theme = Theme.of(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'মোট ক্রয় হিসাব',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${controller.totalPurchaseTripsCount} ${'totalPurchaseTrips'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'totalPurchasesValue'.tr,
                  value: controller.totalPurchasesAmount.format(),
                  icon: Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'totalTransportCosts'.tr,
                  value: controller.totalTransportAndOtherCosts.format(),
                  icon: Icons.local_shipping_outlined,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          if (controller.totalRemainingCash.minorUnits > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'totalUnusedCash'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    controller.totalRemainingCash.format(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Clean Search Field
        TextField(
          onChanged: controller.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'searchPurchasesHint'.tr,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.setSearchQuery('');
                    },
                  )
                : const SizedBox.shrink()),
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Fund Source Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() {
            final currentFilter = controller.selectedFundFilter.value;
            final filters = [
              {'key': 'all', 'label': 'purchaseFilterAll'.tr, 'icon': Icons.tune_rounded},
              {'key': 'cash', 'label': 'purchaseFilterCash'.tr, 'icon': Icons.payments_outlined},
              {'key': 'investor', 'label': 'purchaseFilterInvestor'.tr, 'icon': Icons.handshake_outlined},
            ];

            return Row(
              children: filters.map((f) {
                final isSelected = currentFilter == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(
                      f['icon'] as IconData,
                      size: 14,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(f['label'] as String),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (_) => controller.setFundFilter(f['key'] as String),
                  ),
                );
              }).toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'noPurchasesYet'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'tapPlusToRecordPurchase'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResults(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'কোনো ক্রয় ট্রিপ পাওয়া যায়নি',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: controller.resetFilters,
              child: Text('সব ট্রিপ দেখুন'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTripSheet(BuildContext context, {PurchaseTrip? trip}) async {
    if (trip != null) {
      controller.editTrip(trip);
    } else {
      controller.resetDraft();
      if (controller.items.isEmpty) {
        controller.addItem();
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PurchaseTripFormSheet(),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trip == null ? 'purchaseTripSaved'.tr : 'purchaseTripUpdated'.tr,
          ),
        ),
      );
    }
  }
}

extension on PurchaseEntryController {
  int get totalPurchaseTripsCount => filteredTrips.length;
}

/// A clean, organized, premium card representation for a PurchaseTrip.
class _ModernTripCard extends GetView<PurchaseEntryController> {
  final PurchaseTrip trip;
  final VoidCallback onEdit;

  const _ModernTripCard({required this.trip, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final itemsTotal = trip.items.fold(
      Money.zero(),
      (sum, i) => sum + i.lineTotal,
    );
    final totalSpent = itemsTotal + trip.transportCost + trip.otherCostsTotal;
    final hasCashTaken = trip.actualCashTakenOut != null && trip.actualCashTakenOut!.minorUnits > 0;
    final cashTaken = trip.actualCashTakenOut ?? Money.zero();
    final netUsed = hasCashTaken
        ? cashTaken - trip.cashReturned
        : totalSpent - trip.cashReturned;
    final balanceDiff = hasCashTaken ? (netUsed.minorUnits - totalSpent.minorUnits) : 0;
    final isBalanced = !hasCashTaken || (balanceDiff.abs() < 100);

    // Determine fund source label
    final isInvestor = trip.items.any((i) => i.fundSource.isInvestor);
    final investorIds = trip.items
        .where((i) => i.fundSource.isInvestor)
        .map((i) => i.fundSource.investorId)
        .toSet();
    final investorName = investorIds.isNotEmpty
        ? (controller.investors.firstWhereOrNull((inv) => inv.id == investorIds.first)?.name ?? 'investor'.tr)
        : 'investor'.tr;
    final sourceLabel = isInvestor
        ? (investorIds.length > 1 ? 'fundedByInvestor'.tr : investorName)
        : 'cash'.tr;

    final productNames = trip.items
        .map((i) {
          final prod = controller.products.firstWhereOrNull((p) => p.id == i.productId);
          return prod?.name ?? i.productId;
        })
        .where((name) => name.isNotEmpty)
        .take(3)
        .join(', ');

    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(
          Icons.delete_forever_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => controller.deleteTrip(trip.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Source Pill + Date + Total Spent ─────────────────
                Row(
                  children: [
                    // Fund Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInvestor ? Colors.orange.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isInvestor ? Colors.orange.shade200 : Colors.blue.shade200,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInvestor ? Icons.handshake_outlined : Icons.payments_outlined,
                            size: 13,
                            color: isInvestor ? Colors.orange.shade800 : Colors.blue.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sourceLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isInvestor ? Colors.orange.shade900 : Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date
                    Icon(Icons.calendar_today_outlined, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(trip.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Total Spent
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalSpent.format(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'totalSpent'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Items & Costs Breakdown ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items Summary
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${trip.items.length}টি পণ্য',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (productNames.isNotEmpty)
                                    TextSpan(
                                      text: ' ($productNames)',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Transport & Other Costs
                      if (trip.transportCost.minorUnits > 0 || trip.otherCostsTotal.minorUnits > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (trip.transportCost.minorUnits > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_shipping_outlined, size: 13, color: Colors.orange.shade800),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${'transportCost'.tr}: ${trip.transportCost.format()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (trip.otherCostsTotal.minorUnits > 0)
                              Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 13, color: Colors.purple.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${'otherCost'.tr}: ${trip.otherCostsTotal.format()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Cash Reconciliation Block (if cash taken out) ────────────
                if (hasCashTaken) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isBalanced
                          ? Colors.green.shade50.withValues(alpha: 0.6)
                          : balanceDiff > 0
                              ? Colors.blue.shade50.withValues(alpha: 0.6)
                              : Colors.red.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBalanced
                            ? Colors.green.shade200
                            : balanceDiff > 0
                                ? Colors.blue.shade200
                                : Colors.red.shade200,
                        width: 0.7,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${'cashTaken'.tr}: ${cashTaken.format()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isInvestor ? Colors.deepOrange.shade800 : Colors.green.shade800,
                              ),
                            ),
                            if (trip.cashReturned.minorUnits > 0) ...[
                              Text(
                                '  •  ${'returnedCash'.tr}: ${trip.cashReturned.format()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              isBalanced
                                  ? Icons.check_circle_outline_rounded
                                  : balanceDiff > 0
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.warning_amber_rounded,
                              size: 13,
                              color: isBalanced
                                  ? Colors.green.shade700
                                  : balanceDiff > 0
                                      ? Colors.blue.shade700
                                      : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBalanced
                                  ? 'cashBalanced'.tr
                                  : balanceDiff > 0
                                      ? 'cashRemainingInHand'.trParams({'amount': Money.fromMinor(balanceDiff).format()})
                                      : 'cashSpentFromExtra'.trParams({'amount': Money.fromMinor(-balanceDiff).format()}),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isBalanced
                                    ? Colors.green.shade800
                                    : balanceDiff > 0
                                        ? Colors.blue.shade800
                                        : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr} ${'purchaseEntry'.tr}?'),
        content: Text('cannotUndoNote'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
