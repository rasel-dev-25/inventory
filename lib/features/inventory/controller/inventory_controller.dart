import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;
import 'package:iconsax/iconsax.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/daos/sale_dao.dart';
import '../../../../core/database/daos/investor_dao.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/unit_conversion.dart';
import '../../../../app/theme/app_colors.dart';

class InventoryController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _imageService = ImageService();

  // Reactive state
  final products = <Product>[].obs;
  final categories = <String>[].obs;
  final investors = <String>[].obs;
  final filterCategory = Rxn<String>();
  final filterInvestor = Rxn<String>();
  final showForm = false.obs;
  final isListening = false.obs;
  final buyerCustomers = <Customer>[].obs;

  // Form controllers
  final productNameCtrl = TextEditingController();
  final buyQtyCtrl = TextEditingController();
  final buyPriceCtrl = TextEditingController();
  final sellPriceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final selectedCategory = Rxn<String>();
  final selectedInvestor = Rxn<String>();
  final selectedBuyUnit = Rxn<String>();
  final selectedSellUnit = Rxn<String>();
  File? selectedImage;

  stt.SpeechToText? _speech;
  bool _speechInitialized = false;

  static const double lowStockThreshold = 5.0;

  ProductDao get _productDao => _db.productDao;
  SaleDao get _saleDao => _db.saleDao;
  InvestorDao get _investorDao => _db.investorDao;
  CustomerDao get _customerDao => _db.customerDao;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    loadInvestors();
    _loadBuyers();
    showForm.value = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      showForm.value = false;
    });
  }

  // --- Data Loading ---

  Future<void> loadProducts() async {
    products.value = await _productDao.getAll();
  }

  Future<void> loadCategories() async {
    final cats = await _productDao.getCategories();
    categories.value = cats.map((c) => c.name).toList();
  }

  Future<void> loadInvestors() async {
    final invList = await _investorDao.getAll();
    final names = invList.map((i) => i.name).where((n) => n.isNotEmpty).toSet();
    // Also collect investor names from products
    for (final p in products) {
      if (p.investor.isNotEmpty) names.add(p.investor);
    }
    names.add('Own Shop');
    investors.value = names.toList();
    if (!investors.contains('Own Shop')) investors.insert(0, 'Own Shop');
  }

  Future<void> _loadBuyers() async {
    final all = await _customerDao.getAll();
    buyerCustomers.value = all.where((c) => c.type == 'buyer').toList();
  }

  // --- Filtered Products ---

  List<Product> get filteredProducts {
    return products.where((p) {
      final matchCat =
          filterCategory.value == null || p.category == filterCategory.value;
      final matchInv =
          filterInvestor.value == null || p.investor == filterInvestor.value;
      return matchCat && matchInv;
    }).toList();
  }

  // --- Product CRUD ---

  Future<void> addProduct() async {
    if (productNameCtrl.text.isEmpty ||
        buyQtyCtrl.text.isEmpty ||
        buyPriceCtrl.text.isEmpty ||
        sellPriceCtrl.text.isEmpty) {
      Get.snackbar(
        '',
        'fillRequired'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final buyQty = double.tryParse(buyQtyCtrl.text) ?? 0.0;
    final buyPrice = double.tryParse(buyPriceCtrl.text) ?? 0.0;
    final sellPrice = double.tryParse(sellPriceCtrl.text) ?? 0.0;
    final buyUnit = selectedBuyUnit.value ?? 'pcs';
    final sellUnit = selectedSellUnit.value ?? buyUnit;
    final buyConvFactor = UnitConversion.factorFor(buyUnit);
    final sellConvFactor = UnitConversion.factorFor(sellUnit);
    final stockInput = double.tryParse(stockCtrl.text) ?? 0.0;
    final baseQty = stockInput > 0
        ? stockInput * sellConvFactor
        : buyQty * buyConvFactor;

    await _productDao.insertProduct(
      ProductsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: Value(selectedCategory.value ?? 'Other'),
        investor: Value(selectedInvestor.value ?? 'Own Shop'),
        name: productNameCtrl.text,
        buyQty: Value(buyQty),
        buyUnit: Value(buyUnit),
        buyPrice: Value(buyPrice),
        sellUnit: Value(sellUnit),
        sellPrice: Value(sellPrice),
        qty: Value(baseQty),
        buyConversionFactor: Value(buyConvFactor),
        sellConversionFactor: Value(sellConvFactor),
        date: AppDateUtils.today(),
        imagePath: Value(selectedImage?.path ?? ''),
      ),
    );

    _clearForm();
    await loadProducts();
    await loadInvestors();
  }

  Future<void> updateProduct(
    Product product, {
    required String name,
    required String category,
    required String investor,
    required double buyQty,
    required String buyUnit,
    required double buyPrice,
    required String sellUnit,
    required double sellPrice,
    required double stockQty,
  }) async {
    final buyConvFactor = UnitConversion.factorFor(buyUnit);
    final sellConvFactor = UnitConversion.factorFor(sellUnit);

    await _productDao.updateProduct(
      product.id,
      ProductsCompanion(
        name: Value(name),
        category: Value(category),
        investor: Value(investor),
        buyQty: Value(buyQty),
        buyUnit: Value(buyUnit),
        buyPrice: Value(buyPrice),
        sellUnit: Value(sellUnit),
        sellPrice: Value(sellPrice),
        qty: Value(stockQty * sellConvFactor),
        buyConversionFactor: Value(buyConvFactor),
        sellConversionFactor: Value(sellConvFactor),
      ),
    );
    await loadProducts();
    await loadInvestors();
  }

  Future<void> deleteProduct(String id) async {
    await _productDao.deleteProduct(id);
    await loadProducts();
    await loadInvestors();
  }

  void _clearForm() {
    productNameCtrl.clear();
    buyQtyCtrl.clear();
    buyPriceCtrl.clear();
    sellPriceCtrl.clear();
    stockCtrl.clear();
    noteCtrl.clear();
    selectedImage = null;
    selectedCategory.value = null;
    selectedInvestor.value = null;
    selectedBuyUnit.value = null;
    selectedSellUnit.value = null;
    update();
  }

  // --- Image & Voice ---

  Future<void> pickImage() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) {
      selectedImage = file;
      update();
    }
  }

  Future<void> toggleVoice() async {
    _speech ??= stt.SpeechToText();
    if (!isListening.value) {
      if (!_speechInitialized) {
        _speechInitialized = await _speech!.initialize();
        if (!_speechInitialized) return;
      }
      isListening.value = true;
      _speech!.listen(
        onResult: (val) {
          productNameCtrl.text = val.recognizedWords;
          if (val.hasConfidenceRating && val.confidence > 0) {
            isListening.value = false;
          }
        },
      );
    } else {
      isListening.value = false;
      _speech!.stop();
    }
  }

  // --- Category ---

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || categories.contains(trimmed)) return;
    await _productDao.addCategory(trimmed);
    await loadCategories();
  }

  void showAddCategoryDialog() {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.category, color: kTeal, size: 22),
            const SizedBox(width: 10),
            Text('addNewCategory'.tr),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'enterCategoryName'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              addCategory(ctrl.text);
              Get.back();
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  // --- Sell ---

  double displayQty(Product p) {
    return p.sellConversionFactor > 0 ? p.qty / p.sellConversionFactor : p.qty;
  }

  void processSale(Product product, bool isCredit) {
    final dq = displayQty(product);
    if (dq <= 0) {
      Get.snackbar(
        '',
        'stockFinished'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    _showSaleDialog(product, dq, isCredit);
  }

  void _showSaleDialog(Product product, double maxQty, bool isCredit) {
    final qtyCtrl = TextEditingController(text: '1');
    bool selectedIsCredit = isCredit;
    String? selectedBuyer;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kTeal.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.bag,
                              color: kTeal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '৳${product.sellPrice.toStringAsFixed(2)} / ${product.sellUnit}  •  Available: ${maxQty.toStringAsFixed(2)} ${product.sellUnit}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
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
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${'quantity'.tr} (max ${maxQty.toStringAsFixed(2)} ${product.sellUnit})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('cash'.tr),
                          selected: !selectedIsCredit,
                          onSelected: (_) =>
                              setSheetState(() => selectedIsCredit = false),
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: !selectedIsCredit
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: Text('credit'.tr),
                          selected: selectedIsCredit,
                          onSelected: (_) =>
                              setSheetState(() => selectedIsCredit = true),
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: selectedIsCredit
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final qty = double.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0 || qty > maxQty) {
                            Get.snackbar(
                              '',
                              'invalidQty'.tr,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          _completeSale(
                            product,
                            qty,
                            selectedIsCredit,
                            selectedBuyer,
                          );
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedIsCredit
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedIsCredit
                              ? 'sellOnCredit'.tr
                              : 'completeSale'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      isScrollControlled: true,
    );
  }

  Future<void> _completeSale(
    Product product,
    double qty,
    bool isCredit,
    String? buyerName,
  ) async {
    final baseQtyToSell = qty * product.sellConversionFactor;
    final costPerBaseUnit = product.buyConversionFactor > 0
        ? product.buyPrice / product.buyConversionFactor
        : 0.0;
    final costOfGoodsSold = costPerBaseUnit * baseQtyToSell;
    final amount = product.sellPrice * qty;
    final profit = amount - costOfGoodsSold;
    final today = AppDateUtils.today();

    // Deduct stock
    await _productDao.updateQty(product.id, product.qty - baseQtyToSell);

    // Record sale
    await _saleDao.insertSale(
      SalesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: today,
        productName: product.name,
        amount: amount,
        profit: Value(profit),
        type: Value(isCredit ? 'credit' : 'cash'),
      ),
    );

    if (isCredit) {
      // Navigate to dues with prefilled data
      Get.toNamed(
        '/dues',
        arguments: {
          'prefilledName': product.name,
          'prefilledAmount': amount,
          'itemName': product.name,
        },
      );
    } else {
      // Cash sale — no additional action needed, Drift has the sale record
    }

    // Investor profit split
    await _triggerInvestorProfitSplit(
      product.investor,
      costOfGoodsSold,
      amount,
    );

    // Record buyer purchase
    if (!isCredit && buyerName != null && buyerName.isNotEmpty) {
      final customers = await _customerDao.getAll();
      final buyer = customers
          .where((c) => c.name == buyerName && c.type == 'buyer')
          .firstOrNull;
      if (buyer != null) {
        await _customerDao.addPurchase(
          CustomerPurchasesCompanion.insert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            customerId: buyer.id,
            productName: product.name,
            price: amount,
            date: today,
          ),
        );
      }
    }

    await loadProducts();
  }

  Future<void> _triggerInvestorProfitSplit(
    String investorName,
    double cost,
    double revenue,
  ) async {
    final netProfit = revenue - cost;
    if (netProfit <= 0) return;

    final allInvestors = await _investorDao.getAll();

    if (investorName != 'Own Shop') {
      final inv = allInvestors.where((i) => i.name == investorName).firstOrNull;
      if (inv != null) {
        final share = netProfit * (inv.profitPercentage / 100);
        await _investorDao.updateInvestor(
          inv.id,
          InvestorsCompanion(
            dailyEarnings: Value(inv.dailyEarnings + share),
            monthlyEarnings: Value(inv.monthlyEarnings + share),
          ),
        );
      }
    }
  }

  // --- Summary ---

  Map<String, double> get summary {
    final items = filteredProducts;
    double totalValue = 0;
    double totalProfit = 0;
    for (final p in items) {
      final cost =
          p.qty *
          (p.buyConversionFactor > 0 ? p.buyPrice / p.buyConversionFactor : 0);
      final dq = displayQty(p);
      final revenue = dq * p.sellPrice;
      totalValue += cost;
      totalProfit += revenue - cost;
    }
    return {
      'count': items.length.toDouble(),
      'value': totalValue,
      'profit': totalProfit,
    };
  }

  @override
  void onClose() {
    productNameCtrl.dispose();
    buyQtyCtrl.dispose();
    buyPriceCtrl.dispose();
    sellPriceCtrl.dispose();
    stockCtrl.dispose();
    noteCtrl.dispose();
    _speech?.cancel();
    super.onClose();
  }
}
