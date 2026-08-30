import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/services/purchase_reconciliation.dart';
import '../../investor_v2/view/investor_form_sheet.dart';
import '../controller/purchase_entry_controller.dart';

/// The purchase-entry screen — records a full trip (transport/other
/// costs, cash returned, one or more items) via
/// [PurchaseEntryController.save], which calls
/// `SavePurchaseTripUseCase` end-to-end (trip + items + stock movements +
/// cash-ledger entries, one outbox event).
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
        if (controller.products.isEmpty) {
          return Center(child: Text('noProductsYet'.tr));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TripHeaderSection(),
              const SizedBox(height: AppSpacing.xl),
              _OtherCostsSection(),
              const SizedBox(height: AppSpacing.xl),
              _ItemsSection(),
              const SizedBox(height: AppSpacing.xl),
              _ReconciliationPreview(),
              const SizedBox(height: AppSpacing.lg),
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    controller.errorMessage.value!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final ok = await controller.save();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('purchaseTripSaved'.tr)),
                          );
                        }
                      },
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('savePurchase'.tr),
              ),
              const SizedBox(height: AppSpacing.xl),
              _RecentTripsSection(),
            ],
          ),
        );
      }),
    );
  }
}

/// The first real UI trigger for `DeletePurchaseTripUseCase` — see
/// `PurchaseEntryController.recentTrips`'s own doc comment for why this
/// list exists at all (that use case was previously dead code with no
/// reachable delete action anywhere). Existing trips can also be corrected;
/// the controller records that correction through the append-only ledger.
class _RecentTripsSection extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trips = controller.recentTrips;
      if (trips.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'recentTripsSectionTitle'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final trip in trips) _RecentTripTile(trip: trip),
        ],
      );
    });
  }
}

class _RecentTripTile extends GetView<PurchaseEntryController> {
  final PurchaseTrip trip;

  const _RecentTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final total = reconcilePurchaseTrip(trip).totalCashOut;
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
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          title: Text(DateFormat.yMMMd().format(trip.date)),
          subtitle: Text('${trip.items.length} ${'items'.tr}'),
          leading: IconButton(
            tooltip: 'edit'.tr,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => controller.editTrip(trip),
          ),
          trailing: Text(
            total.format(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  /// Same confirm-before-dismiss pattern `CustomersScreen`'s
  /// `_confirmDelete` establishes — extra warranted here since, like a
  /// fixed asset, this delete is *not* restorable (see
  /// `DeletePurchaseTripUseCase`'s own doc comment).
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

class _TripHeaderSection extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('tripDate'.tr),
                subtitle: Text(
                  DateFormat.yMMMd().format(controller.tripDate.value),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: controller.tripDate.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) controller.tripDate.value = picked;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyField(
              label: 'transportCost'.tr,
              value: controller.transportCost,
              onChanged: (m) => controller.transportCost.value = m,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyField(
              label: 'returnedCash'.tr,
              value: controller.cashReturned,
              onChanged: (m) => controller.cashReturned.value = m,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActualCashField(),
          ],
        ),
      ),
    );
  }
}

class _OtherCostsSection extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'otherCosts'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addOtherCost,
                icon: const Icon(Icons.add),
                label: Text('addOne'.tr),
              ),
            ],
          ),
          for (final cost in controller.otherCosts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'description'.tr,
                        ),
                        onChanged: (v) => cost.description = v,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 100,
                      child: _MoneyField(
                        label: 'amount'.tr,
                        value: cost.amount.obs,
                        onChanged: (m) => cost.amount = m,
                        dense: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.removeOtherCost(cost),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemsSection extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('items'.tr, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addItem,
                icon: const Icon(Icons.add),
                label: Text('addItem'.tr),
              ),
            ],
          ),
          for (final item in controller.items) _ItemCard(item: item),
        ],
      ),
    );
  }
}

