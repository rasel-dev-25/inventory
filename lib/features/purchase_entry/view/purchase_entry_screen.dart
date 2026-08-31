import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/purchase.dart';
import '../controller/purchase_entry_controller.dart';
import 'purchase_trip_form_sheet.dart';

/// The Purchase Entry screen — displays the list of recorded purchase trips
/// with complete financial details (cash taken, items, transport, other costs,
/// returned cash, net spent, and balance reconciliation status) matching the
/// old app's clarity and richness.
class PurchaseEntryScreen extends GetView<PurchaseEntryController> {
  final VoidCallback? onMenuTap;

  const PurchaseEntryScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'purchaseEntry'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        final trips = controller.recentTrips;
        if (trips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'noPurchasesYet'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'tapPlusToRecordPurchase'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
                top: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'savedPurchases'.tr} (${trips.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (final trip in trips)
              _RecentTripTile(
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
        icon: const Icon(Icons.add),
        label: Text('addPurchase'.tr),
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

class _RecentTripTile extends GetView<PurchaseEntryController> {
  final PurchaseTrip trip;
  final VoidCallback onEdit;

  const _RecentTripTile({required this.trip, required this.onEdit});

  @override
  Widget build(BuildContext context) {
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
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => controller.deleteTrip(trip.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: !hasCashTaken
                  ? Theme.of(context).colorScheme.primary
                  : isBalanced
                      ? Colors.green.shade600
                      : balanceDiff > 0
                          ? Colors.blue.shade600
                          : Colors.orange.shade700,
              width: 4,
            ),
          ),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Source badge + Date + Total Spent
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isInvestor
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          sourceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isInvestor
                                ? Colors.orange.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd-MM-yyyy').format(trip.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        totalSpent.format(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  // Row 2: Cash Taken (if entered)
                  if (hasCashTaken)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${'cashTaken'.tr}: ${cashTaken.format()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isInvestor
                              ? Colors.deepOrange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),

                  // Row 3: Items breakdown + Transport + Other costs
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${trip.items.length} ${'items'.tr}${productNames.isNotEmpty ? ' ($productNames)' : ''}'
                      '${trip.transportCost.minorUnits > 0 ? '  |  ${'transportCost'.tr}: ${trip.transportCost.format()}' : ''}'
                      '${trip.otherCostsTotal.minorUnits > 0 ? '  |  ${'otherCost'.tr}: ${trip.otherCostsTotal.format()}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),

                  // Row 4: Returned cash & Net spent
                  if (trip.cashReturned.minorUnits > 0 || hasCashTaken)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 13, color: Colors.deepPurple.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${'returnedCash'.tr}: ${trip.cashReturned.format()}  |  ${'netCashUsed'.tr}: ${netUsed.format()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Row 5: Balance status tag (OK / Fix)
                  if (hasCashTaken)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? Colors.green.shade50
                              : balanceDiff > 0
                                  ? Colors.blue.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isBalanced
                                ? Colors.green.shade300
                                : balanceDiff > 0
                                    ? Colors.blue.shade300
                                    : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          isBalanced
                              ? 'OK'
                              : balanceDiff > 0
                                  ? 'cashRemainingInHand'.trParams({'amount': Money.fromMinor(balanceDiff).format()})
                                  : 'Fix: ${Money.fromMinor(-balanceDiff).format()}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isBalanced
                                ? Colors.green.shade700
                                : balanceDiff > 0
                                    ? Colors.blue.shade700
                                    : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
