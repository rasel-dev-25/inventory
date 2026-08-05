import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/platform/capabilities.dart';
import '../../../core/widgets/barcode_scanner_view.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/pricing_engine.dart';

/// What [ProductFormSheet] hands back on save — [CatalogScreen] decides
/// whether that means a create or an update, since only it knows whether
/// [ProductFormSheet.existing] was passed.
class ProductFormResult {
  final String name;
  final String category;
  final Money costPrice;
  final Money suggestedSellPrice;
  final FundSource fundSource;
  final bool isRentable;
  final String? barcode;
  final String? sku;
  final int? pageCount;

  const ProductFormResult({
    required this.name,
    required this.category,
    required this.costPrice,
    required this.suggestedSellPrice,
    required this.fundSource,
    required this.isRentable,
    this.barcode,
    this.sku,
    this.pageCount,
  });
}

/// Create/edit form for a single [Product]. Pure form state — validation
/// and the actual create/update call both live in [CatalogController],
/// this widget only ever returns a [ProductFormResult] via
/// `Navigator.pop`.
class ProductFormSheet extends StatefulWidget {
  final Product? existing;
  final List<String> categories;
  final List<Investor> investors;

  /// Null hides the suggestion entirely — see `computeOverheadMarkupPercent`
  /// (`pricing_engine.dart`) for the exact conditions (the pricing
  /// engine's bootstrap period, or no usable revenue estimate yet).
  /// `CatalogScreen` resolves this once from `CatalogController` before
  /// opening the sheet — this widget stays pure form state, per its own
  /// class doc comment, so it never reads a controller directly.
  final double? overheadMarkupPercent;

  const ProductFormSheet({
    super.key,
    required this.categories,
    required this.investors,
    this.existing,
    this.overheadMarkupPercent,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
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
  late final _barcodeController = TextEditingController(
    text: widget.existing?.barcode,
  );
  late final _skuController = TextEditingController(text: widget.existing?.sku);
  late final _pageCountController = TextEditingController(
    text: widget.existing?.pageCount?.toString(),
  );

  late String? _category =
      widget.existing?.category ?? (widget.categories.firstOrNull);
  late bool _isRentable = widget.existing?.isRentable ?? false;
  late bool _fundedByInvestor = widget.existing?.fundSource.isInvestor ?? false;
  late String? _investorId = widget.existing?.fundSource.investorId;

  @override
  void initState() {
    super.initState();
    // Recompute the suggestion live as the cost price is typed — the
    // fund-source toggle/investor dropdown already trigger their own
    // setState via onChanged below.
    _costController.addListener(_onCostChanged);
  }

  void _onCostChanged() => setState(() {});

  /// Just fills the field with whatever was scanned — unlike Daily
  /// Sales' scan button, there is no existing product to look up here;
  /// this form *is* where a barcode gets attached to a product in the
  /// first place.
  Future<void> _scanBarcodeIntoField(BuildContext context) async {
    final code = await showBarcodeScanner(context);
    if (code == null) return;
    setState(() => _barcodeController.text = code);
  }

  @override
  void dispose() {
    _costController.removeListener(_onCostChanged);
    _nameController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }

  /// Per the spec's formula, shown next to the cost-price entry the
  /// instant it's typed — see `pricing_engine.dart`'s own doc comment.
  /// Null whenever there isn't enough to compute one yet: the engine's
  /// bootstrap period, an unparseable cost price, or "funded by investor"
  /// with no investor picked.
  Money? get _suggestedSellPrice {
    final markup = widget.overheadMarkupPercent;
    if (markup == null) return null;
    final cost = _parseMoneyOrNull(_costController.text);
    if (cost == null) return null;

    final fundSource = _fundedByInvestor
        ? (_investorId == null ? null : FundSource.investor(_investorId!))
        : FundSource.shop();
    if (fundSource == null) return null;

    final investor = _fundedByInvestor
        ? widget.investors.where((i) => i.id == _investorId).firstOrNull
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'productName'.tr),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'nameRequired'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: 'category'.tr),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'nameRequired'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'costLabel'.tr),
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
                      ),
                      validator: _validateMoney,
                    ),
                  ),
                ],
              ),
              if (_suggestedSellPrice case final suggestion?) ...[
                const SizedBox(height: AppSpacing.sm),
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
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('fundedByInvestor'.tr),
                value: _fundedByInvestor,
                onChanged: (v) => setState(() => _fundedByInvestor = v),
              ),
              if (_fundedByInvestor)
                DropdownButtonFormField<String>(
                  initialValue: _investorId,
                  decoration: InputDecoration(labelText: 'selectInvestor'.tr),
                  items: [
                    for (final i in widget.investors)
                      DropdownMenuItem(value: i.id, child: Text(i.name)),
                  ],
                  onChanged: (v) => setState(() => _investorId = v),
                  validator: (v) => (_fundedByInvestor && v == null)
                      ? 'nameRequired'.tr
                      : null,
                ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('rentABook'.tr),
                value: _isRentable,
                onChanged: (v) => setState(() => _isRentable = v),
              ),
              if (_isRentable) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _pageCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'pageCount'.tr),
                  validator: (v) => (v != null && v.trim().isNotEmpty)
                      ? (int.tryParse(v) == null ? 'invalidQty'.tr : null)
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  suffixIcon: PlatformCapabilities.detect().hasCamera
                      ? IconButton(
                          tooltip: 'scanBarcodeTitle'.tr,
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () => _scanBarcodeIntoField(context),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: Text('save'.tr)),
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
    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text,
        category: _category!,
        costPrice: Money.parse(_costController.text),
        suggestedSellPrice: Money.parse(_priceController.text),
        fundSource: _fundedByInvestor
            ? FundSource.investor(_investorId!)
            : FundSource.shop(),
        isRentable: _isRentable,
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        sku: _skuController.text.isEmpty ? null : _skuController.text,
        pageCount: _isRentable ? int.tryParse(_pageCountController.text) : null,
      ),
    );
  }
}

/// Same pattern as every other live-input `Money` field in the app —
/// `Money` has no `tryParse`. Used only by [_suggestedSellPrice], which
/// must degrade to null on unparseable input rather than throw mid-build.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
