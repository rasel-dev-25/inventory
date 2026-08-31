import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/money/money.dart';
import '../../../../core/platform/capabilities.dart';
import '../../../../core/widgets/barcode_scanner_view.dart';
import '../../../../core/widgets/calculator_keypad.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/services/barcode_lookup.dart';
import '../../controller/daily_sales_controller.dart';
import 'sale_customer_section.dart';

/// Bottom Sheet for creating a new Sale.
class SaleFormSheet extends StatefulWidget {
  const SaleFormSheet({super.key});

  @override
  State<SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<SaleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _selectedCategory;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _receivedController = TextEditingController();
  String _paymentMode = 'cash';
  String? _selectedCustomerId;
  DateTime? _promisedDate;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String? _activeCalculatorField;

  DailySalesController get controller => Get.find<DailySalesController>();

  PaymentMethod get _paymentMethod {
    if (_paymentMode == 'mobile') return PaymentMethod.mobileBanking;
    if (_paymentMode == 'bank') return PaymentMethod.bankTransfer;
    return PaymentMethod.cash;
  }

  bool get _isDueSale => _paymentMode == 'due';

  double get _qty => double.tryParse(_qtyController.text) ?? 1;
  Money? get _price => _parseMoneyOrNull(_priceController.text);
  Money? get _received => _parseMoneyOrNull(_receivedController.text);

  Money get _saleTotal => (_price ?? Money.zero()) * _qty;
  Money get _effectiveReceived =>
      _isDueSale ? (_received ?? Money.zero()) : _saleTotal;
  Money get _remaining =>
      _isDueSale ? (_saleTotal - _effectiveReceived) : Money.zero();
  Money? get _grossProfitPreview {
    if (_selectedProduct == null || _price == null) return null;
    return (_price! - _selectedProduct!.costPrice) * _qty;
  }

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

