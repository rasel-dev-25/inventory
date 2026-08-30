import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/services/rent_lifecycle.dart';
import '../controller/rent_controller.dart';

/// The v2 Rent screen — issue/return/stolen-escalation for book rentals,
/// per `notes/business_logic.md` §জ, backed by [RentController].
class RentScreen extends GetView<RentController> {
  const RentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'rent'.tr} (v2)')),
      body: Obx(() {
        final active = controller.activeRentals;
        final history = controller.history;
        if (active.isEmpty && history.isEmpty) {
          return Center(child: Text('noRentalsYet'.tr));
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'activeRentals'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('noRentalsYet'.tr),
              )
            else
              for (final rent in active) _ActiveRentCard(rent: rent),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'rentHistory'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final rent in history) _HistoryRow(rent: rent),
            ],
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'rent_fab',
        onPressed: () => _openIssueSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openIssueSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _IssueRentSheet(),
    );
  }
}

class _ActiveRentCard extends GetView<RentController> {
  final RentTransaction rent;
  const _ActiveRentCard({required this.rent});

  @override
  Widget build(BuildContext context) {
    final book = controller.productById(rent.bookProductId);
    final overdue = controller.rentIsOverdue(rent);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    book?.name ?? rent.bookProductId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (overdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'overdue'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              controller.customerName(rent.customerId),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${'startDate'.tr}: ${_fmt(rent.startDate)}   '
              '${'dueDate'.tr}: ${_fmt(rent.dueDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (overdue)
                  TextButton(
                    onPressed: () => _confirmMarkStolen(context),
                    child: Text(
                      'markStolen'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: () => _openReturnDialog(context),
                  child: Text('returnBook'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmMarkStolen(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('markStolen'.tr),
        content: Text('confirmMarkStolen'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('markStolen'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.markStolen(rent.id);
    }
  }

  Future<void> _openReturnDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ReturnRentDialog(rent: rent),
    );
  }

  String _fmt(DateTime d) => d.toLocal().toString().split(' ').first;
}

class _HistoryRow extends GetView<RentController> {
  final RentTransaction rent;
  const _HistoryRow({required this.rent});

  @override
  Widget build(BuildContext context) {
    final book = controller.productById(rent.bookProductId);
    final statusLabel = switch (rent.status) {
      RentStatus.returned => 'returnedLabel'.tr,
      RentStatus.treatedAsStolen => 'stolen'.tr,
      RentStatus.active => 'active'.tr,
      RentStatus.overdue => 'overdue'.tr,
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(book?.name ?? rent.bookProductId),
      subtitle: Text(controller.customerName(rent.customerId)),
      trailing: Text(statusLabel),
    );
  }
}

class _IssueRentSheet extends StatefulWidget {
  const _IssueRentSheet();

  @override
  State<_IssueRentSheet> createState() => _IssueRentSheetState();
}

class _IssueRentSheetState extends State<_IssueRentSheet> {
  final _formKey = GlobalKey<FormState>();
  RentController get controller => Get.find<RentController>();

  Product? _selectedBook;
  String? _selectedCustomerId;
  final _daysController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController(text: '0');

  @override
  void dispose() {
    _daysController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _onBookSelected(Product book) {
    setState(() {
      _selectedBook = book;
      final suggestion = controller.suggestedTierFor(book);
      if (suggestion != null) {
        _daysController.text = suggestion.days.toString();
        _priceController.text = suggestion.price.format(showSymbol: false);
      } else {
        _daysController.clear();
        _priceController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'issueRent'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<Product>(
                  initialValue: _selectedBook,
                  decoration: InputDecoration(labelText: 'selectBook'.tr),
                  items: [
                    for (final p in controller.rentableProducts)
                      DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p.name} (${'availableCopies'.tr}: '
                          '${controller.availableCopiesFor(p)})',
                        ),
                      ),
                  ],
                  onChanged: (v) => v == null ? null : _onBookSelected(v),
                  validator: (v) => v == null ? 'selectProduct'.tr : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  decoration: InputDecoration(labelText: 'customerName'.tr),
                  items: [
                    for (final c in controller.customers)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _selectedCustomerId = v),
                  validator: (v) => v == null ? 'nameRequired'.tr : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'days'.tr),
                        validator: (v) => int.tryParse(v ?? '') == null
                            ? 'invalidQty'.tr
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'rentPriceLabel'.tr,
                        ),
                        validator: (v) => _parseMoneyOrNull(v ?? '') == null
                            ? 'invalidQty'.tr
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _depositController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: 'deposit'.tr),
                  validator: (v) => _parseMoneyOrNull(v ?? '') == null
                      ? 'invalidQty'.tr
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      controller.errorMessage.value!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                FilledButton(
                  onPressed: controller.isSaving.value ? null : _submit,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('issueRent'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await controller.issueRent(
      bookProductId: _selectedBook!.id,
      customerId: _selectedCustomerId!,
      deposit: _parseMoneyOrNull(_depositController.text) ?? Money.zero(),
      days: int.tryParse(_daysController.text),
      rentPrice: _parseMoneyOrNull(_priceController.text),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ReturnRentDialog extends StatefulWidget {
  final RentTransaction rent;
  const _ReturnRentDialog({required this.rent});

  @override
  State<_ReturnRentDialog> createState() => _ReturnRentDialogState();
}

class _ReturnRentDialogState extends State<_ReturnRentDialog> {
  RentController get controller => Get.find<RentController>();
  late final _extraDayController = TextEditingController(
    text: controller
        .suggestedExtraDayChargeFor(widget.rent, DateTime.now())
        .format(showSymbol: false),
  );
  final _damageController = TextEditingController(text: '0');
  final _amountReceivedController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _formKey = GlobalKey<FormState>();

  Money? get _extraDayCharge => _parseMoneyOrNull(_extraDayController.text);
  Money? get _damageCharge => _parseMoneyOrNull(_damageController.text);

  ReturnSettlement? get _settlement {
    if (_extraDayCharge == null || _damageCharge == null) return null;
    return computeReturnSettlement(
      rentPrice: widget.rent.rentPrice,
      deposit: widget.rent.deposit,
      extraDayCharge: _extraDayCharge,
      damageCharge: _damageCharge,
    );
  }

  @override
  void dispose() {
    _extraDayController.dispose();
    _damageController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settlement = _settlement;
    return AlertDialog(
      title: Text('returnBook'.tr),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'depositLabel'.tr}: ${widget.rent.deposit.format()}'),
              Text('${'rentPriceLabel'.tr}: ${widget.rent.rentPrice.format()}'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _extraDayController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'extraDayCharge'.tr,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _damageController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'damageCharge'.tr),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
                    ),
                  ),
                ],
              ),
              if (settlement != null) ...[
                const SizedBox(height: AppSpacing.md),
                if (settlement.refundOwed)
                  Text(
                    '${'refundOwed'.tr}: ${settlement.refundAmount.format()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (settlement.customerOwes)
                  Text(
                    '${'netAmountOwed'.tr}: ${settlement.netAmount.format()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    '${'netAmountOwed'.tr}: ${settlement.netAmount.format()}',
                  ),
              ],
              if (settlement != null && settlement.customerOwes) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountReceivedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: 'cashAmount'.tr),
                  validator: (v) => _parseMoneyOrNull(v ?? '') == null
                      ? 'invalidQty'.tr
                      : null,
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
                  selected: {_paymentMethod},
                  onSelectionChanged: (s) =>
                      setState(() => _paymentMethod = s.first),
                ),
              ],
              Obx(
                () => controller.errorMessage.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        Obx(
          () => FilledButton(
            onPressed: controller.isSaving.value ? null : _submit,
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('returnBook'.tr),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final settlement = _settlement!;
    final amountReceivedNow = settlement.customerOwes
        ? (_parseMoneyOrNull(_amountReceivedController.text) ?? Money.zero())
        : Money.zero();
    final ok = await controller.returnRent(
      rentId: widget.rent.id,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: _paymentMethod,
      extraDayCharge: _extraDayCharge,
      damageCharge: _damageCharge,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
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
