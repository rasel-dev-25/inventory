import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/calculator_evaluator.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/unit_dao.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/pricing_engine.dart';
import 'unit_management_sheet.dart';

/// What [ProductFormSheet] hands back on save â€” [CatalogScreen] / [StockScreen] decides
/// whether that means a create or an update, since only it knows whether
/// [ProductFormSheet.existing] was passed.
class ProductFormResult {
  final String name;
  final String category;
  final Money costPrice;
  final Money suggestedSellPrice;
  final FundSource fundSource;
  final String unit;
  final String sellUnit;
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
    this.unit = 'pcs',
    this.sellUnit = 'pcs',
    required this.isRentable,
    this.initialQty = 0,
    this.barcode,
    this.sku,
    this.pageCount,
    this.photoLocalPath,
  });
}

/// Create/edit form for a single [Product]. Pure form state â€” validation
/// and the actual create/update call both live in [CatalogController]/[StockController],
/// this widget only ever returns a [ProductFormResult] via
/// `Navigator.pop`.
class ProductFormSheet extends StatefulWidget {
  final Product? existing;
  final List<String> categories;
  final List<Investor> investors;
  final List<String>? units;
  final Future<String?> Function(String name)? onCreateCategory;
  final Future<String?> Function()? onCapturePhoto;
  final String? existingPhotoPath;

  /// Null hides the suggestion entirely â€” see `computeOverheadMarkupPercent`
  /// (`pricing_engine.dart`) for the exact conditions (the pricing
  /// engine's bootstrap period, or no usable revenue estimate yet).
  final double? overheadMarkupPercent;

