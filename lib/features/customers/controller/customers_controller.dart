import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;
import 'package:iconsax/iconsax.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../app/theme/app_colors.dart';

class CustomersController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _imageService = ImageService();

  final customers = <Customer>[].obs;
  final customerTypes = <CustomerType>[].obs;
  final selectedType = 'buyer'.obs;
  final showForm = false.obs;

  // Quick add form
  final formNameCtrl = TextEditingController();
  final formPhoneCtrl = TextEditingController();
  final formNoteCtrl = TextEditingController();
  final formType = 'buyer'.obs;

  CustomerDao get _dao => _db.customerDao;

  static const typeIcons = {
    'buyer': Iconsax.bag,
    'order_giver': Iconsax.task,
    'renter': Iconsax.book,
    'due_taker': Iconsax.card,
    'prospective': Iconsax.profile_add,
  };

  @override
  void onInit() {
    super.onInit();
    loadTypes();
    loadCustomers();
    showForm.value = true;
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => showForm.value = false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => checkOrderDeadlines());
  }

  Future<void> loadCustomers() async {
    customers.value = await _dao.getAll();
  }

  Future<void> loadTypes() async {
    customerTypes.value = await _dao.getTypes();
  }

  List<Customer> get filtered =>
      customers.where((c) => c.type == selectedType.value).toList();

  IconData iconFor(String typeId) => typeIcons[typeId] ?? Iconsax.folder;

  String labelFor(String typeId) {
    const map = {
      'buyer': 'buyers',
      'order_giver': 'orderGivers',
      'renter': 'renters',
      'due_taker': 'dueTakers',
      'prospective': 'prospective',
    };
    return (map[typeId] ?? typeId).tr;
  }

  // --- Customer CRUD ---

  Future<void> addCustomer({
    required String name,
    String phone = '',
    String whatsapp = '',
    String note = '',
    String address = '',
    String type = 'buyer',
    File? image,
  }) async {
    if (name.isEmpty) return;
    await _dao.insertCustomer(
      CustomersCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: Value(phone),
        whatsapp: Value(whatsapp),
        note: Value(note),
        address: Value(address),
        type: Value(type),
        imagePath: Value(image?.path ?? ''),
      ),
    );
    await loadCustomers();
  }

  void saveFromForm() {
    if (formNameCtrl.text.isEmpty) return;
    addCustomer(
      name: formNameCtrl.text,
      phone: formPhoneCtrl.text,
      note: formNoteCtrl.text,
      type: formType.value,
    );
    formNameCtrl.clear();
    formPhoneCtrl.clear();
    formNoteCtrl.clear();
    showForm.value = false;
  }

  Future<void> updateCustomer(
    Customer c, {
    required String name,
    required String phone,
    String whatsapp = '',
    String note = '',
    String address = '',
    File? image,
  }) async {
    await _dao.updateCustomer(
      c.id,
      CustomersCompanion(
        name: Value(name),
        phone: Value(phone),
        whatsapp: Value(whatsapp),
        note: Value(note),
        address: Value(address),
        imagePath: Value(image?.path ?? c.imagePath),
      ),
    );
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _dao.deleteCustomer(id);
    await loadCustomers();
  }

  void confirmDelete(Customer c) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'deleteCustomer'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
        ),
        content: Text('${'delete'.tr} "${c.name}"? ${'cannotBeUndone'.tr}.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              deleteCustomer(c.id);
              Get.back();
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  // --- Customer Types ---

  Future<void> addType(String label, int iconIndex) async {
    if (label.isEmpty) return;
    final id = label.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _dao.addType(
      CustomerTypesCompanion.insert(
        id: id,
        label: label,
        iconIndex: Value(iconIndex),
      ),
    );
    await loadTypes();
    selectedType.value = id;
  }

  // --- Purchases ---

  Future<void> addPurchase(
    Customer c,
    String productName,
    double price,
    String date,
  ) async {
    await _dao.addPurchase(
      CustomerPurchasesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: c.id,
        productName: productName,
        price: price,
        date: date,
      ),
    );
    await loadCustomers();
  }

  Future<List<CustomerPurchase>> getPurchases(String customerId) =>
      _dao.getPurchases(customerId);

  // --- Orders ---

  Future<void> addOrder(
    Customer c,
    String description,
    String dateNeeded,
  ) async {
    await _dao.addOrder(
      CustomerOrdersCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: c.id,
        description: description,
        dateGiven: AppDateUtils.today(),
        dateNeeded: dateNeeded,
      ),
    );
    await loadCustomers();
  }

  Future<void> markOrderFulfilled(String orderId) async {
    await _dao.updateOrder(
      orderId,
      CustomerOrdersCompanion(
        status: const Value('fulfilled'),
        dateTaken: Value(AppDateUtils.today()),
      ),
    );
    await loadCustomers();
  }

  Future<void> markOrderCancelled(String orderId) async {
    await _dao.updateOrder(
      orderId,
      CustomerOrdersCompanion(
        status: const Value('cancelled'),
        dateTaken: Value(AppDateUtils.today()),
      ),
    );
    await loadCustomers();
  }

  Future<List<CustomerOrder>> getOrders(String customerId) =>
      _dao.getOrders(customerId);

  void checkOrderDeadlines() {
    // Will be implemented with async order loading
  }

  // --- Ledger (for due_taker type) ---

  Future<List<LedgerEntry>> getLedger(String customerId) =>
      _dao.getLedger(customerId);

  Future<double> getOutstanding(String customerId) async {
    final ledger = await _dao.getLedger(customerId);
    double due = 0, paid = 0;
    for (final e in ledger) {
      if (e.type == 'due') {
        due += e.amount;
      } else {
        paid += e.amount;
      }
    }
    return due - paid;
  }

  // --- Image ---

  Future<File?> pickImage() => _imageService.pickFromCamera();

  @override
  void onClose() {
    formNameCtrl.dispose();
    formPhoneCtrl.dispose();
    formNoteCtrl.dispose();
    super.onClose();
  }
}
