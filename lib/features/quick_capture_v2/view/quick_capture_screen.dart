import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/quick_capture.dart';
import '../controller/quick_capture_controller.dart';

/// The v2 Quick Capture screen — jot now, formalize later, per
/// `notes/business_logic.md`'s QuickCapture addition, backed by
/// [QuickCaptureController].
class QuickCaptureScreen extends GetView<QuickCaptureController> {
  const QuickCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'quickCaptures'.tr} (v2)')),
      body: Obx(() {
        final pending = controller.pending;
        final converted = controller.converted;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('pending'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('noPendingCaptures'.tr),
              )
            else
              for (final capture in pending) _PendingCard(capture: capture),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'converted'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (converted.isEmpty)
              Text('noConvertedCaptures'.tr)
            else
              for (final capture in converted) _ConvertedRow(capture: capture),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    QuickCaptureType type = QuickCaptureType.voiceNote;
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('quickCaptures'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<QuickCaptureType>(
                      segments: [
                        ButtonSegment(
                          value: QuickCaptureType.voiceNote,
                          label: Text('voiceNote'.tr),
                        ),
                        ButtonSegment(
                          value: QuickCaptureType.photoNote,
                          label: Text('photoNote'.tr),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setState(() => type = s.first),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: noteController,
                      autofocus: true,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'writeQuickNote'.tr,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'nameRequired'.tr
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.createCapture(
                      type: type,
                      note: noteController.text,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
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
}

class _PendingCard extends GetView<QuickCaptureController> {
  final QuickCapture capture;
  const _PendingCard({required this.capture});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  capture.type == QuickCaptureType.voiceNote
                      ? Icons.mic
                      : Icons.photo,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(capture.fileLocalPath)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _openConvertChoice(context),
                child: Text('convertTo'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openConvertChoice(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: Text('dailySales'.tr),
              onTap: () => Navigator.of(context).pop('sale'),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text('purchaseEntry'.tr),
              onTap: () => Navigator.of(context).pop('purchase'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('expenses'.tr),
              onTap: () => Navigator.of(context).pop('expense'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'sale':
        await _openSaleForm(context);
      case 'purchase':
        await _openPurchaseForm(context);
      case 'expense':
        await _openExpenseForm(context);
    }
  }

  Future<void> _openExpenseForm(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: capture.fileLocalPath,
    );
    ExpenseCategory category = ExpenseCategory.dailyOther;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('addExpense'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<ExpenseCategory>(
                        segments: [
                          ButtonSegment(
                            value: ExpenseCategory.monthlyRent,
                            label: Text('monthlyRent'.tr),
                          ),
                          ButtonSegment(
                            value: ExpenseCategory.dailyOther,
                            label: Text('dailyOther'.tr),
                          ),
                        ],
                        selected: {category},
                        onSelectionChanged: (s) =>
                            setState(() => category = s.first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: amountController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: 'amount'.tr),
                        validator: (v) => _parseMoneyOrNull(v ?? '') == null
                            ? 'invalidQty'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'description'.tr,
                        ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToExpense(
                      captureId: capture.id,
                      category: category,
                      amount: _parseMoneyOrNull(amountController.text)!,
                      paymentMethod: method,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
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

  Future<void> _openSaleForm(BuildContext context) async {
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final receivedController = TextEditingController();
    String? customerId;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('dailySales'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: productId,
                          decoration: InputDecoration(
                            labelText: 'selectProduct'.tr,
                          ),
                          items: [
                            for (final p in controller.products)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            productId = v;
                            final product = controller.productById(v ?? '');
                            if (product != null &&
                                priceController.text.isEmpty) {
                              priceController.text = product.suggestedSellPrice
                                  .format(showSymbol: false);
                            }
                          }),
                          validator: (v) =>
                              v == null ? 'selectProduct'.tr : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(labelText: 'qty'.tr),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'sellPriceLabel'.tr,
                              ),
                              validator: (v) =>
                                  _parseMoneyOrNull(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: receivedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: 'cashAmount'.tr),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: customerId,
                          decoration: InputDecoration(
                            labelText: 'customerName'.tr,
                          ),
                          items: [
                            for (final c in controller.customers)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => customerId = v),
                        ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToSale(
                      captureId: capture.id,
                      productId: productId!,
                      qty: double.parse(qtyController.text),
                      actualSellPrice: _parseMoneyOrNull(priceController.text)!,
                      amountReceivedNow:
                          _parseMoneyOrNull(receivedController.text) ??
                          Money.zero(),
                      paymentMethod: method,
                      customerId: customerId,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
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

  Future<void> _openPurchaseForm(BuildContext context) async {
    final shopNameController = TextEditingController();
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    bool fundedByInvestor = false;
    String? investorId;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('purchaseEntry'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: shopNameController,
                        decoration: InputDecoration(
                          labelText: 'shopNameLabel'.tr,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'nameRequired'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: productId,
                          decoration: InputDecoration(
                            labelText: 'selectProduct'.tr,
                          ),
                          items: [
                            for (final p in controller.products)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => productId = v),
                          validator: (v) =>
                              v == null ? 'selectProduct'.tr : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(labelText: 'qty'.tr),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'buyPricePer'.tr,
                              ),
                              validator: (v) =>
                                  _parseMoneyOrNull(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('fundedByInvestor'.tr),
                        value: fundedByInvestor,
                        onChanged: (v) => setState(() => fundedByInvestor = v),
                      ),
                      if (fundedByInvestor)
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: investorId,
                            decoration: InputDecoration(
                              labelText: 'selectInvestor'.tr,
                            ),
                            items: [
                              for (final i in controller.investors)
                                DropdownMenuItem(
                                  value: i.id,
                                  child: Text(i.name),
                                ),
                            ],
                            onChanged: (v) => setState(() => investorId = v),
                            validator: (v) => (fundedByInvestor && v == null)
                                ? 'nameRequired'.tr
                                : null,
                          ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToPurchase(
                      captureId: capture.id,
                      shopName: shopNameController.text.trim(),
                      productId: productId!,
                      qty: double.parse(qtyController.text),
                      unitPrice: _parseMoneyOrNull(priceController.text)!,
                      fundSource: fundedByInvestor
                          ? FundSource.investor(investorId!)
                          : FundSource.shop(),
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
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
}

class _ConvertedRow extends StatelessWidget {
  final QuickCapture capture;
  const _ConvertedRow({required this.capture});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        capture.type == QuickCaptureType.voiceNote ? Icons.mic : Icons.photo,
        size: 18,
      ),
      title: Text(capture.fileLocalPath),
      trailing: Text(capture.convertedToType ?? ''),
    );
  }
}

/// Same pattern as every other v2 form field — `Money` has no `tryParse`,
/// see `daily_sales_v2`'s doc comment for why every live-input field
/// wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
