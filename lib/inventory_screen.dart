import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'sales_notifier.dart';
import 'dues_screen.dart';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;
import 'constants.dart';

class InventoryEntryScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const InventoryEntryScreen({super.key, this.onMenuTap});

  @override
  State<InventoryEntryScreen> createState() => _InventoryEntryScreenState();
}

class _InventoryEntryScreenState extends State<InventoryEntryScreen> {
  Map<String, String> get _cardHints => {};

  void _showCardHint(String label) {
    final msg = _cardHints[label];
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: kTeal,
      ),
    );
  }

  final _inventoryBox = Hive.box('inventoryBox');
  final _salesBox = Hive.box('salesBox');
  final _assetsBox = Hive.box('assetsBox');

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _buyQtyController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  File? _selectedImage;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  String? _selectedCategory;
  String? _selectedInvestor;
  String? _selectedBuyUnit;
  String? _selectedSellUnit;

  String? _filterCategory;
  String? _filterInvestor;

  List<String> _categories = ['Book', 'Date', 'Attar', 'Topi', 'Miswak'];
  final List<String> _units = ['pcs', 'kg', 'box', 'pack', 'litre', 'pair', 'set', 'roll', 'dozen'];
  final Map<String, double> _conversionFactors = {
    'pcs': 1,
    'kg': 1000,
    'box': 1,
    'pack': 1,
    'litre': 1000,
    'pair': 2,
    'set': 1,
    'roll': 1,
    'dozen': 12,
  };
  final double _lowStockThreshold = 5.0;
  List<String> _investors = ['Own Shop'];

  List<Map<dynamic, dynamic>> _addedProducts = [];
  bool _showForm = false;

  // Buyer connection fields
  final _duesBox = Hive.box('duesBox');
  List<Customer> _buyerCustomers = [];
  String? _selectedBuyerName;

  // Asset fields
  final _assetNameController = TextEditingController();
  final _assetValueController = TextEditingController();
  File? _assetImage;
  List<FixedAsset> _assets = [];

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadDataFromDatabase();
    _loadAssetData();
    _loadCategories();
    _loadInvestors();
    _loadBuyerCustomers();
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
  }

  void _loadCategories() {
    final stored = _inventoryBox.get('categories', defaultValue: ['Book', 'Date', 'Attar', 'Topi', 'Miswak']);
    setState(() {
      _categories = List<String>.from(stored);
    });
  }

  void _saveCategories() {
    _inventoryBox.put('categories', _categories);
  }

  void _addNewCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      if (!_categories.contains(trimmed)) {
        _categories.add(trimmed);
      }
    });
    _saveCategories();
  }

  // ignore: unused_element
  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.category, color: kTeal, size: 22),
            const SizedBox(width: 10),
            Text(lang.Lang.tr('addNewCategory')),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: lang.Lang.tr('enterCategoryName'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              _addNewCategory(controller.text);
              Navigator.pop(context);
            },
            child: Text(lang.Lang.tr('add')),
          ),
        ],
      ),
    );
  }

  void _loadInvestors() {
    final investorBox = Hive.box('investorBox');
    final storedInvestors = List<Map<dynamic, dynamic>>.from(investorBox.get('investors', defaultValue: []));
    final productInvestors = _addedProducts.map((p) => p['investor']?.toString()).whereType<String>().toSet();

    setState(() {
      final names = storedInvestors.map((e) => e['name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
      names.addAll(productInvestors);
      names.add('Own Shop');
      final investorList = <String>[];
      for (final e in names) {
        investorList.add(e.toString());
      }
      _investors = investorList;
      if (!_investors.contains('Own Shop')) _investors.insert(0, 'Own Shop');
    });
  }

  void _loadBuyerCustomers() {
    final stored = _duesBox.get('customers', defaultValue: []);
    _buyerCustomers = List<Map<dynamic, dynamic>>.from(stored)
        .map((c) => Customer.fromMap(Map<String, dynamic>.from(c)))
        .where((c) => c.type == 'buyer')
        .toList();
  }

  void _loadAssetData() {
    final stored = _assetsBox.get('assets', defaultValue: []);
    setState(() {
      _assets = List<Map<dynamic, dynamic>>.from(stored)
          .map((a) => FixedAsset(
                id: a['id']?.toString() ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: a['name']?.toString() ?? '',
                estimatedValue: (a['estimatedValue']?.toDouble() ?? 0.0),
                purchaseDate: a['purchaseDate']?.toString() ?? '',
                image: a['imagePath'] != null &&
                        a['imagePath'].toString().isNotEmpty
                    ? File(a['imagePath'].toString())
                    : null,
              ))
          .toList();
    });
  }

  void _saveAssetData() {
    _assetsBox.put(
        'assets',
        _assets
            .map((a) => {
                  'id': a.id,
                  'name': a.name,
                  'estimatedValue': a.estimatedValue,
                  'purchaseDate': a.purchaseDate,
                  'imagePath': a.image?.path ?? '',
                })
            .toList());
  }

  void _pickAssetImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      setState(() => _assetImage = File(pickedFile.path));
    }
  }

  void _addAsset() {
    if (_assetNameController.text.isEmpty ||
        _assetValueController.text.isEmpty) {
      return;
    }
    setState(() {
      _assets.add(FixedAsset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _assetNameController.text,
        estimatedValue: double.parse(_assetValueController.text),
        purchaseDate: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        image: _assetImage,
      ));
      _assetNameController.clear();
      _assetValueController.clear();
      _assetImage = null;
      _saveAssetData();
    });
  }

  void _deleteAsset(int index) {
    setState(() {
      _assets.removeAt(index);
      _saveAssetData();
    });
  }

  void _loadDataFromDatabase() {
    final storedData = _inventoryBox.get('products', defaultValue: []);
    setState(() {
      _addedProducts = List<Map<dynamic, dynamic>>.from(storedData).map((product) {
        final buyQty = double.tryParse(product['buyQty']?.toString() ?? '') ?? (double.tryParse(product['qty']?.toString() ?? '1') ?? 1.0);
        final buyUnit = product['buyUnit']?.toString() ?? product['unit']?.toString() ?? 'pcs';
        final buyPrice = double.tryParse(product['buyPrice']?.toString() ?? '') ?? (double.tryParse(product['buy']?.toString() ?? '0') ?? 0.0);
        final sellUnit = product['sellUnit']?.toString() ?? product['unit']?.toString() ?? 'pcs';
        final sellPrice = double.tryParse(product['sellPrice']?.toString() ?? '') ?? (double.tryParse(product['sell']?.toString() ?? '0') ?? 0.0);
        final buyConversionFactor = double.tryParse(product['buyConversionFactor']?.toString() ?? '') ?? _conversionFactors[buyUnit] ?? 1.0;
        final sellConversionFactor = double.tryParse(product['sellConversionFactor']?.toString() ?? '') ?? _conversionFactors[sellUnit] ?? 1.0;
        double qty = double.tryParse(product['qty']?.toString() ?? '0') ?? 0.0;
        if (qty <= 0 && buyQty > 0) {
          qty = buyQty * buyConversionFactor;
        }

        return Map<dynamic, dynamic>.from(product)
          ..['buyQty'] = buyQty
          ..['buyUnit'] = buyUnit
          ..['buyPrice'] = buyPrice
          ..['sellUnit'] = sellUnit
          ..['sellPrice'] = sellPrice
          ..['qty'] = qty
          ..['buyConversionFactor'] = buyConversionFactor
          ..['sellConversionFactor'] = sellConversionFactor;
      }).toList();
      _inventoryBox.put('products', _addedProducts);
    });
  }

  void _listenVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _productNameController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) _isListening = false;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _addProductToStore() {
    if (_productNameController.text.isEmpty || _buyQtyController.text.isEmpty || _buyPriceController.text.isEmpty || _sellPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.Lang.tr('fillRequired')), backgroundColor: Colors.red),
      );
      return;
    }

    double buyQty = double.tryParse(_buyQtyController.text) ?? 0.0;
    double buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
    double sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String buyUnit = _selectedBuyUnit ?? 'pcs';
    String sellUnit = _selectedSellUnit ?? buyUnit;
    double buyConversionFactor = _conversionFactors[buyUnit] ?? 1.0;
    double sellConversionFactor = _conversionFactors[sellUnit] ?? 1.0;
    double stockInput = double.tryParse(_stockController.text) ?? 0.0;
    double baseQty = stockInput > 0 ? stockInput * sellConversionFactor : buyQty * buyConversionFactor;

    final newProduct = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'category': _selectedCategory ?? 'Other',
      'investor': _selectedInvestor ?? 'Own Shop',
      'name': _productNameController.text,
      'buyQty': buyQty,
      'buyUnit': buyUnit,
      'buyPrice': buyPrice,
      'sellUnit': sellUnit,
      'sellPrice': sellPrice,
      'qty': baseQty,
      'buyConversionFactor': buyConversionFactor,
      'sellConversionFactor': sellConversionFactor,
      'date': currentDate,
      'imagePath': _selectedImage?.path ?? '',
    };

    setState(() {
      _addedProducts.add(newProduct);
      _inventoryBox.put('products', _addedProducts);
      _loadInvestors();

      _productNameController.clear();
      _buyQtyController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _stockController.clear();
      _selectedImage = null;
      _selectedCategory = null;
      _selectedInvestor = null;
      _selectedBuyUnit = null;
      _selectedSellUnit = null;
    });
  }

  void _openEditBottomSheet(int index) {
    var item = _addedProducts[index];

    final editNameController = TextEditingController(text: item['name']);
    final editBuyQtyController = TextEditingController(text: item['buyQty']?.toString() ?? '1');
    final editBuyPriceController = TextEditingController(text: item['buyPrice']?.toString() ?? '0');
    final editSellPriceController = TextEditingController(text: item['sellPrice']?.toString() ?? '0');
    final editStockController = TextEditingController(
      text: () {
        final baseQty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0;
        final sellConv = double.tryParse(item['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
        return (sellConv > 0 ? baseQty / sellConv : baseQty).toStringAsFixed(1);
      }(),
    );

    String? editCategory = _categories.contains(item['category']?.toString()) ? item['category']?.toString() : null;
    String? editInvestor = _investors.contains(item['investor']?.toString()) ? item['investor']?.toString() : null;
    String? editBuyUnit = _units.contains(item['buyUnit']?.toString()) ? item['buyUnit']?.toString() : 'pcs';
    String? editSellUnit = _units.contains(item['sellUnit']?.toString()) ? item['sellUnit']?.toString() : 'pcs';
    double editBuyConversionFactor = double.tryParse(item['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
    double editSellConversionFactor = double.tryParse(item['sellConversionFactor']?.toString() ?? '1') ?? 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Iconsax.edit, color: kTeal, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(lang.Lang.tr('editProduct'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    TextField(controller: editNameController, decoration: InputDecoration(labelText: lang.Lang.tr('productName'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: editCategory,
                                isExpanded: true,
                                hint: Text(lang.Lang.tr('category')),
                                items: _categories.toSet().toList().map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                onChanged: (v) => setModalState(() => editCategory = v),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: editInvestor,
                                isExpanded: true,
                                hint: Text(lang.Lang.tr('investor')),
                                items: _investors.toSet().toList().map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                onChanged: (v) => setModalState(() => editInvestor = v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: 12),

                     Row(
                       children: [
                         Expanded(
                           child: TextField(controller: editBuyQtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('buyQty'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                         ),
                         const SizedBox(width: 10),
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                             child: DropdownButtonHideUnderline(
                               child: DropdownButton<String>(
                                 value: editBuyUnit,
                                 isExpanded: true,
                                 hint: Text(lang.Lang.tr('buyUnit')),
                                 items: _units.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                 onChanged: (v) {
                                   if (v != null) {
                                     setModalState(() {
                                       editBuyUnit = v;
                                       editBuyConversionFactor = _conversionFactors[v] ?? 1.0;
                                     });
                                   }
                                 },
                               ),
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),

                     Row(
                       children: [
                         Expanded(child: TextField(controller: editBuyPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('buyPrice'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                         const SizedBox(width: 10),
                         Expanded(child: TextField(controller: editSellPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('sellPrice'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                       ],
                     ),
                     const SizedBox(height: 12),

                     Row(
                       children: [
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                             child: DropdownButtonHideUnderline(
                               child: DropdownButton<String>(
                                 value: editSellUnit,
                                 isExpanded: true,
                                 hint: Text(lang.Lang.tr('sellUnit')),
                                 items: _units.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                 onChanged: (v) {
                                   if (v != null) {
                                     setModalState(() {
                                       editSellUnit = v;
                                       editSellConversionFactor = _conversionFactors[v] ?? 1.0;
                                     });
                                   }
                                 },
                               ),
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),

                     Row(
                       children: [
                         Expanded(child: TextField(
                           controller: editStockController,
                           keyboardType: TextInputType.number,
                           decoration: InputDecoration(
                              labelText: '${lang.Lang.tr('stock')} (${editSellUnit ?? 'pcs'})',
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                             focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
                             contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                           ),
                         )),
                       ],
                     ),
                     const SizedBox(height: 20),

                     SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: kTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          setState(() {
                             _addedProducts[index] = {
                               ...item,
                               'name': editNameController.text,
                               'category': editCategory ?? 'Other',
                               'investor': editInvestor ?? 'Own Shop',
                               'buyQty': double.tryParse(editBuyQtyController.text) ?? 1,
                               'buyUnit': editBuyUnit ?? 'pcs',
                               'buyPrice': double.tryParse(editBuyPriceController.text) ?? 0,
                               'sellUnit': editSellUnit ?? 'pcs',
                               'sellPrice': double.tryParse(editSellPriceController.text) ?? 0,
                               'qty': (double.tryParse(editStockController.text) ?? 0) * editSellConversionFactor,
                               'buyConversionFactor': editBuyConversionFactor,
                               'sellConversionFactor': editSellConversionFactor,
                             };
                           _inventoryBox.put('products', _addedProducts);
                           _loadInvestors();
                         });
                         Navigator.pop(context);
                       },
                        child: Text(lang.Lang.tr('save'), style: TextStyle(fontSize: 16)),
                     ),),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _addedProducts.removeAt(index);
                            _inventoryBox.put('products', _addedProducts);
                            _loadInvestors();
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Iconsax.trash, size: 20),
                        label: Text(lang.Lang.tr('delete'), style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    }

  void _processSale(int index, bool isCreditSale) {
    final product = _addedProducts[index];
    double baseQty = double.tryParse(product['qty']?.toString() ?? '0') ?? 0.0;
    double sellConversionFactor = double.tryParse(product['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
    double displayQty = sellConversionFactor > 0 ? baseQty / sellConversionFactor : baseQty;
    String sellUnit = product['sellUnit']?.toString() ?? 'pcs';

    if (displayQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.Lang.tr('stockFinished')), backgroundColor: Colors.red),
      );
      return;
    }

    double buyQty = double.tryParse(product['buyQty']?.toString() ?? '1') ?? 1.0;
    double buyPrice = double.tryParse(product['buyPrice']?.toString() ?? '0') ?? 0.0;
    double buyConversionFactor = double.tryParse(product['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
    double sellPrice = double.tryParse(product['sellPrice']?.toString() ?? '0') ?? 0.0;

    _showSaleQuantityDialog(index, displayQty, sellUnit, buyQty, buyPrice, buyConversionFactor, sellPrice, sellConversionFactor, isCreditSale);
  }

  void _showSaleQuantityDialog(int index, double maxDisplayQty, String sellUnit, double buyQty, double buyPrice, double buyConversionFactor, double sellPrice, double sellConversionFactor, bool isCreditSale) {
    final product = _addedProducts[index];
    final productName = product['name']?.toString() ?? 'Unknown';
    final qtyController = TextEditingController(text: '1');
    bool selectedIsCredit = isCreditSale;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                // Product info header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kTeal.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Iconsax.bag, color: kTeal, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('৳${sellPrice.toStringAsFixed(2)} / $sellUnit  •  Available: ${maxDisplayQty.toStringAsFixed(2)} $sellUnit',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${lang.Lang.tr('quantity')} (max ${maxDisplayQty.toStringAsFixed(2)} $sellUnit)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kTeal)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(lang.Lang.tr('cash'), style: TextStyle(fontWeight: FontWeight.w500)),
                        selected: !selectedIsCredit,
                        onSelected: (v) => setSheetState(() => selectedIsCredit = false),
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(color: !selectedIsCredit ? Colors.white : Colors.black87),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: Text(lang.Lang.tr('credit'), style: TextStyle(fontWeight: FontWeight.w500)),
                        selected: selectedIsCredit,
                        onSelected: (v) => setSheetState(() => selectedIsCredit = true),
                        selectedColor: Colors.orange,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(color: selectedIsCredit ? Colors.white : Colors.black87),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_buyerCustomers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      initialValue: '',
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('buyerOptional'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kTeal)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: '', child: Text(lang.Lang.tr('none'), style: TextStyle(color: Colors.grey))),
                        ..._buyerCustomers.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                      ],
                      onChanged: (v) => _selectedBuyerName = v?.isNotEmpty == true ? v : null,
                    ),
                  ),
                const SizedBox(height: 18),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                      onPressed: () {
                        double qty = double.tryParse(qtyController.text) ?? 0;
                        if (qty <= 0 || qty > maxDisplayQty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(lang.Lang.tr('invalidQty')), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        double baseQtyToSell = qty * sellConversionFactor;
                        double costPerBaseUnit = buyConversionFactor > 0 ? buyPrice / buyConversionFactor : 0;
                        double costOfGoodsSold = costPerBaseUnit * baseQtyToSell;
                        double amount = sellPrice * qty;
                        double profit = amount - costOfGoodsSold;

                        setState(() {
                          _addedProducts[index] = {
                            ..._addedProducts[index],
                            'qty': (double.tryParse(_addedProducts[index]['qty']?.toString() ?? '0') ?? 0.0) - baseQtyToSell,
                          };
                          _inventoryBox.put('products', _addedProducts);
                        });

                        String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
                        final existingSales = List<Map<dynamic, dynamic>>.from(_salesBox.get('sales', defaultValue: []));
                        existingSales.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'date': today,
                          'productName': _addedProducts[index]['name']?.toString() ?? 'Unknown',
                          'amount': amount,
                          'profit': profit,
                          'type': selectedIsCredit ? 'credit' : 'cash',
                        });
                        _salesBox.put('sales', existingSales);

                        if (selectedIsCredit) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DuesScreen(
                                prefilledName: _addedProducts[index]['name'].toString(),
                                prefilledAmount: amount,
                                itemName: _addedProducts[index]['name']?.toString(),
                                itemImage: null,
                              ),
                            ),
                          );
                        } else {
                          salesNotifier.value = {
                            'cash': salesNotifier.value['cash']! + amount,
                            'profit': salesNotifier.value['profit']! + profit,
                          };
                        }

                        String investor = _addedProducts[index]['investor']?.toString() ?? 'Own Shop';
                        _triggerInvestorProfitSplit(investor, costOfGoodsSold, amount);

                        if (!selectedIsCredit && _selectedBuyerName != null) {
                          final allCustomers = List<Map<dynamic, dynamic>>.from(_duesBox.get('customers', defaultValue: []));
                          final buyerIdx = allCustomers.indexWhere((c) =>
                              c['name']?.toString() == _selectedBuyerName && c['type']?.toString() == 'buyer');
                          if (buyerIdx >= 0) {
                            final customer = Customer.fromMap(Map<String, dynamic>.from(allCustomers[buyerIdx]));
                            customer.purchases.add({
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'productName': _addedProducts[index]['name']?.toString() ?? '',
                              'price': amount,
                              'date': today,
                            });
                            allCustomers[buyerIdx] = customer.toMap();
                            _duesBox.put('customers', allCustomers);
                          }
                          _selectedBuyerName = null;
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedIsCredit ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(selectedIsCredit ? lang.Lang.tr('sellOnCredit') : lang.Lang.tr('completeSale'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  void _triggerInvestorProfitSplit(String investorName, double cost, double revenue) {
    final investorBox = Hive.box('investorBox');
    List<Map<dynamic, dynamic>> investors = List<Map<dynamic, dynamic>>.from(investorBox.get('investors', defaultValue: []));

    double netProfit = revenue - cost;
    if (netProfit <= 0) return;

    double investorShare = 0.0;
    double ownShopShare = netProfit;

    if (investorName != 'Own Shop') {
      int investorIndex = investors.indexWhere((inv) => inv['name'] == investorName);
      if (investorIndex != -1) {
        double profitPercentage = double.tryParse(investors[investorIndex]['profitPercentage'].toString()) ?? 0.0;
        investorShare = netProfit * (profitPercentage / 100);
        ownShopShare = netProfit - investorShare;

        investors[investorIndex] = {
          ...investors[investorIndex],
          'dailyEarnings': (double.tryParse(investors[investorIndex]['dailyEarnings'].toString()) ?? 0.0) + investorShare,
          'monthlyEarnings': (double.tryParse(investors[investorIndex]['monthlyEarnings'].toString()) ?? 0.0) + investorShare,
        };
      }
    }

    int ownShopIndex = investors.indexWhere((inv) => inv['name'] == 'Own Shop');
    if (ownShopIndex == -1) {
      investors.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': 'Own Shop',
        'investedAmount': 0.0,
        'durationMonths': 12,
        'profitPercentage': 100.0,
        'dailyEarnings': ownShopShare,
        'monthlyEarnings': ownShopShare,
      });
    } else {
      investors[ownShopIndex] = {
        ...investors[ownShopIndex],
        'dailyEarnings': (double.tryParse(investors[ownShopIndex]['dailyEarnings'].toString()) ?? 0.0) + ownShopShare,
        'monthlyEarnings': (double.tryParse(investors[ownShopIndex]['monthlyEarnings'].toString()) ?? 0.0) + ownShopShare,
      };
    }

    investorBox.put('investors', investors);
  }

  List<Map<dynamic, dynamic>> get _filteredProducts {
    return _addedProducts.where((product) {
      final category = product['category']?.toString() ?? '';
      final investor = product['investor']?.toString() ?? '';
      final matchCategory = _filterCategory == null || category == _filterCategory;
      final matchInvestor = _filterInvestor == null || investor == _filterInvestor;
      return matchCategory && matchInvestor;
    }).toList();
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: kTeal,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kTeal, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kTeal),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTeal)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kTeal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: kTeal.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.calendar, color: kTeal, size: 22),
              const SizedBox(width: 10),
              Text(lang.Lang.tr('dateSelected')),
            ],
          ),
          content: Text('${lang.Lang.tr('dateLabel')}${DateFormat('yyyy-MM-dd').format(_selectedDate!)}\n\n${lang.Lang.tr('noDateSpecificData')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK', style: TextStyle(color: kTeal)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.menu_1, color: Colors.white), onPressed: widget.onMenuTap),
        title: shopLogo(size: 20, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: _showDatePicker,
          ),
        ],
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: lang.Lang.tr('stock')),
            Tab(text: lang.Lang.tr('assets')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          Stack(
            children: [
              SingleChildScrollView(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(lang.Lang.tr('stockList'), Iconsax.box),
                const SizedBox(height: 8),
                _buildSectionHeader(lang.Lang.tr('filterByCategory'), Iconsax.filter),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(lang.Lang.tr('all'), _filterCategory == null, () => setState(() => _filterCategory = null)),
                      ..._categories.map((cat) => _buildFilterChip(cat, _filterCategory == cat, () => setState(() => _filterCategory = cat))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                _buildSectionHeader(lang.Lang.tr('filterByInvestor'), Iconsax.profile),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(lang.Lang.tr('all'), _filterInvestor == null, () => setState(() => _filterInvestor = null)),
                      ..._investors.map((inv) => _buildFilterChip(inv, _filterInvestor == inv, () => setState(() => _filterInvestor = inv))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _buildSummaryCards(),

                _filteredProducts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: _buildEmptyState(Iconsax.box, lang.Lang.tr('noProducts'), lang.Lang.tr('addFirstProduct')),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final name = product['name']?.toString() ?? 'Unknown Product';
                          final buyUnit = product['buyUnit']?.toString() ?? 'pcs';
                          final buyPrice = (double.tryParse(product['buyPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                          final sellPrice = (double.tryParse(product['sellPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                            double baseQty = double.tryParse(product['qty']?.toString() ?? '0') ?? 0.0;
                            double sellConversionFactor = double.tryParse(product['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
                            double displayQty = sellConversionFactor > 0 ? baseQty / sellConversionFactor : baseQty;
                            final sellUnit = product['sellUnit']?.toString() ?? 'pcs';
                            bool isOutOfStock = displayQty <= 0;
                            bool isLowStock = !isOutOfStock && displayQty < _lowStockThreshold;

                             return Card(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                elevation: 2,
                                shadowColor: kTeal.withValues(alpha: 0.25),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: isOutOfStock ? Colors.red.shade50 : isLowStock ? Colors.yellow.shade50 : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: isOutOfStock ? Colors.red.shade100 : isLowStock ? Colors.yellow.shade100 : kTeal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isOutOfStock ? Colors.red.shade200 : isLowStock ? Colors.yellow.shade300 : kTeal.withValues(alpha: 0.15)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: product['imagePath'] != null && product['imagePath'].toString().isNotEmpty
                                            ? Image.file(File(product['imagePath'].toString()), fit: BoxFit.cover)
                                            : Icon(isOutOfStock ? Iconsax.box : isLowStock ? Iconsax.warning_2 : Iconsax.bag,
                                                  color: isOutOfStock ? Colors.red.shade400 : isLowStock ? Colors.yellow.shade700 : kTeal, size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: isOutOfStock ? Colors.red.shade800 : isLowStock ? Colors.yellow.shade900 : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text('${lang.Lang.tr('buyLabel')}৳$buyPrice/$buyUnit  •  ${lang.Lang.tr('sellPriceLabel')}৳$sellPrice/$sellUnit',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                            const SizedBox(height: 3),
                                             Row(
                                               children: [
                                                  Text('${lang.Lang.tr('stockLabel2')}${displayQty.toStringAsFixed(2)} $sellUnit',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                       color: isOutOfStock ? Colors.red : Colors.green.shade700,
                                                     )),
                                                 if (isOutOfStock)
                                                   const Padding(
                                                     padding: EdgeInsets.only(left: 6),
                                                      child: Icon(Iconsax.close_circle, color: Colors.red, size: 15),
                                                   ),
                                                 const SizedBox(width: 4),
                                                 GestureDetector(
                                                    onTap: () => _showCardHint(lang.Lang.tr('stock')),
                                                    child: Icon(Iconsax.info_circle, size: 10, color: Colors.grey.shade400),
                                                 ),
                                               ],
                                             ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Iconsax.money, color: Colors.green),
                                            onPressed: () => _processSale(_addedProducts.indexOf(product), false),
                                            tooltip: lang.Lang.tr('sell'),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                          IconButton(
                                            icon: Icon(Iconsax.edit, color: kTeal),
                                            onPressed: () => _openEditBottomSheet(_addedProducts.indexOf(product)),
                                            tooltip: lang.Lang.tr('edit'),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                          IconButton(
                                            icon: const Icon(Iconsax.trash, color: Colors.red),
                                            onPressed: () {
                                              final productCopy = product;
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: Row(
                                                    children: [
                                                       Icon(Iconsax.trash, color: Colors.red.shade400, size: 22),
                                                      const SizedBox(width: 10),
                                                      Text(lang.Lang.tr('deleteProduct')),
                                                    ],
                                                  ),
                                                  content: Text('${lang.Lang.tr('delete')} "${productCopy['name']}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                      onPressed: () {
                                                        setState(() {
                                                          _addedProducts.removeAt(_addedProducts.indexOf(productCopy));
                                                          _inventoryBox.put('products', _addedProducts);
                                                          _loadInvestors();
                                                        });
                                                        Navigator.pop(ctx);
                                                      },
                                                      child: Text(lang.Lang.tr('delete')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            tooltip: lang.Lang.tr('delete'),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                        },
                        ),
                        ),
              ],
            ),
          ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                bottom: _showForm ? 0 : -600,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(14.0, 14.0, 14.0, MediaQuery.of(context).viewInsets.bottom + 14.0),
                  child: Card(
                    elevation: 2,
                    shadowColor: kTeal.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: kTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Iconsax.shopping_cart, color: kTeal, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(lang.Lang.tr('addNewProduct'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: kTeal.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: _selectedImage != null
                                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                      : Icon(Iconsax.camera, color: kTeal.withValues(alpha: 0.6), size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _productNameController,
                                  decoration: InputDecoration(
                                    labelText: lang.Lang.tr('productName'),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_isListening ? Iconsax.microphone : Iconsax.microphone_slash, color: _isListening ? Colors.red : Colors.grey.shade500),
                                onPressed: _listenVoice,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory,
                                        isExpanded: true,
                                        hint: Text(lang.Lang.tr('category')),
                                        items: _categories.toSet().toList().map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                        onChanged: (v) => setState(() => _selectedCategory = v),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedInvestor,
                                        isExpanded: true,
                                        hint: Text(lang.Lang.tr('investor')),
                                        items: _investors.toSet().toList().map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                        onChanged: (v) => setState(() => _selectedInvestor = v),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(controller: _buyQtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('buyQty'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedBuyUnit,
                                        isExpanded: true,
                                        hint: Text(lang.Lang.tr('buyUnit')),
                                        items: _units.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                        onChanged: (v) => setState(() => _selectedBuyUnit = v),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: TextField(controller: _buyPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('buyPrice'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                                const SizedBox(width: 10),
                                Expanded(child: TextField(controller: _sellPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('sellPrice'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedSellUnit,
                                        isExpanded: true,
                                        hint: Text(lang.Lang.tr('sellUnit')),
                                        items: _units.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                        onChanged: (v) => setState(() => _selectedSellUnit = v),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${lang.Lang.tr('stock')} (${_selectedSellUnit ?? "pcs"})', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                      labelText: lang.Lang.tr('noteOptional'),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                              onPressed: _addProductToStore,
                              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: kTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(lang.Lang.tr('saveProduct'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
          _buildAssetTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _showForm = !_showForm),
        child: Icon(_showForm ? Iconsax.close_circle : Iconsax.add),
      ),
      ),
    );
  }

  Widget _buildAssetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shadowColor: kTeal.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: kTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Iconsax.chart, color: kTeal, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(lang.Lang.tr('addNewAsset'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAssetImage,
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: _assetImage != null
                              ? Image.file(_assetImage!, fit: BoxFit.cover)
                              : Icon(Iconsax.camera, color: kTeal.withValues(alpha: 0.6), size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _assetNameController,
                          decoration: InputDecoration(
                            labelText: lang.Lang.tr('assetName'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _assetValueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.Lang.tr('estimatedValue'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kTeal)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                    onPressed: _addAsset,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: kTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(lang.Lang.tr('saveAsset'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(lang.Lang.tr('assetList'), Iconsax.box),
          const SizedBox(height: 12),
          _assets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: _buildEmptyState(Iconsax.box, lang.Lang.tr('noAssets'), lang.Lang.tr('addAnAsset')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      elevation: 2,
                      shadowColor: kTeal.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: kTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kTeal.withValues(alpha: 0.15)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: asset.image != null
                                  ? Image.file(asset.image!, fit: BoxFit.cover)
                                  : Icon(Iconsax.box, color: kTeal, size: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 3),
                                  Text('${lang.Lang.tr('dateLabel')}${asset.purchaseDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text('৳${asset.estimatedValue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: kTeal, fontSize: 14)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.trash, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: [
                                        Icon(Iconsax.trash, color: Colors.red.shade400, size: 22),
                                        const SizedBox(width: 10),
                                        Text(lang.Lang.tr('deleteAsset')),
                                      ],
                                    ),
                                    content: Text('${lang.Lang.tr('delete')} "${asset.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
            child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        onPressed: () {
                                          _deleteAsset(index);
                                          Navigator.pop(ctx);
                                        },
                                        child: Text(lang.Lang.tr('delete')),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final items = _filteredProducts;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    Map<String, Map<String, double>> categoryTotals = {};
    Map<String, Map<String, double>> investorTotals = {};

    for (final product in items) {
      final category = product['category']?.toString() ?? 'Other';
      final investor = product['investor']?.toString() ?? 'Own Shop';
      final buyPrice = double.tryParse(product['buyPrice']?.toString() ?? '0') ?? 0.0;
      double baseQty = double.tryParse(product['qty']?.toString() ?? '0') ?? 0.0;
      double buyConversionFactor = double.tryParse(product['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
      double sellConversionFactor = double.tryParse(product['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
      double displayQty = sellConversionFactor > 0 ? baseQty / sellConversionFactor : baseQty;
      final sellPrice = double.tryParse(product['sellPrice']?.toString() ?? '0') ?? 0.0;
      double cost = baseQty * (buyConversionFactor > 0 ? buyPrice / buyConversionFactor : 0);
      double revenue = displayQty * sellPrice;
      double profit = revenue - cost;

      categoryTotals.putIfAbsent(category, () => {'value': 0.0, 'profit': 0.0});
      categoryTotals[category]!['value'] = (categoryTotals[category]!['value'] ?? 0.0) + cost;
      categoryTotals[category]!['profit'] = (categoryTotals[category]!['profit'] ?? 0.0) + profit;

      investorTotals.putIfAbsent(investor, () => {'value': 0.0, 'profit': 0.0});
      investorTotals[investor]!['value'] = (investorTotals[investor]!['value'] ?? 0.0) + cost;
      investorTotals[investor]!['profit'] = (investorTotals[investor]!['profit'] ?? 0.0) + profit;
    }

    String title = _filterCategory ?? _filterInvestor ?? 'All';
    String filterLabel = _filterCategory != null ? 'Category' : _filterInvestor != null ? 'Investor' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filterLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6),
            child: Text('$filterLabel: $title', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kTeal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kTeal.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(lang.Lang.tr('products'), '${items.length}'),
              _buildSummaryItem(lang.Lang.tr('value'), '৳${(categoryTotals.values.fold(0.0, (sum, e) => sum + (e['value'] ?? 0.0))).toStringAsFixed(2)}'),
              _buildSummaryItem(lang.Lang.tr('profit'), '৳${(categoryTotals.values.fold(0.0, (sum, e) => sum + (e['profit'] ?? 0.0))).toStringAsFixed(2)}', isProfit: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isProfit = false}) {
    return GestureDetector(
      onTap: () => _showCardHint(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(width: 2),
                Icon(Iconsax.info_circle, size: 8, color: Colors.grey.shade400),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isProfit ? Colors.green : kTeal)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _noteController.dispose();
    _assetNameController.dispose();
    _assetValueController.dispose();
    _speech.cancel();
    super.dispose();
  }
}
