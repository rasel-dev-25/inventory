import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/barcode_scanner_view.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/pricing_engine.dart';

/// What [ProductFormSheet] hands back on save — [CatalogScreen] / [StockScreen] decides
/// whether that means a create or an update, since only it knows whether
/// [ProductFormSheet.existing] was passed.
class ProductFormResult {
  final String name;
  final String category;
  final Money costPrice;
  final Money suggestedSellPrice;
  final FundSource fundSource;
  final bool isRentable;
  final double initialQty;
  final String? barcode;
  final String? sku;
  final int? pageCount;
  final String? photoLocalPath;

  const ProductFormResult({
    required this.name,
    required this.category,
    required this.costPrice,
    required this.suggestedSellPrice,
    required this.fundSource,
    required this.isRentable,
    this.initialQty = 0,
    this.barcode,
    this.sku,
    this.pageCount,
    this.photoLocalPath,
  });
}

/// Create/edit form for a single [Product]. Pure form state — validation
/// and the actual create/update call both live in [CatalogController]/[StockController],
/// this widget only ever returns a [ProductFormResult] via
/// `Navigator.pop`.
class ProductFormSheet extends StatefulWidget {
  final Product? existing;
  final List<String> categories;
  final List<Investor> investors;
  final Future<String?> Function(String name)? onCreateCategory;
  final Future<String?> Function()? onCapturePhoto;
  final String? existingPhotoPath;

  /// Null hides the suggestion entirely — see `computeOverheadMarkupPercent`
  /// (`pricing_engine.dart`) for the exact conditions (the pricing
  /// engine's bootstrap period, or no usable revenue estimate yet).
  final double? overheadMarkupPercent;

  const ProductFormSheet({
    required this.categories,
    required this.investors,
    super.key,
    this.onCreateCategory,
    this.existing,
    this.overheadMarkupPercent,
    this.onCapturePhoto,
    this.existingPhotoPath,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  static const _shopFundValue = '__shop__';
  final _formKey = GlobalKey<FormState>();

  late final _nameController = TextEditingController(
    text: widget.existing?.name,
  );
  late final _costController = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.costPrice.format(showSymbol: false),
  );
  late final _priceController = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.suggestedSellPrice.format(showSymbol: false),
  );
  late final _initialQtyController = TextEditingController(
    text: widget.existing == null
        ? '0'
        : widget.existing!.qty.toStringAsFixed(
            widget.existing!.qty == widget.existing!.qty.roundToDouble() ? 0 : 2,
          ),
  );
  late final _barcodeController = TextEditingController(
    text: widget.existing?.barcode,
  );
  late final _skuController = TextEditingController(
    text: widget.existing?.sku,
  );
  late final _pageCountController = TextEditingController(
    text: widget.existing?.pageCount?.toString() ?? '',
  );

  late String? _category =
      widget.existing?.category ?? (widget.categories.firstOrNull);
  late final List<String> _categories = [...widget.categories];
  late String _fundSourceValue =
      widget.existing?.fundSource.investorId ?? _shopFundValue;
  late String? _photoLocalPath = widget.existingPhotoPath;
  late bool _isRentable = widget.existing?.isRentable ?? false;

  @override
  void initState() {
    super.initState();
    _costController.addListener(_onCostChanged);
  }

  void _onCostChanged() => setState(() {});

  Future<void> _createCategoryInline() async {
    var enteredName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('addCategory'.tr),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(labelText: 'categoryName'.tr),
          onChanged: (value) => enteredName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(enteredName.trim()),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name.isEmpty) return;
    final created = await widget.onCreateCategory!(name);
    if (created != null && mounted) {
      setState(() {
        if (!_categories.contains(created)) _categories.add(created);
        _category = created;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final photoPath = await widget.onCapturePhoto?.call();
    if (photoPath != null && mounted) {
      setState(() => _photoLocalPath = photoPath);
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await showBarcodeScanner(context);
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = scanned;
      });
    }
  }

  @override
  void dispose() {
    _costController.removeListener(_onCostChanged);
    _nameController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _initialQtyController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }

