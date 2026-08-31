import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../domain/entities/fund_source.dart';
import '../../investor_v2/view/investor_form_sheet.dart';
import '../controller/purchase_entry_controller.dart';

/// Modal bottom sheet form for creating or editing a [PurchaseTrip].
///
/// Encapsulates all trip-level metadata (date, transport, returned cash,
/// optional cash taken out), miscellaneous costs, item breakdown (with
/// autocomplete, direct new product creation on the fly, and investor tagging),
/// and comprehensive financial summary with live balance check.
class PurchaseTripFormSheet extends GetView<PurchaseEntryController> {
  const PurchaseTripFormSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),

                // Title row with close button
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Text(
                          controller.editingOriginalTripId.value == null
                              ? 'newPurchaseTrip'.tr
                              : 'editPurchaseTrip'.tr,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'cancel'.tr,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Trip header section (Date, Cash Taken, Returned Cash, Transport)
                const _TripHeaderSection(),
                const SizedBox(height: AppSpacing.lg),

                // Items section
                const _ItemsSection(),
                const SizedBox(height: AppSpacing.lg),

                // Other costs section
                const _OtherCostsSection(),
                const SizedBox(height: AppSpacing.lg),

                // Live summary & reconciliation card
                const _ReconciliationPreview(),
                const SizedBox(height: AppSpacing.md),

                // Error message display
                Obx(() {
                  final error = controller.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),

                // Save / Update action button
                Obx(
                  () => FilledButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            final ok = await controller.save();
                            if (ok && context.mounted) {
                              Navigator.of(context).pop(true);
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripHeaderSection extends StatefulWidget {
  const _TripHeaderSection();

  @override
  State<_TripHeaderSection> createState() => _TripHeaderSectionState();
}

class _TripHeaderSectionState extends State<_TripHeaderSection> {
  late final TextEditingController _cashTakenController;
  late final TextEditingController _returnedCashController;
  late final TextEditingController _transportCostController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<PurchaseEntryController>();
    _cashTakenController = TextEditingController(
      text: controller.actualCashTakenOut.value?.format(showSymbol: false) ?? '',
    );
    _returnedCashController = TextEditingController(
      text: controller.cashReturned.value.minorUnits == 0
          ? ''
          : controller.cashReturned.value.format(showSymbol: false),
    );
    _transportCostController = TextEditingController(
      text: controller.transportCost.value.minorUnits == 0
          ? ''
          : controller.transportCost.value.format(showSymbol: false),
    );
  }

  @override
  void dispose() {
    _cashTakenController.dispose();
    _returnedCashController.dispose();
    _transportCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PurchaseEntryController>();

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

            // Cash Taken Out (Optional)
            TextFormField(
              controller: _cashTakenController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'actualCashTaken'.tr,
                helperText: 'actualCashTakenHelp'.tr,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  tooltip: 'calculator'.tr,
                  onPressed: () async {
                    final res = await showCalculatorModal(
                      context,
                      initialValue: _cashTakenController.text,
                      title: 'actualCashTaken'.tr,
                    );
                    if (res != null) {
                      _cashTakenController.text = res;
                      try {
                        controller.actualCashTakenOut.value = res.trim().isEmpty ? null : Money.parse(res);
                      } catch (_) {}
                    }
                  },
                ),
              ),
              onChanged: (text) {
                try {
                  controller.actualCashTakenOut.value = text.trim().isEmpty
                      ? null
                      : Money.parse(text);
                } on MoneyException {
                  // Keep the previous valid value while user is mid-typing
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Returned Cash
            TextFormField(
              controller: _returnedCashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'returnedCash'.tr,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  tooltip: 'calculator'.tr,
                  onPressed: () async {
                    final res = await showCalculatorModal(
                      context,
                      initialValue: _returnedCashController.text,
                      title: 'returnedCash'.tr,
                    );
                    if (res != null) {
                      _returnedCashController.text = res;
                      try {
                        controller.cashReturned.value = res.trim().isEmpty ? Money.zero() : Money.parse(res);
                      } catch (_) {}
                    }
                  },
                ),
              ),
              onChanged: (text) {
                try {
                  controller.cashReturned.value = text.trim().isEmpty
                      ? Money.zero()
                      : Money.parse(text);
                } on MoneyException {
                  // Keep previous valid value
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Transport Cost
            TextFormField(
              controller: _transportCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'transportCost'.tr,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  tooltip: 'calculator'.tr,
                  onPressed: () async {
                    final res = await showCalculatorModal(
                      context,
                      initialValue: _transportCostController.text,
                      title: 'transportCost'.tr,
                    );
                    if (res != null) {
                      _transportCostController.text = res;
                      try {
                        controller.transportCost.value = res.trim().isEmpty ? Money.zero() : Money.parse(res);
                      } catch (_) {}
                    }
                  },
                ),
              ),
              onChanged: (text) {
                try {
                  controller.transportCost.value = text.trim().isEmpty
                      ? Money.zero()
                      : Money.parse(text);
                } on MoneyException {
                  // Keep previous valid value
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherCostsSection extends GetView<PurchaseEntryController> {
  const _OtherCostsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'otherCostsTotal'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addOtherCost,
                icon: const Icon(Icons.add, size: 18),
                label: Text('addOne'.tr),
              ),
            ],
          ),
          for (final cost in controller.otherCosts)
            _OtherCostRow(key: ValueKey(cost), cost: cost),
        ],
      ),
    );
  }
}

class _OtherCostRow extends StatefulWidget {
  final DraftOtherCost cost;

  const _OtherCostRow({super.key, required this.cost});

  @override
  State<_OtherCostRow> createState() => _OtherCostRowState();
}

class _OtherCostRowState extends State<_OtherCostRow> {
  late final TextEditingController _descController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.cost.description);
    _amountController = TextEditingController(
      text: widget.cost.amount.minorUnits == 0
          ? ''
          : widget.cost.amount.format(showSymbol: false),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PurchaseEntryController>();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'description'.tr,
                  isDense: true,
                ),
                onChanged: (v) => widget.cost.description = v,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'cost'.tr,
                  isDense: true,
                ),
                onChanged: (text) {
                  try {
                    widget.cost.amount = text.trim().isEmpty
                        ? Money.zero()
                        : Money.parse(text);
                    controller.otherCosts.refresh();
                  } on MoneyException {
                    // mid-typing
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => controller.removeOtherCost(widget.cost),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends GetView<PurchaseEntryController> {
  const _ItemsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'items'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addItem,
                icon: const Icon(Icons.add, size: 18),
                label: Text('addItem'.tr),
              ),
            ],
          ),
          if (controller.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: controller.addItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('addItem'.tr),
                ),
              ),
            )
          else
            for (final item in controller.items)
              _ItemCard(key: ValueKey(item.id), item: item),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final DraftPurchaseItem item;

  const _ItemCard({super.key, required this.item});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _shopController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<PurchaseEntryController>();
    final initialName = widget.item.productName.isNotEmpty
        ? widget.item.productName
        : (controller.products.firstWhereOrNull((p) => p.id == widget.item.productId)?.name ?? '');
    _nameController = TextEditingController(text: initialName);
    _shopController = TextEditingController(text: widget.item.shopName);
    _qtyController = TextEditingController(
      text: widget.item.qty == 0
          ? ''
          : (widget.item.qty % 1 == 0
              ? widget.item.qty.toInt().toString()
              : widget.item.qty.toString()),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.minorUnits == 0
          ? ''
          : widget.item.unitPrice.format(showSymbol: false),
    );
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    _shopController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PurchaseEntryController>();
    final effectiveProductName = widget.item.productName.isNotEmpty
        ? widget.item.productName
        : (controller.products.firstWhereOrNull((p) => p.id == widget.item.productId)?.name ?? '');

    final isNewProduct = effectiveProductName.trim().isNotEmpty &&
        !controller.products.any((p) => p.name.trim().toLowerCase() == effectiveProductName.trim().toLowerCase());

    final lineTotal = widget.item.unitPrice * widget.item.qty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item / Product Name with Autocomplete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: _nameController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.trim().toLowerCase();
                      if (query.isEmpty || !_nameFocusNode.hasFocus) {
                        return const Iterable<String>.empty();
                      }
                      return controller.products
                          .map((p) => p.name)
                          .where((name) => name.toLowerCase().contains(query))
                          .take(8);
                    },
                    onSelected: (String selection) {
                      _nameController.text = selection;
                      widget.item.productName = selection;
                      final matched = controller.products.firstWhereOrNull(
                        (p) => p.name.trim().toLowerCase() == selection.trim().toLowerCase(),
                      );
                      if (matched != null) {
                        widget.item.productId = matched.id;
                        if (widget.item.unitPrice.minorUnits == 0 && matched.costPrice.minorUnits > 0) {
                          widget.item.unitPrice = matched.costPrice;
                          _priceController.text = matched.costPrice.format(showSymbol: false);
                        }
                      } else {
                        widget.item.productId = null;
                      }
                      setState(() {});
                      controller.items.refresh();
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textController,
                        focusNode: _nameFocusNode,
                        decoration: InputDecoration(
                          labelText: 'itemOrProductName'.tr,
                          hintText: 'itemOrProductHint'.tr,
                          isDense: true,
                          prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                        onChanged: (text) {
                          widget.item.productName = text.trim();
                          final matched = controller.products.firstWhereOrNull(
                            (p) => p.name.trim().toLowerCase() == text.trim().toLowerCase(),
                          );
                          widget.item.productId = matched?.id;
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'removeItem'.tr,
                  onPressed: () => controller.removeItem(widget.item),
                ),
              ],
            ),

            if (isNewProduct) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'newProductAutoCreate'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Shop Name
            TextFormField(
              controller: _shopController,
              decoration: InputDecoration(
                labelText: 'shopName'.tr,
                isDense: true,
                prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
              ),
              onChanged: (v) => widget.item.shopName = v,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Qty & Unit Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'qty'.tr,
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calculate_outlined, size: 18),
                        tooltip: 'calculator'.tr,
                        onPressed: () async {
                          final res = await showCalculatorModal(
                            context,
                            initialValue: _qtyController.text,
                            title: 'qty'.tr,
                            currencySymbol: '',
                          );
                          if (res != null) {
                            _qtyController.text = res;
                            widget.item.qty = double.tryParse(res) ?? 1.0;
                            setState(() {});
                            controller.items.refresh();
                          }
                        },
                      ),
                    ),
                    onChanged: (v) {
                      widget.item.qty = double.tryParse(v) ?? 1.0;
                      setState(() {});
                      controller.items.refresh();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'unitPrice'.tr,
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calculate_outlined, size: 18),
                        tooltip: 'calculator'.tr,
                        onPressed: () async {
                          final res = await showCalculatorModal(
                            context,
                            initialValue: _priceController.text,
                            title: 'unitPrice'.tr,
                          );
                          if (res != null) {
                            _priceController.text = res;
                            try {
                              widget.item.unitPrice = res.trim().isEmpty ? Money.zero() : Money.parse(res);
                              setState(() {});
                              controller.items.refresh();
                            } catch (_) {}
                          }
                        },
                      ),
                    ),
                    onChanged: (text) {
                      try {
                        widget.item.unitPrice = text.trim().isEmpty
                            ? Money.zero()
                            : Money.parse(text);
                        setState(() {});
                        controller.items.refresh();
                      } on MoneyException {
                        // mid-typing
                      }
                    },
                  ),
                ),
              ],
            ),

            // Line Total Badge
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${'lineTotal'.tr}: ${lineTotal.format()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Funding options
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('fundedByInvestor'.tr, style: const TextStyle(fontSize: 12)),
                    value: widget.item.fundSource.isInvestor,
                    onChanged: (v) async {
                      if (v) {
                        if (controller.investors.isEmpty) {
                          await _addInvestor(context);
                        } else {
                          widget.item.fundSource = FundSource.investor(controller.investors.first.id);
                          controller.items.refresh();
                        }
                      } else {
                        widget.item.fundSource = FundSource.shop();
                        controller.items.refresh();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('inKind'.tr, style: const TextStyle(fontSize: 12)),
                    value: widget.item.isInKind,
                    onChanged: (v) {
                      widget.item.isInKind = v;
                      controller.items.refresh();
                    },
                  ),
                ),
              ],
            ),

            if (widget.item.fundSource.isInvestor)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.investors.any((i) => i.id == widget.item.fundSource.investorId)
                          ? widget.item.fundSource.investorId
                          : (controller.investors.isNotEmpty ? controller.investors.first.id : null),
                      decoration: InputDecoration(
                        labelText: 'selectInvestor'.tr,
                        isDense: true,
                      ),
                      items: [
                        for (final i in controller.investors)
                          DropdownMenuItem(value: i.id, child: Text(i.name)),
                      ],
                      onChanged: (v) {
                        if (v != null && v.isNotEmpty) {
                          widget.item.fundSource = FundSource.investor(v);
                          controller.items.refresh();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'addInvestor'.tr,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    onPressed: () => _addInvestor(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInvestor(BuildContext context) async {
    final controller = Get.find<PurchaseEntryController>();
    final result = await showModalBottomSheet<InvestorFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const InvestorFormSheet(includeLegacySettlement: false),
    );
    if (result == null) {
      if (controller.investors.isEmpty) {
        widget.item.fundSource = FundSource.shop();
        controller.items.refresh();
      }
      return;
    }

    final investor = await controller.createInvestor(
      name: result.name,
      contact: result.contact,
      investmentType: result.investmentType,
      profitSharePercent: result.profitSharePercent,
      capitalReturnTermDays: result.capitalReturnTermDays,
      profitPayoutCycle: result.profitPayoutCycle,
      notes: result.notes,
    );
    if (investor == null || !context.mounted) {
      if (controller.investors.isEmpty) {
        widget.item.fundSource = FundSource.shop();
        controller.items.refresh();
      }
      return;
    }
    widget.item.fundSource = FundSource.investor(investor.id);
    controller.items.refresh();
  }
}

class _ReconciliationPreview extends GetView<PurchaseEntryController> {
  const _ReconciliationPreview();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.reconciliationPreview;
      if (preview == null) return const SizedBox.shrink();

      final actual = controller.actualCashTakenOut.value;
      final returned = controller.cashReturned.value;
      final totalSpent = preview.totalItemsCash + preview.transportCost + preview.otherCostsTotal;
      final netCashUsed = actual == null ? totalSpent : actual - returned;
      final balanceDiff = actual == null ? 0 : (netCashUsed.minorUnits - totalSpent.minorUnits);
      final isBalanced = actual != null && balanceDiff.abs() < 100; // within 1 taka

      final scheme = Theme.of(context).colorScheme;

      return Card(
        color: actual == null
            ? scheme.surfaceContainerHighest
            : isBalanced
                ? scheme.primaryContainer
                : balanceDiff > 0
                    ? Colors.blue.shade50
                    : Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Items Total
              Row(
                children: [
                  Text('itemsTotal'.tr),
                  const Spacer(),
                  Text(
                    preview.totalItemsCash.format(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              if (preview.transportCost.minorUnits > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text('transportTotal'.tr),
                    const Spacer(),
                    Text(
                      preview.transportCost.format(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],

              if (preview.otherCostsTotal.minorUnits > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text('otherCostsTotal'.tr),
                    const Spacer(),
                    Text(
                      preview.otherCostsTotal.format(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1),
              ),

              // Total Spent
              Row(
                children: [
                  Text(
                    'totalSpent'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    totalSpent.format(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),

              if (actual != null && actual.minorUnits > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text('cashTaken'.tr),
                    const Spacer(),
                    Text(actual.format()),
                  ],
                ),
                if (returned.minorUnits > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text('returnedCash'.tr),
                      const Spacer(),
                      Text('- ${returned.format()}'),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text('netCashUsed'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(netCashUsed.format(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Balance Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBalanced
                        ? Colors.green.shade100
                        : balanceDiff > 0
                            ? Colors.blue.shade100
                            : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBalanced
                            ? Icons.check_circle_outline
                            : balanceDiff > 0
                                ? Icons.account_balance_wallet_outlined
                                : Icons.info_outline,
                        size: 18,
                        color: isBalanced
                            ? Colors.green.shade800
                            : balanceDiff > 0
                                ? Colors.blue.shade900
                                : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isBalanced
                              ? 'cashBalanced'.tr
                              : balanceDiff > 0
                                  ? 'cashRemainingInHand'.trParams({
                                      'amount': Money.fromMinor(balanceDiff).format(),
                                    })
                                  : 'cashSpentFromExtra'.trParams({
                                      'amount': Money.fromMinor(-balanceDiff).format(),
                                    }),
                          key: const Key('purchase-reconciliation-status'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isBalanced
                                ? Colors.green.shade900
                                : balanceDiff > 0
                                    ? Colors.blue.shade900
                                    : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'enterActualCashForCheck'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],

              for (final bucket in preview.byFundSource)
                if (bucket.fundSource.isInvestor)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        Text('fundedByInvestor'.tr),
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
