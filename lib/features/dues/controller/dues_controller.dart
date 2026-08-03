import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/date_utils.dart';

class DuesController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _imageService = ImageService();

  final customers = <Customer>[].obs;
  final selectedDate = Rxn<DateTime>();
  final showForm = false.obs;

  final todayDue = 0.0.obs;
  final monthlyDue = 0.0.obs;
  final totalDue = 0.0.obs;

  // Form
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final paymentCtrl = TextEditingController();
  final productSearchCtrl = TextEditingController();
  final filteredProducts = <Product>[].obs;
  final selectedProduct = Rxn<Product>();
  File? customerImage;

  CustomerDao get _customerDao => _db.customerDao;
  ProductDao get _productDao => _db.productDao;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    showForm.value = true;
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => showForm.value = false,
    );

    // Handle prefilled args from inventory credit sale
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['prefilledName'] != null) nameCtrl.text = args['prefilledName'];
      if (args['prefilledAmount'] != null)
        amountCtrl.text = args['prefilledAmount'].toString();
    }
  }

  Future<void> loadCustomers() async {
    customers.value = await _customerDao.getAll();
    calculateTotals();
  }

  void calculateTotals() {
    final todayStr = AppDateUtils.today();
    final currentMonth = DateFormat('MM-yyyy').format(DateTime.now());
    final filterStr = selectedDate.value != null
        ? AppDateUtils.format(selectedDate.value!)
        : null;
    _calculateFromLedger(todayStr, currentMonth, filterStr);
  }

  Future<void> _calculateFromLedger(
    String todayStr,
    String currentMonth,
    String? filterStr,
  ) async {
    double today = 0, monthly = 0, total = 0;

    for (final c in customers) {
      final ledger = await _customerDao.getLedger(c.id);
      for (final entry in ledger) {
        if (filterStr != null && entry.date != filterStr) continue;
        final amt = entry.amount;
        final sign = entry.type == 'payment' ? -1.0 : 1.0;
        if (entry.date == todayStr) today += amt * sign;
        if (entry.date.length >= 7 && entry.date.substring(3) == currentMonth)
          monthly += amt * sign;
        total += amt * sign;
      }
    }

    todayDue.value = today;
    monthlyDue.value = monthly;
    totalDue.value = total;
  }

  List<Customer> get filteredCustomers {
    if (selectedDate.value == null) return customers;
    // Would need async ledger check; for now return all
    return customers;
  }

  // --- Customer CRUD ---

  Future<void> addDueCustomer() async {
    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
    final today = AppDateUtils.today();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await _customerDao.insertCustomer(
      CustomersCompanion.insert(
        id: id,
        name: nameCtrl.text,
        phone: Value(phoneCtrl.text),
        imagePath: Value(customerImage?.path ?? ''),
        note: Value(noteCtrl.text),
        type: const Value('due_taker'),
      ),
    );

    if (amt > 0) {
      await _customerDao.addLedgerEntry(
        LedgerEntriesCompanion.insert(
          customerId: id,
          date: today,
          amount: amt,
          type: 'due',
          itemName: Value(selectedProduct.value?.name ?? ''),
          imagePath: Value(selectedProduct.value?.imagePath ?? ''),
          note: Value(noteCtrl.text),
        ),
      );
    }

    _clearForm();
    await loadCustomers();
  }

  Future<void> receivePayment(Customer customer, double amount) async {
    if (amount <= 0) return;
    await _customerDao.addLedgerEntry(
      LedgerEntriesCompanion.insert(
        customerId: customer.id,
        date: AppDateUtils.today(),
        amount: amount,
        type: 'payment',
      ),
    );
    paymentCtrl.clear();
    await loadCustomers();
    Get.snackbar(
      '',
      'paymentSaved'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> editCustomer(
    Customer customer,
    String name,
    String phone,
    File? image,
  ) async {
    await _customerDao.updateCustomer(
      customer.id,
      CustomersCompanion(
        name: Value(name),
        phone: Value(phone),
        imagePath: Value(image?.path ?? customer.imagePath),
      ),
    );
    await loadCustomers();
  }

  // --- Ledger helpers ---

  Future<List<LedgerEntry>> getLedger(String customerId) =>
      _customerDao.getLedger(customerId);

  Future<double> getOutstanding(String customerId) async {
    final ledger = await _customerDao.getLedger(customerId);
    double due = 0, paid = 0;
    for (final e in ledger) {
      if (e.type == 'due')
        due += e.amount;
      else
        paid += e.amount;
    }
    return due - paid;
  }

  Future<double> getMonthlyPayback(String customerId) async {
    final ledger = await _customerDao.getLedger(customerId);
    final currentMonth = DateFormat('MM-yyyy').format(DateTime.now());
    double total = 0;
    for (final e in ledger) {
      if (e.type == 'payment' &&
          e.date.length >= 7 &&
          e.date.substring(3) == currentMonth) {
        total += e.amount;
      }
    }
    return total;
  }

  // --- Product search ---

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

  void selectProduct(Product product) {
    selectedProduct.value = product;
    productSearchCtrl.text = product.name;
    filteredProducts.clear();
    amountCtrl.text = product.sellPrice.toString();
  }

  // --- Image ---

  Future<void> pickCustomerImage() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) {
      customerImage = file;
      update();
    }
  }

  // --- Date filter ---

  Future<void> pickDate() async {
    final picked = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      ),
    );
    if (picked != null) {
      selectedDate.value = picked;
      calculateTotals();
    }
  }

  void clearDateFilter() {
    selectedDate.value = null;
    calculateTotals();
  }

  void _clearForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    amountCtrl.clear();
    noteCtrl.clear();
    productSearchCtrl.clear();
    customerImage = null;
    selectedProduct.value = null;
    filteredProducts.clear();
    update();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
    paymentCtrl.dispose();
    productSearchCtrl.dispose();
    super.onClose();
  }
}