class _ItemCard extends GetView<PurchaseEntryController> {
  final DraftPurchaseItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: item.productId,
                    decoration: InputDecoration(labelText: 'selectProduct'.tr),
                    items: [
                      for (final p in controller.products)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) {
                      item.productId = v;
                      controller.items.refresh();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'addInvestor'.tr,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  onPressed: () => _addInvestor(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.removeItem(item),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.shopName,
                    decoration: InputDecoration(labelText: 'shopName'.tr),
                    onChanged: (v) => item.shopName = v,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: item.qty.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'qty'.tr),
                    onChanged: (v) => item.qty = double.tryParse(v) ?? item.qty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyField(
              label: 'unitPrice'.tr,
              value: item.unitPrice.obs,
              onChanged: (m) => item.unitPrice = m,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('fundedByInvestor'.tr),
                    value: item.fundSource.isInvestor,
                    onChanged: (v) {
                      item.fundSource = v
                          ? FundSource.investor(
                              controller.investors.isEmpty
                                  ? ''
                                  : controller.investors.first.id,
                            )
                          : FundSource.shop();
                      controller.items.refresh();
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('inKind'.tr),
                    value: item.isInKind,
                    onChanged: (v) {
                      item.isInKind = v;
                      controller.items.refresh();
                    },
                  ),
                ),
              ],
            ),
            if (item.fundSource.isInvestor)
              DropdownButtonFormField<String>(
                initialValue: item.fundSource.investorId,
                decoration: InputDecoration(labelText: 'selectInvestor'.tr),
                items: [
                  for (final i in controller.investors)
                    DropdownMenuItem(value: i.id, child: Text(i.name)),
                ],
                onChanged: (v) {
                  if (v != null) item.fundSource = FundSource.investor(v);
                  controller.items.refresh();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInvestor(BuildContext context) async {
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const InvestorFormSheet(includeLegacySettlement: false),
    );
    if (result == null) return;

    final investor = await controller.createInvestor(
      name: result.name,
      contact: result.contact,
      investmentType: result.investmentType,
      profitSharePercent: result.profitSharePercent,
      capitalReturnTermDays: result.capitalReturnTermDays,
      profitPayoutCycle: result.profitPayoutCycle,
      notes: result.notes,
    );
    if (investor == null || !context.mounted) return;
    item.fundSource = FundSource.investor(investor.id);
    controller.items.refresh();
  }
}

class _ReconciliationPreview extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.reconciliationPreview;
      if (preview == null) return const SizedBox.shrink();
      final actual = controller.actualCashTakenOut.value;
      final reconciles = actual != null && preview.reconciles(actual);
      final difference = actual == null
          ? null
          : actual.minorUnits - preview.totalCashOut.minorUnits;
      final scheme = Theme.of(context).colorScheme;
      return Card(
        color: actual == null
            ? scheme.surfaceContainerHighest
            : reconciles
            ? scheme.primaryContainer
            : scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('calculatedCashOut'.tr),
                  const Spacer(),
                  Text(
                    preview.totalCashOut.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (actual != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text('actualCashTaken'.tr),
                    const Spacer(),
                    Text(actual.format()),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  reconciles
                      ? 'cashReconciles'.tr
                      : difference! < 0
                      ? 'cashShortBy'.trParams({
                          'amount': Money.fromMinor(-difference).format(),
                        })
                      : 'cashOverBy'.trParams({
                          'amount': Money.fromMinor(difference).format(),
                        }),
                  key: const Key('purchase-reconciliation-status'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: reconciles
                        ? scheme.onPrimaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Text('enterActualCashForCheck'.tr),
              ],
              for (final bucket in preview.byFundSource)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text(
                        bucket.fundSource.isShop
                            ? 'fundedByShop'.tr
                            : 'fundedByInvestor'.tr,
                      ),
                      const Spacer(),
                      Text(bucket.amount.format()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _ActualCashField extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TextFormField(
        key: ValueKey(controller.actualCashTakenOut.value?.minorUnits),
        initialValue: controller.actualCashTakenOut.value?.format(
          showSymbol: false,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'actualCashTaken'.tr,
          helperText: 'actualCashTakenHelp'.tr,
        ),
        onChanged: (text) {
          try {
            controller.actualCashTakenOut.value = text.trim().isEmpty
                ? null
                : Money.parse(text);
          } on MoneyException {
            // Keep the previous valid value while the user is mid-edit.
          }
        },
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final String label;
  final Rx<Money> value;
  final ValueChanged<Money> onChanged;
  final bool dense;

  const _MoneyField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.value.minorUnits == 0
          ? ''
          : value.value.format(showSymbol: false),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: dense),
      onChanged: (text) {
        try {
          onChanged(text.trim().isEmpty ? Money.zero() : Money.parse(text));
        } on MoneyException {
          // Leave the previous value in place while the user is still
          // mid-edit (e.g. a lone "-" or trailing "."); the field's own
          // displayed text is untouched either way since this isn't a
          // controller-driven TextField.
        }
      },
    );
  }
}
