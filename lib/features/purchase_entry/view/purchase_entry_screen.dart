import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/fund_source.dart';
import '../controller/purchase_entry_controller.dart';

/// The v2 purchase-entry screen — records a full trip (transport/other
/// costs, cash returned, one or more items) via
/// [PurchaseEntryController.save], which calls
/// `SavePurchaseTripUseCase` end-to-end (trip + items + stock movements +
/// cash-ledger entries, one outbox event). See `CatalogScreen`'s doc
/// comment for why this reads/writes the v2 database only, separate from
/// v1's Expenses & Purchases tab.
class PurchaseEntryScreen extends GetView<PurchaseEntryController> {
  const PurchaseEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'purchaseEntry'.tr} (v2)')),
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
            ],
          ),
        );
      }),
    );
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
}

class _ReconciliationPreview extends GetView<PurchaseEntryController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.reconciliationPreview;
      if (preview == null) return const SizedBox.shrink();
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('grandTotal'.tr),
                  const Spacer(),
                  Text(
                    preview.totalCashOut.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
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
