import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sale_dao.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/daos/rental_dao.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/utils/date_utils.dart';

class DailySalesController extends GetxController {
  final _db = Get.find<AppDatabase>();

  final sales = <Sale>[].obs;
  final rentBooks = <RentBook>[].obs;
  final bookRentals = <BookRental>[].obs;
  final filteredProducts = <Product>[].obs;
  final selectedProduct = Rxn<Product>();
  final showForm = false.obs;
  final tabIndex = 0.obs;
  final isCredit = false.obs;
  final selectedBuyer = Rxn<String>();
  final selectedDate = Rxn<DateTime>();
  final buyerCustomers = <Customer>[].obs;

  // Sale form
  final productSearchCtrl = TextEditingController();
  final quickSaleCtrl = TextEditingController();
  final salesSearchCtrl = TextEditingController();
  final salesSearchQuery = ''.obs;

  // Rent form
  final bookNameCtrl = TextEditingController();
  final pageCountCtrl = TextEditingController();
  final copiesCtrl = TextEditingController(text: '1');
  final rentCustomerCtrl = TextEditingController();
  final rentDaysCtrl = TextEditingController(text: '10');
  final selectedRentBook = Rxn<String>();

  SaleDao get _saleDao => _db.saleDao;
  ProductDao get _productDao => _db.productDao;
  RentalDao get _rentalDao => _db.rentalDao;
  CustomerDao get _customerDao => _db.customerDao;

  @override
  void onInit() {
    super.onInit();
    loadSales();
    loadRentData();
    loadBuyers();
    showForm.value = true;
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => showForm.value = false,
    );
  }

  Future<void> loadBuyers() async {
    final all = await _customerDao.getAll();
    buyerCustomers.value = all.where((c) => c.type == 'buyer').toList();
  }

  Future<void> pickDate() async {
    final picked = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ),
    );
    if (picked != null) selectedDate.value = picked;
  }

  Future<void> loadSales() async {
    sales.value = await _saleDao.getAll();
  }

  Future<void> loadRentData() async {
    rentBooks.value = await _rentalDao.getBooks();
    bookRentals.value = await _rentalDao.getRentals();
  }

  List<Sale> get filteredSales {
    final q = salesSearchQuery.value.toLowerCase();
    if (q.isEmpty) return sales;
    return sales.where((s) => s.productName.toLowerCase().contains(q)).toList();
  }

  List<BookRental> get activeRentals =>
      bookRentals.where((r) => r.dateReturned.isEmpty).toList();

  // --- Sales ---

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      filteredProducts.clear();
      return;
    }
    final all = await _productDao.getAll();
    filteredProducts.value = all
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void selectProduct(Product p) {
    selectedProduct.value = p;
    productSearchCtrl.text = p.name;
    filteredProducts.clear();
  }

  Future<void> addQuickSale(double qty, {String? buyerName}) async {
    final product = selectedProduct.value;
    if (product == null || qty <= 0) return;

    final amount = qty * product.sellPrice;
    final costPerBase = product.buyConversionFactor > 0
        ? product.buyPrice / product.buyConversionFactor
        : 0.0;
    final baseQtySold = qty * product.sellConversionFactor;
    final profit = amount - (costPerBase * baseQtySold);
    final today = AppDateUtils.today();
    final isCredit = buyerName != null && buyerName.isNotEmpty;

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

    // Deduct stock
    await _productDao.updateQty(product.id, product.qty - baseQtySold);

    quickSaleCtrl.clear();
    productSearchCtrl.clear();
    selectedProduct.value = null;
    await loadSales();
  }

  Future<void> deleteSale(String id) async {
    await _saleDao.deleteSale(id);
    await loadSales();
  }

  // --- Rent Books ---

  Future<void> addRentBook() async {
    final name = bookNameCtrl.text.trim();
    final pages = int.tryParse(pageCountCtrl.text) ?? 0;
    final copies = int.tryParse(copiesCtrl.text) ?? 1;
    if (name.isEmpty || pages <= 0) return;

    await _rentalDao.addBook(
      RentBooksCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        pageCount: Value(pages),
        copies: Value(copies),
      ),
    );
    bookNameCtrl.clear();
    pageCountCtrl.clear();
    copiesCtrl.text = '1';
    await loadRentData();
  }

  Future<void> deleteRentBook(String id) async {
    await _rentalDao.deleteBook(id);
    await loadRentData();
  }

  double rentPrice(int pageCount, int days) {
    final rate = ((pageCount - 1) ~/ 100 + 1) * 10.0;
    final periods = ((days - 1) ~/ 10 + 1);
    return rate * periods;
  }

  Future<void> rentOutBook() async {
    final bookName = selectedRentBook.value;
    final customer = rentCustomerCtrl.text.trim();
    final days = int.tryParse(rentDaysCtrl.text) ?? 10;
    if (bookName == null || customer.isEmpty) return;

    final book = rentBooks.where((b) => b.name == bookName).firstOrNull;
    if (book == null) return;

    final cost = rentPrice(book.pageCount, days);
    final today = AppDateUtils.today();

    await _rentalDao.addRental(
      BookRentalsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookName: bookName,
        pageCount: Value(book.pageCount),
        customerName: customer,
        dateTaken: today,
        expectedReturn: AppDateUtils.daysFromNow(days),
        cost: Value(cost),
      ),
    );

    // Auto-create renter customer if not exists
    final existing = await _customerDao.getAll();
    final exists = existing.any(
      (c) => c.name.toLowerCase() == customer.toLowerCase(),
    );
    if (!exists) {
      await _customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: customer,
          type: const Value('renter'),
        ),
      );
    }

    rentCustomerCtrl.clear();
    selectedRentBook.value = null;
    await loadRentData();
  }

  Future<void> returnBook(String id) async {
    await _rentalDao.markReturned(id, AppDateUtils.today());
    await loadRentData();
  }

  Future<void> toggleRentPaid(String id) async {
    final rental = bookRentals.where((r) => r.id == id).firstOrNull;
    if (rental == null) return;
    if (rental.isPaid) {
      await _rentalDao.updateRental(
        id,
        const BookRentalsCompanion(isPaid: Value(false)),
      );
    } else {
      await _rentalDao.markPaid(id);
    }
    await loadRentData();
  }

  @override
  void onClose() {
    productSearchCtrl.dispose();
    quickSaleCtrl.dispose();
    salesSearchCtrl.dispose();
    bookNameCtrl.dispose();
    pageCountCtrl.dispose();
    copiesCtrl.dispose();
    rentCustomerCtrl.dispose();
    rentDaysCtrl.dispose();
    super.onClose();
  }
}
