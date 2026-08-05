import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/platform/capabilities.dart';
import '../../../core/widgets/barcode_scanner_view.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/barcode_lookup.dart';
import '../controller/daily_sales_controller.dart';

/// The Daily Sales screen — product autosuggest, qty/price entry, the
/// cash/due payment-method router, and a live gross-profit preview
/// (`notes/business_logic.md` §গ / §ঘ), backed by
/// [DailySalesController.logSale] → `SaveSaleUseCase`. One of the 5
/// screens `ShellScreen` embeds directly — see [DashboardScreen]'s own
/// doc comment for why [onMenuTap] exists.
class DailySalesScreen extends GetView<DailySalesController> {
  final VoidCallback? onMenuTap;

  const DailySalesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dailySales'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return Center(child: Text('noProductsYet'.tr));
        }
        return const _SaleForm();
      }),
    );
  }
}

class _SaleForm extends GetView<DailySalesController> {
  const _SaleForm();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaleFormBody(),
          const SizedBox(height: AppSpacing.xl),
          _RecentSalesList(),
        ],
      ),
    );
  }
}

class _SaleFormBody extends StatefulWidget {
  @override
  State<_SaleFormBody> createState() => _SaleFormBodyState();
}

class _SaleFormBodyState extends State<_SaleFormBody> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _receivedController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _selectedCustomerId;
  final _promisedDaysController = TextEditingController();

  /// Owned explicitly (rather than letting [Autocomplete] manage its own
  /// internal controller) so a successful barcode scan can update the
  /// visible search text to the matched product's name — otherwise the
  /// field would still show whatever was last typed (usually nothing)
  /// even though [_selectedProduct] was set, which would look broken.
  /// [Autocomplete] requires [_searchFocusNode] alongside it once a
  /// controller is supplied.
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  DailySalesController get controller => Get.find<DailySalesController>();

  double get _qty => double.tryParse(_qtyController.text) ?? 0;
  Money? get _price => _parseMoneyOrNull(_priceController.text);
  Money? get _received => _parseMoneyOrNull(_receivedController.text);

  Money get _saleTotal => (_price ?? Money.zero()) * _qty;
  Money get _remaining => _saleTotal - (_received ?? Money.zero());
  Money? get _grossProfitPreview {
    if (_selectedProduct == null || _price == null) return null;
    return (_price! - _selectedProduct!.costPrice) * _qty;
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
      _searchController.text = product.name;
      _priceController.text = product.suggestedSellPrice.format(
        showSymbol: false,
      );
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _receivedController.dispose();
    _promisedDaysController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Autocomplete<Product>(
                        textEditingController: _searchController,
                        focusNode: _searchFocusNode,
                        displayStringForOption: (p) => p.name,
                        optionsBuilder: (textValue) {
                          if (textValue.text.isEmpty)
                            return controller.products;
                          final query = textValue.text.toLowerCase();
                          return controller.products.where(
                            (p) =>
                                p.name.toLowerCase().contains(query) ||
                                p.category.toLowerCase().contains(query),
                          );
                        },
                        onSelected: (product) {
                          setState(() {
                            _selectedProduct = product;
                            _priceController.text = product.suggestedSellPrice
                                .format(showSymbol: false);
                          });
                        },
                        fieldViewBuilder:
                            (context, textController, focusNode, onSubmit) {
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'searchProductAdd'.tr,
                                ),
                                validator: (_) => _selectedProduct == null
                                    ? 'selectProduct'.tr
                                    : null,
                              );
                            },
                      ),
                    ),
                    if (PlatformCapabilities.detect().hasCamera)
                      IconButton(
                        tooltip: 'scanBarcodeTitle'.tr,
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () => _scanBarcode(context),
                      ),
                  ],
                ),
              ),
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${'stockLabel'.tr}${_selectedProduct!.qty}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'qty'.tr),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (_qty <= 0) ? 'invalidQty'.tr : null,
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
                        labelText: 'sellPriceLabel'.tr,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (_price == null) ? 'invalidQty'.tr : null,
                    ),
                  ),
                ],
              ),
              if (_grossProfitPreview != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '${'profit'.tr}: ${_grossProfitPreview!.format()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _grossProfitPreview!.isNegative
                          ? Theme.of(context).colorScheme.error
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _receivedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'cashAmount'.tr,
                  helperText: _remaining.isPositive
                      ? '${'dueAmount'.tr}: ${_remaining.format()}'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_remaining.isPositive) ...[
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: InputDecoration(labelText: 'customerName'.tr),
                    items: [
                      for (final c in controller.customers)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
                    validator: (v) => (_remaining.isPositive && v == null)
                        ? 'nameRequired'.tr
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _promisedDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'enterDueDay'.tr),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Obx(() => errorMessageText(controller.errorMessage.value)),
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
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await controller.logSale(
      productId: _selectedProduct!.id,
      qty: _qty,
      actualSellPrice: _price!,
      amountReceivedNow: _received ?? Money.zero(),
      paymentMethod: _paymentMethod,
      customerId: _selectedCustomerId,
      promisedDays: int.tryParse(_promisedDaysController.text),
    );
    if (ok && mounted) {
      setState(() {
        _selectedProduct = null;
        _qtyController.text = '1';
        _priceController.clear();
        _receivedController.clear();
        _selectedCustomerId = null;
        _promisedDaysController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('paymentSaved'.tr)));
    }
  }
}

class _RecentSalesList extends GetView<DailySalesController> {
  const _RecentSalesList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recentSales.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('sales'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final sale in controller.recentSales.take(20))
            ListTile(
              title: Text(
                controller.productById(sale.productId)?.name ?? sale.productId,
              ),
              subtitle: Text('${sale.qty} x ${sale.actualSellPrice.format()}'),
              trailing: Text(
                (sale.actualSellPrice * sale.qty).format(),
                style: TextStyle(
                  color: sale.paymentStatus == PaymentStatus.fullCash
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// Shared tiny helper, same shape as `sign_in_screen.dart`'s `errorText`
/// — not reused directly to avoid pulling an auth-feature import into
/// this feature for one widget.
Widget errorMessageText(String? message) {
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

/// `Money` has no `tryParse` — `Money.parse` is the one sanctioned
/// text-input entry point and throws [MoneyException] on malformed
/// input (see its own doc comment), so every form field in this app
/// that reads a live [Money] value while the user is still typing wraps
/// it exactly like this — same pattern as `purchase_entry_screen.dart`'s
/// `_MoneyField`.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
