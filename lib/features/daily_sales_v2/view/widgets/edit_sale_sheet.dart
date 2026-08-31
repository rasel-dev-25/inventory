import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/calculator_keypad.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/sale.dart';
import '../../controller/daily_sales_controller.dart';
import 'sale_customer_section.dart';

/// Bottom Sheet for editing an existing Sale with custom calculator keypad.
class EditSaleSheet extends StatefulWidget {
  final Sale sale;
  const EditSaleSheet({required this.sale, super.key});

  @override
  State<EditSaleSheet> createState() => _EditSaleSheetState();
}

class _EditSaleSheetState extends State<EditSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _receivedController;
  late String? _selectedCustomerId;
  String _paymentMode = 'cash';
  DateTime? _promisedDate;

  String? _activeCalculatorField;

  DailySalesController get controller => Get.find<DailySalesController>();

  PaymentMethod get _paymentMethod {
    if (_paymentMode == 'mobile') return PaymentMethod.mobileBanking;
    if (_paymentMode == 'bank') return PaymentMethod.bankTransfer;
    return PaymentMethod.cash;
  }

  bool get _isDueSale => _paymentMode == 'due';

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    _qtyController = TextEditingController(
      text: sale.qty.toStringAsFixed(sale.qty == sale.qty.roundToDouble() ? 0 : 2),
    );
    _priceController = TextEditingController(
      text: sale.actualSellPrice.format(showSymbol: false),
    );
    _selectedCustomerId = sale.customerId;

    final existingDue = controller.dues.firstWhereOrNull(
      (d) => d.sourceType == DueSourceType.sale && d.sourceId == sale.id,
    );

    if (existingDue != null && existingDue.status != DueStatus.paid) {
      _paymentMode = 'due';
      _receivedController = TextEditingController(
        text: controller.cashReceivedForSale(sale).format(showSymbol: false),
      );
    } else {
      if (sale.paymentMethod == PaymentMethod.mobileBanking) {
        _paymentMode = 'mobile';
      } else if (sale.paymentMethod == PaymentMethod.bankTransfer) {
        _paymentMode = 'bank';
      } else {
        _paymentMode = 'cash';
      }
      _receivedController = TextEditingController();
    }

    if (existingDue?.promisedDays != null) {
      _promisedDate = sale.date.add(Duration(days: existingDue!.promisedDays!));
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyController.text) ?? widget.sale.qty;
  Money? get _price => _parseMoneyOrNull(_priceController.text);
  Money? get _received => _parseMoneyOrNull(_receivedController.text);
  Money get _total => (_price ?? widget.sale.actualSellPrice) * _qty;
  Money get _effectiveReceived =>
      _isDueSale ? (_received ?? Money.zero()) : _total;
  Money get _due => _isDueSale ? (_total - _effectiveReceived) : Money.zero();

  void _setActiveField(String? field) {
    if (_activeCalculatorField != field) {
      if (_activeCalculatorField != null) {
        if (_activeCalculatorField == 'qty') finalizeCalculatorController(_qtyController);
        if (_activeCalculatorField == 'price') finalizeCalculatorController(_priceController);
        if (_activeCalculatorField == 'received') finalizeCalculatorController(_receivedController);
      }
      setState(() => _activeCalculatorField = field);
      if (field != null) {
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _onCalculatorKeyPress(String key) {
    if (_activeCalculatorField == null) return;
    setState(() {
      if (_activeCalculatorField == 'qty') {
        applyCalculatorKeyToController(_qtyController, key);
        if (!_isDueSale && _price != null) {
          _receivedController.text = (_price! * _qty).format(showSymbol: false);
        }
      } else if (_activeCalculatorField == 'price') {
        applyCalculatorKeyToController(_priceController, key);
        if (!_isDueSale && _price != null) {
          _receivedController.text = (_price! * _qty).format(showSymbol: false);
        }
      } else if (_activeCalculatorField == 'received') {
        applyCalculatorKeyToController(_receivedController, key);
        if (!_isDueSale && _qty > 0 && _received != null) {
          final unitPrice = Money.fromMinor((_received!.minorUnits / _qty).round());
          _priceController.text = unitPrice.format(showSymbol: false);
        }
      }
    });
  }

  Future<void> _pickDueDate(BuildContext context) async {
    _setActiveField(null);
    final now = DateTime.now();
    final initial = _promisedDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _promisedDate = picked);
    }
  }

  Widget _buildDueDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _promisedDate != null
        ? DateFormat('d MMM yyyy').format(_promisedDate!)
        : 'selectDueDate'.tr;
    final daysRemaining = _promisedDate?.difference(DateTime.now()).inDays;

    return InkWell(
      onTap: () => _pickDueDate(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _promisedDate != null
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: _promisedDate != null
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'promisedPaymentDate'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _promisedDate != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (daysRemaining != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  daysRemaining > 0
                      ? '$daysRemaining ${'daysLater'.tr}'
                      : (daysRemaining == 0 ? 'today'.tr : 'overdue'.tr),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            if (_promisedDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: 'clear'.tr,
                onPressed: () => setState(() => _promisedDate = null),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    finalizeCalculatorController(_qtyController);
    finalizeCalculatorController(_priceController);
    if (_isDueSale) finalizeCalculatorController(_receivedController);

    if (!_formKey.currentState!.validate()) return;
    if (_isDueSale &&
        _due.isPositive &&
        (_selectedCustomerId == null || _selectedCustomerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('customerRequiredForDue'.tr),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    int? promisedDays;
    if (_isDueSale && _promisedDate != null) {
      final saleDate = widget.sale.date;
      final diff = _promisedDate!.difference(
        DateTime(saleDate.year, saleDate.month, saleDate.day),
      ).inDays;
      promisedDays = diff > 0 ? diff : 1;
    }
    final amountReceived = _isDueSale
        ? (_parseMoneyOrNull(_receivedController.text) ?? Money.zero())
        : _total;
    final ok = await controller.editSale(
      saleId: widget.sale.id,
      qty: double.parse(_qtyController.text),
      actualSellPrice: Money.parse(_priceController.text),
      amountReceivedNow: amountReceived,
      paymentMethod: _paymentMethod,
      customerId: _selectedCustomerId,
      promisedDays: _isDueSale ? promisedDays : null,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('saleUpdated'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keypadVisible = _activeCalculatorField != null;
    final product = controller.productById(widget.sale.productId);
    final unitName = product == null
        ? 'unitPcs'.tr
        : (product.sellUnit.isNotEmpty ? product.sellUnit : product.unit);

    final formContent = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: keypadVisible
            ? AppSpacing.sm
            : (bottomInset > 0 ? bottomInset + AppSpacing.xl : AppSpacing.lg),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'editSale'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product?.name ?? widget.sale.productId,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: CalculatorFieldCard(
                    label: '${'quantity'.tr} ($unitName)',
                    value: _qtyController.text,
                    isSelected: _activeCalculatorField == 'qty',
                    onTap: () => _setActiveField('qty'),
                    prefixText: '',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CalculatorFieldCard(
                    label: '${'sellPriceLabel'.tr} / $unitName',
                    value: _priceController.text,
                    isSelected: _activeCalculatorField == 'price',
                    onTap: () => _setActiveField('price'),
                    prefixText: '৳ ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 'cash',
                  label: Text('cash'.tr),
                ),
                ButtonSegment(
                  value: 'due',
                  label: Text('due'.tr),
                ),
                ButtonSegment(
                  value: 'mobile',
                  label: Text('mobile'.tr),
                ),
                ButtonSegment(
                  value: 'bank',
                  label: Text('bank'.tr),
                ),
              ],
              selected: {_paymentMode},
              onSelectionChanged: (s) {
                setState(() {
                  _paymentMode = s.first;
                  if (_paymentMode == 'due') {
                    _receivedController.text = '0';
                  } else {
                    if (_price != null) {
                      _receivedController.text = (_price! * _qty).format(showSymbol: false);
                    }
                    _promisedDate = null;
                  }
                  _setActiveField(null);
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            CalculatorFieldCard(
              label: _paymentMode == 'cash'
                  ? 'cashAmount'.tr
                  : (_paymentMode == 'due'
                      ? 'cashReceived'.tr
                      : (_paymentMode == 'mobile' ? 'mobile'.tr : 'bank'.tr)),
              value: _receivedController.text,
              isSelected: _activeCalculatorField == 'received',
              onTap: () => _setActiveField('received'),
              prefixText: '৳ ',
              helperText: _isDueSale && _due.isPositive
                  ? '${'due'.tr}: ${_due.format()}'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SaleCustomerSection(
              controller: controller,
              selectedCustomerId: _selectedCustomerId,
              isRequired: _isDueSale && _due.isPositive,
              onCustomerChanged: (v) {
                setState(() => _selectedCustomerId = v);
                _setActiveField(null);
              },
              onClearFocus: () => _setActiveField(null),
            ),
            if (_isDueSale && _due.isPositive) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDueDatePicker(context),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!keypadVisible)
              FilledButton(
                onPressed: _submit,
                child: Text('save'.tr),
              ),
          ],
        ),
      ),
    );

    final sheetDecoration = BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );

    if (keypadVisible) {
      String barLabel = 'calculator'.tr;
      String currentText = '';
      String prefix = '৳ ';

      if (_activeCalculatorField == 'qty') {
        barLabel = '${'quantity'.tr} ($unitName)';
        currentText = _qtyController.text;
        prefix = '';
      } else if (_activeCalculatorField == 'price') {
        barLabel = 'sellPriceLabel'.tr;
        currentText = _priceController.text;
        prefix = '৳ ';
      } else if (_activeCalculatorField == 'received') {
        barLabel = 'amountReceived'.tr;
        currentText = _receivedController.text;
        prefix = '৳ ';
      }

      return SizedBox(
        height: screenHeight * 0.92,
        child: Container(
          decoration: sheetDecoration,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setActiveField(null),
                    behavior: HitTestBehavior.translucent,
                    child: formContent,
                  ),
                ),
                InPlaceCalculatorBar(
                  label: barLabel,
                  currentText: currentText,
                  prefixText: prefix,
                  onDone: () => _setActiveField(null),
                ),
                CalculatorKeypad(onKeyPress: _onCalculatorKeyPress),
              ],
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: sheetDecoration,
        child: SafeArea(top: false, child: formContent),
      ),
    );
  }
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