  Money? get _suggestedSellPrice {
    final markup = widget.overheadMarkupPercent;
    if (markup == null) return null;
    final cost = _parseMoneyOrNull(_costController.text);
    if (cost == null) return null;

    final fundSource = _fundSourceValue == _shopFundValue
        ? FundSource.shop()
        : FundSource.investor(_fundSourceValue);

    final investor = fundSource.isInvestor
        ? widget.investors
              .where((i) => i.id == fundSource.investorId)
              .firstOrNull
        : null;

    return suggestSellPrice(
      costPrice: cost,
      overheadMarkupPercent: markup,
      fundSource: fundSource,
      fundingInvestor: investor,
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'addNewProduct'.tr : 'editProduct'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'productName'.tr,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'nameRequired'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Photo capture
              OutlinedButton.icon(
                onPressed: widget.onCapturePhoto == null ? null : _capturePhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _photoLocalPath == null
                      ? 'Add product photo'
                      : 'Change product photo',
                ),
              ),
              if (_photoLocalPath case final photoPath?) ...[
                const SizedBox(height: AppSpacing.sm),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.file(
                        File(photoPath),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () => setState(() => _photoLocalPath = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'category'.tr,
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: widget.onCreateCategory == null
                      ? null
                      : IconButton(
                          tooltip: 'addCategory'.tr,
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _createCategoryInline,
                        ),
                ),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'nameRequired'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Buy Price & Sell Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'costLabel'.tr,
                        prefixText: '৳ ',
                      ),
                      validator: _validateMoney,
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
                        prefixText: '৳ ',
                      ),
                      validator: _validateMoney,
                    ),
                  ),
                ],
              ),
              if (_suggestedSellPrice case final suggestion?) ...[
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => setState(
                    () => _priceController.text = suggestion.format(
                      showSymbol: false,
                    ),
                  ),
                  child: Text(
                    '${'suggestedSellPriceLabel'.tr}${suggestion.format()} '
                    '· ${'tapToUse'.tr}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Stock Quantity (for both new creation & edit mode)
              TextFormField(
                controller: _initialQtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.existing == null
                      ? 'initialStock'.tr
                      : 'currentStock'.tr,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  suffixText: 'unitPcs'.tr,
                  helperText: widget.existing == null
                      ? 'initialStockHelper'.tr
                      : 'editStockHelper'.tr,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0) return 'invalidQty'.tr;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Fund Source (Shop vs Investor)
              DropdownButtonFormField<String>(
                initialValue: _fundSourceValue,
                decoration: InputDecoration(
                  labelText: 'fundSource'.tr,
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: _shopFundValue,
                    child: Text('shop'.tr),
                  ),
                  for (final investor in widget.investors)
                    DropdownMenuItem(
                      value: investor.id,
                      child: Text(investor.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _fundSourceValue = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Barcode with Scanner
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'barcode'.tr,
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'scanBarcode'.tr,
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // SKU
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'sku'.tr,
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Rentable Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('rentable'.tr),
                subtitle: const Text('Allow this product to be rented'),
                value: _isRentable,
                onChanged: (v) => setState(() => _isRentable = v),
              ),
              if (_isRentable) ...[
                TextFormField(
                  controller: _pageCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'pageCount'.tr,
                    helperText: 'For books / rental tier calculations',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('save'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) return 'nameRequired'.tr;
    try {
      Money.parse(value);
      return null;
    } on MoneyException {
      return 'invalidQty'.tr;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final initialQty = double.tryParse(_initialQtyController.text) ??
        (widget.existing?.qty ?? 0.0);
    final pageCount = int.tryParse(_pageCountController.text);

    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text,
        category: _category!,
        costPrice: Money.parse(_costController.text),
        suggestedSellPrice: Money.parse(_priceController.text),
        fundSource: _fundSourceValue == _shopFundValue
            ? FundSource.shop()
            : FundSource.investor(_fundSourceValue),
        isRentable: _isRentable,
        initialQty: initialQty,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        pageCount: _isRentable ? pageCount : null,
        photoLocalPath: _photoLocalPath,
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