  Future<void> _showSearchProductDialog(BuildContext context) async {
    _setActiveField(null);
    final theme = Theme.of(context);
    final searchCtrl = TextEditingController();

    final Product? picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final allFiltered = controller.products.where((p) {
              final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
              final matchesQuery = query.isEmpty ||
                  p.name.toLowerCase().contains(query) ||
                  p.category.toLowerCase().contains(query) ||
                  (p.barcode != null && p.barcode!.toLowerCase().contains(query));
              return matchesCategory && matchesQuery;
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'searchProductAdd'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'searchProductAdd'.tr,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: allFiltered.isEmpty
                        ? Center(child: Text('noProductsYet'.tr))
                        : ListView.separated(
                            itemCount: allFiltered.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final p = allFiltered[index];
                              final unitName = p.sellUnit.isNotEmpty ? p.sellUnit : p.unit;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Text(
                                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('${p.category} • ${'stockLabel'.tr}${p.qty} $unitName'),
                                trailing: Text(
                                  p.suggestedSellPrice.format(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => Navigator.of(ctx).pop(p),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedProduct = picked;
        _selectedCategory = picked.category;
        _priceController.text = picked.suggestedSellPrice.format(showSymbol: false);
        if (_isDueSale) {
          _receivedController.text = '0';
        } else {
          _receivedController.text = (picked.suggestedSellPrice * _qty).format(showSymbol: false);
        }
        _setActiveField(null);
      });
    }
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final code = await showBarcodeScanner(context);
    if (code == null || !context.mounted) return;

    final product = findProductByBarcode(controller.products, code);
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('noProductForBarcode'.tr)));
      return;
    }

    setState(() {
      _selectedProduct = product;
      _selectedCategory = product.category;
      _priceController.text = product.suggestedSellPrice.format(showSymbol: false);
      if (_isDueSale) {
        _receivedController.text = '0';
      } else {
        _receivedController.text = (product.suggestedSellPrice * _qty).format(showSymbol: false);
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

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _receivedController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    finalizeCalculatorController(_qtyController);
    finalizeCalculatorController(_priceController);
    if (_isDueSale) finalizeCalculatorController(_receivedController);

    if (!_formKey.currentState!.validate()) return;
    if (_isDueSale &&
        _remaining.isPositive &&
        (_selectedCustomerId == null || _selectedCustomerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('customerRequiredForDue'.tr),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    final total = (_price ?? Money.zero()) * _qty;
    final amountReceived = _isDueSale
        ? (_parseMoneyOrNull(_receivedController.text) ?? Money.zero())
        : total;

    int? promisedDays;
    if (_isDueSale && _promisedDate != null) {
      final saleDate = controller.selectedDate.value;
      final diff = _promisedDate!.difference(
        DateTime(saleDate.year, saleDate.month, saleDate.day),
      ).inDays;
      promisedDays = diff > 0 ? diff : 1;
    }
    final ok = await controller.logSale(
      productId: _selectedProduct!.id,
      qty: _qty,
      actualSellPrice: _price!,
      amountReceivedNow: amountReceived,
      paymentMethod: _paymentMethod,
      customerId: _selectedCustomerId,
      promisedDays: _isDueSale ? promisedDays : null,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('paymentSaved'.tr)),
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

    final unitName = _selectedProduct == null
        ? 'unitPcs'.tr
        : (_selectedProduct!.sellUnit.isNotEmpty
            ? _selectedProduct!.sellUnit
            : _selectedProduct!.unit);

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'addSale'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'category'.tr,
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('allCategories'.tr),
                ),
                for (final category in {
                  for (final product in controller.products) product.category,
                })
                  DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                  if (_selectedProduct != null &&
                      _selectedCategory != null &&
                      _selectedProduct!.category != _selectedCategory) {
                    _selectedProduct = null;
                    _priceController.clear();
                    _receivedController.clear();
                  }
                  _setActiveField(null);
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${_selectedCategory}_${_selectedProduct?.id}'),
                    initialValue: _selectedProduct?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'selectProduct'.tr,
                      prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                    ),
                    items: [
                      for (final p in controller.products.where((p) =>
                          _selectedCategory == null || p.category == _selectedCategory))
                        DropdownMenuItem<String>(
                          value: p.id,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${p.suggestedSellPrice.format()} • ${p.qty} ${p.sellUnit.isNotEmpty ? p.sellUnit : p.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (productId) {
                      if (productId != null) {
                        final product = controller.productById(productId);
                        if (product != null) {
                          setState(() {
                            _selectedProduct = product;
                            _selectedCategory ??= product.category;
                            _priceController.text = product.suggestedSellPrice.format(showSymbol: false);
                            if (_isDueSale) {
                              _receivedController.text = '0';
                            } else {
                              _receivedController.text = (product.suggestedSellPrice * _qty).format(showSymbol: false);
                            }
                            _setActiveField(null);
                          });
                        }
                      }
                    },
                    validator: (_) => _selectedProduct == null ? 'selectProduct'.tr : null,
                  ),
                ),
                IconButton(
                  tooltip: 'searchProductAdd'.tr,
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchProductDialog(context),
                ),
                if (PlatformCapabilities.detect().hasCamera)
                  IconButton(
                    tooltip: 'scanBarcodeTitle'.tr,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _scanBarcode(context),
                  ),
              ],
            ),
            if (_selectedProduct != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${'stockLabel'.tr}${_selectedProduct!.qty} $unitName',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // Quantity & Sell Price via interactive CalculatorFieldCards
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
            if (_grossProfitPreview != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '${'profit'.tr}: ${_grossProfitPreview!.format()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _grossProfitPreview!.isNegative ? theme.colorScheme.error : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

            // Amount Received / Cash Amount
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
              helperText: _isDueSale && _remaining.isPositive
                  ? '${'dueAmount'.tr}: ${_remaining.format()}'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SaleCustomerSection(
              controller: controller,
              selectedCustomerId: _selectedCustomerId,
              isRequired: _isDueSale && _remaining.isPositive,
              onCustomerChanged: (v) {
                setState(() => _selectedCustomerId = v);
                _setActiveField(null);
              },
              onClearFocus: () => _setActiveField(null),
            ),
            if (_isDueSale && _remaining.isPositive) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDueDatePicker(context),
            ],
            const SizedBox(height: AppSpacing.lg),
            Obx(() => _errorMessageText(controller.errorMessage.value)),

            // Save / Complete Sale button — shown only when keypad is NOT visible
            if (!keypadVisible) ...[
              const SizedBox(height: AppSpacing.sm),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSaving.value ? null : _submit,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('completeSale'.tr),
                ),
              ),
            ],
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

Widget _errorMessageText(String? message) {
  return SizedBox(
    height: 20,
    child: message == null
        ? null
        : Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
  );
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