  const ProductFormSheet({
    required this.categories,
    required this.investors,
    super.key,
    this.units,
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

  late String _buyUnit = widget.existing?.unit ?? 'pcs';
  late String _sellUnit = widget.existing?.sellUnit ?? widget.existing?.unit ?? 'pcs';
  late List<String> _availableUnits = widget.units != null && widget.units!.isNotEmpty
      ? [...widget.units!]
      : [...UnitDao.defaultUnitNames];

  @override
  void initState() {
    super.initState();
    _costController.addListener(_onCostChanged);
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final db = Get.find<AppDatabase>();
      final units = await db.unitDao.getAll(defaultShopId);
      if (units.isNotEmpty && mounted) {
        setState(() {
          _availableUnits = units.map((u) => u.name).toList();
          if (!_availableUnits.contains(_buyUnit)) _availableUnits.add(_buyUnit);
          if (!_availableUnits.contains(_sellUnit)) _availableUnits.add(_sellUnit);
        });
      }
    } catch (_) {}
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

  Future<void> _openUnitManagement({required bool forSellUnit}) async {
    final initial = forSellUnit ? _sellUnit : _buyUnit;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UnitManagementSheet(initialSelectedUnit: initial),
    );
    await _loadUnits();
    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        if (forSellUnit) {
          _sellUnit = selected;
        } else {
          final wasMatching = _sellUnit == _buyUnit;
          _buyUnit = selected;
          if (wasMatching) _sellUnit = selected;
        }
        if (!_availableUnits.contains(selected)) {
          _availableUnits.add(selected);
        }
      });
    }
  }

  String? _activeCalculatorField;

  void _setActiveField(String? field) {
    if (_activeCalculatorField != field) {
      if (_activeCalculatorField != null) {
        if (_activeCalculatorField == 'cost') finalizeCalculatorController(_costController);
        if (_activeCalculatorField == 'price') finalizeCalculatorController(_priceController);
        if (_activeCalculatorField == 'stock') finalizeCalculatorController(_initialQtyController);
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
      if (_activeCalculatorField == 'cost') {
        applyCalculatorKeyToController(_costController, key);
      } else if (_activeCalculatorField == 'price') {
        applyCalculatorKeyToController(_priceController, key);
      } else if (_activeCalculatorField == 'stock') {
        applyCalculatorKeyToController(_initialQtyController, key);
      }
    });
  }

  Future<void> _capturePhoto() async {
    final captured = await widget.onCapturePhoto!();
    if (captured != null && mounted) {
      setState(() => _photoLocalPath = captured);
    }
  }

  Money? get _suggestedSellPrice {
    final markup = widget.overheadMarkupPercent;
    if (markup == null) return null;
    final cost = _parseMoneyOrNull(_costController.text);
    if (cost == null) return null;
    final investor = widget.investors
        .where((i) => i.id == _fundSourceValue)
        .firstOrNull;
    return suggestSellPrice(
      costPrice: cost,
      overheadMarkupPercent: markup,
      fundSource: _fundSourceValue == _shopFundValue
          ? FundSource.shop()
          : FundSource.investor(_fundSourceValue),
      fundingInvestor: investor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final keypadVisible = _activeCalculatorField != null;

    // â”€â”€â”€ shared scrollable form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final formContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: keypadVisible ? AppSpacing.sm : AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),

            // Title bar
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null ? 'newProduct'.tr : 'editProduct'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Product Name
            TextFormField(
              controller: _nameController,
              onTap: () => _setActiveField(null),
              decoration: InputDecoration(
                labelText: 'productName'.tr,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'nameRequired'.tr : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Photo
            OutlinedButton.icon(
              onPressed: widget.onCapturePhoto == null ? null : _capturePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_photoLocalPath == null ? 'Add product photo' : 'Change product photo'),
            ),
            if (_photoLocalPath case final photoPath?) ...[
              const SizedBox(height: AppSpacing.sm),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => showFullScreenImageViewer(
                      context,
                      imagePath: photoPath,
                      title: _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : 'Product Photo',
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        SafeImage(
                          source: photoPath,
                          height: 140,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          fallbackIcon: Icons.broken_image_outlined,
                        ),
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text('tapToZoom'.tr, style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
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

            // Category & Investor
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: 'category'.tr,
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      suffixIcon: widget.onCreateCategory == null
                          ? null
                          : IconButton(
                              tooltip: 'addCategory'.tr,
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              onPressed: _createCategoryInline,
                            ),
                    ),
                    items: [
                      for (final c in _categories)
                        DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      setState(() => _category = v);
                      _setActiveField(null);
                    },
                    validator: (v) => v == null ? 'nameRequired'.tr : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _fundSourceValue,
                    decoration: InputDecoration(
                      labelText: 'investor'.tr,
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _shopFundValue,
                        child: Text('shop'.tr, overflow: TextOverflow.ellipsis),
                      ),
                      for (final investor in widget.investors)
                        DropdownMenuItem(
                          value: investor.id,
                          child: Text(investor.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _fundSourceValue = value);
                        _setActiveField(null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Buy Unit & Sell Unit
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _availableUnits.contains(_buyUnit) ? _buyUnit : null,
                    decoration: InputDecoration(
                      labelText: 'buyUnit'.tr,
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      suffixIcon: IconButton(
                        tooltip: 'manageUnits'.tr,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        onPressed: () => _openUnitManagement(forSellUnit: false),
                      ),
                    ),
                    items: [
                      for (final u in _availableUnits)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          final wasMatching = _sellUnit == _buyUnit;
                          _buyUnit = v;
                          if (wasMatching) _sellUnit = v;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _availableUnits.contains(_sellUnit) ? _sellUnit : null,
                    decoration: InputDecoration(
                      labelText: 'sellUnit'.tr,
                      prefixIcon: const Icon(Icons.point_of_sale_outlined, size: 20),
                      suffixIcon: IconButton(
                        tooltip: 'manageUnits'.tr,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        onPressed: () => _openUnitManagement(forSellUnit: true),
                      ),
                    ),
                    items: [
                      for (final u in _availableUnits)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sellUnit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Cost & Sell Price â€” tap activates in-place keypad
            Row(
              children: [
                Expanded(
                  child: CalculatorFieldCard(
                    label: '${'costLabel'.tr} ($_buyUnit)',
                    value: _costController.text,
                    isSelected: _activeCalculatorField == 'cost',
                    onTap: () => _setActiveField('cost'),
                    prefixText: 'à§³ ',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CalculatorFieldCard(
                    label: '${'sellPriceLabel'.tr} ($_sellUnit)',
                    value: _priceController.text,
                    isSelected: _activeCalculatorField == 'price',
                    onTap: () => _setActiveField('price'),
                    prefixText: 'à§³ ',
                  ),
                ),
              ],
            ),
            if (_suggestedSellPrice case final suggestion?) ...[
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                onTap: () {
                  setState(() => _priceController.text = suggestion.format(showSymbol: false));
                  _setActiveField('price');
                },
                child: Text(
                  '${'suggestedSellPriceLabel'.tr}${suggestion.format()} / $_sellUnit Â· ${'tapToUse'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Stock â€” tap activates in-place keypad
            CalculatorFieldCard(
              label: '${widget.existing == null ? 'initialStock'.tr : 'currentStock'.tr} ($_sellUnit)',
              value: _initialQtyController.text,
              isSelected: _activeCalculatorField == 'stock',
              onTap: () => _setActiveField('stock'),
              prefixText: '',
            ),
            const SizedBox(height: AppSpacing.md),

            // Rentable
            SwitchListTile(
              title: Text('rentable'.tr),
              subtitle: Text('allowRentProduct'.tr),
              value: _isRentable,
              onChanged: (value) => setState(() => _isRentable = value),
            ),

            if (_isRentable) ...[
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _pageCountController,
                keyboardType: TextInputType.number,
                onTap: () => _setActiveField(null),
                decoration: InputDecoration(
                  labelText: 'pageCount'.tr,
                  prefixIcon: const Icon(Icons.menu_book),
                  helperText: 'pageCountHelper'.tr,
                ),
                validator: (v) {
                  if (!_isRentable) return null;
                  if (v == null || v.trim().isEmpty) return null;
                  final count = int.tryParse(v);
                  if (count == null || count <= 0) return 'invalidQty'.tr;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Save button â€” shown only when keypad is NOT visible
            if (!keypadVisible) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('save'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );

    // ————————————————————————————————————————————————————————————————
    // Keypad visible  → fix sheet height to 92%
    // Keypad hidden   → hug content naturally (≤ 92% screen height).
    final sheetDecoration = BoxDecoration(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    );

    if (keypadVisible) {
      return SizedBox(
        height: screenHeight * 0.92,
        child: Container(
          decoration: sheetDecoration,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Tap anywhere on the scrollable form to dismiss the keypad
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setActiveField(null),
                    behavior: HitTestBehavior.translucent,
                    child: formContent,
                  ),
                ),

                // Live expression / Confirm bar
                InPlaceCalculatorBar(
                  label: _activeCalculatorField == 'cost'
                      ? '${'costLabel'.tr} ($_buyUnit)'
                      : (_activeCalculatorField == 'price'
                          ? '${'sellPriceLabel'.tr} ($_sellUnit)'
                          : '${'stockLabel'.tr} ($_sellUnit)'),
                  currentText: _activeCalculatorField == 'cost'
                      ? _costController.text
                      : (_activeCalculatorField == 'price'
                          ? _priceController.text
                          : _initialQtyController.text),
                  prefixText: _activeCalculatorField == 'stock' ? '' : '৳ ',
                  onDone: () => _setActiveField(null),
                ),

                // 5-row keypad — no Save button here.
                // User taps Confirm bar or anywhere outside to dismiss,
                // then uses the regular Save button shown below the form.
                CalculatorKeypad(onKeyPress: _onCalculatorKeyPress),
              ],
            ),
          ),
        ),
      );
    }

    // No keypad â€” hug content height
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: sheetDecoration,
        child: SafeArea(top: false, child: formContent),
      ),
    );
  }

  Money? _parseMoneyOrNull(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final evaluated = CalculatorEvaluator.evaluate(text) ??
          CalculatorEvaluator.evaluatePreview(text);
      if (evaluated != null) {
        return Money.parse(CalculatorEvaluator.formatResult(evaluated));
      }
      return Money.parse(text);
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    finalizeCalculatorController(_costController);
    finalizeCalculatorController(_priceController);
    finalizeCalculatorController(_initialQtyController);

    if (!_formKey.currentState!.validate()) return;

    final cost = _parseMoneyOrNull(_costController.text) ?? Money.zero();
    final price = _parseMoneyOrNull(_priceController.text) ?? Money.zero();
    final initialQty = double.tryParse(_initialQtyController.text) ??
        (widget.existing?.qty ?? 0.0);
    final pageCount = int.tryParse(_pageCountController.text);

    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text,
        category: _category!,
        costPrice: cost,
        suggestedSellPrice: price,
        fundSource: _fundSourceValue == _shopFundValue
            ? FundSource.shop()
            : FundSource.investor(_fundSourceValue),
        unit: _buyUnit,
        sellUnit: _sellUnit,
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
