import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/expense_dao.dart';
import '../../../../core/database/daos/purchase_dao.dart';
import '../../../../core/database/daos/investor_dao.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/date_utils.dart';

class FinanceController extends GetxController {
  final _db = Get.find<AppDatabase>();
  final _imageService = ImageService();

  final expenses = <Expense>[].obs;
  final purchases = <Purchase>[].obs;
  final investorNames = <String>[].obs;
  final selectedDate = Rxn<DateTime>();
  final showForm = false.obs;
  final tabIndex = 0.obs;

  // Expense form
  final expAmount = TextEditingController();
  final expNote = TextEditingController();
  final expVendor = TextEditingController();
  final expCategory = 'Other'.obs;
  final expPaymentMethod = 'Cash'.obs;
  final expRecurring = 'none'.obs;
  final expIsPaid = false.obs;
  File? billFile;

  // Purchase form
  final purCashTaken = TextEditingController();
  final purReturnedCash = TextEditingController();
  final purNotes = TextEditingController();
  final purItemShop = TextEditingController();
  final purItemName = TextEditingController();
  final purItemQty = TextEditingController();
  final purItemPrice = TextEditingController();
  final purVehicle = TextEditingController();
  final purCost = TextEditingController();
  final purOtherDesc = TextEditingController();
  final purOtherCost = TextEditingController();
  final purSource = 'cash'.obs;
  final tempItems = <PurchaseItem>[].obs;
  final tempTransport = <TransportCost>[].obs;
  final tempOtherCosts = <OtherCost>[].obs;
  File? purMemoFile;

  ExpenseDao get _expenseDao => _db.expenseDao;
  PurchaseDao get _purchaseDao => _db.purchaseDao;
  InvestorDao get _investorDao => _db.investorDao;

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
    loadPurchases();
    loadInvestorNames();
    showForm.value = true;
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => showForm.value = false,
    );
  }

  Future<void> loadExpenses() async {
    expenses.value = await _expenseDao.getAll();
  }

  Future<void> loadPurchases() async {
    purchases.value = await _purchaseDao.getAll();
  }

  Future<void> loadInvestorNames() async {
    final invList = await _investorDao.getAll();
    investorNames.value = invList
        .map((i) => i.name)
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // --- Expense CRUD ---

  Future<void> addExpense(String type) async {
    if (expAmount.text.isEmpty) return;
    await _expenseDao.insertExpense(
      ExpensesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: Value(type),
        title: expCategory.value,
        amount: double.tryParse(expAmount.text) ?? 0,
        date: AppDateUtils.today(),
        billPath: Value(billFile?.path ?? ''),
        note: Value(expNote.text),
        vendor: Value(expVendor.text),
        paymentMethod: Value(expPaymentMethod.value),
        isPaid: Value(expIsPaid.value),
        recurringType: Value(expRecurring.value),
      ),
    );
    _clearExpenseForm();
    await loadExpenses();
  }

  Future<void> updateExpense(
    String id, {
    required String title,
    required double amount,
    String note = '',
    String vendor = '',
    String paymentMethod = 'Cash',
    bool isPaid = false,
  }) async {
    await _expenseDao.updateExpense(
      id,
      ExpensesCompanion(
        title: Value(title),
        amount: Value(amount),
        note: Value(note),
        vendor: Value(vendor),
        paymentMethod: Value(paymentMethod),
        isPaid: Value(isPaid),
      ),
    );
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseDao.deleteExpense(id);
    await loadExpenses();
  }

  Future<void> markExpensePaid(String id) async {
    await _expenseDao.markPaid(id);
    await loadExpenses();
  }

  void _clearExpenseForm() {
    expAmount.clear();
    expNote.clear();
    expVendor.clear();
    expCategory.value = 'Other';
    expPaymentMethod.value = 'Cash';
    expRecurring.value = 'none';
    expIsPaid.value = false;
    billFile = null;
    update();
  }

  Future<void> pickBillImage() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) {
      billFile = file;
      update();
    }
  }

  // --- Purchase CRUD ---

  void addTempItem() {
    if (purItemShop.text.isEmpty || purItemName.text.isEmpty) return;
    tempItems.add(
      PurchaseItem(
        id: 0,
        purchaseId: '',
        shopName: purItemShop.text,
        itemName: purItemName.text,
        quantity: double.tryParse(purItemQty.text) ?? 1,
        unitPrice: double.tryParse(purItemPrice.text) ?? 0,
      ),
    );
    purItemShop.clear();
    purItemName.clear();
    purItemQty.clear();
    purItemPrice.clear();
  }

  void removeTempItem(int index) => tempItems.removeAt(index);

  void addTempTransport() {
    if (purVehicle.text.isEmpty) return;
    tempTransport.add(
      TransportCost(
        id: 0,
        purchaseId: '',
        vehicle: purVehicle.text,
        cost: double.tryParse(purCost.text) ?? 0,
      ),
    );
    purVehicle.clear();
    purCost.clear();
  }

  void removeTempTransport(int index) => tempTransport.removeAt(index);

  void addTempOtherCost() {
    if (purOtherDesc.text.isEmpty) return;
    tempOtherCosts.add(
      OtherCost(
        id: 0,
        purchaseId: '',
        description: purOtherDesc.text,
        cost: double.tryParse(purOtherCost.text) ?? 0,
      ),
    );
    purOtherDesc.clear();
    purOtherCost.clear();
  }

  void removeTempOtherCost(int index) => tempOtherCosts.removeAt(index);

  Future<void> pickPurMemo() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) {
      purMemoFile = file;
      update();
    }
  }

  double get itemsTotal =>
      tempItems.fold(0.0, (s, i) => s + (i.quantity * i.unitPrice));
  double get transportTotal => tempTransport.fold(0.0, (s, t) => s + t.cost);
  double get otherTotal => tempOtherCosts.fold(0.0, (s, o) => s + o.cost);
  double get grandTotal => itemsTotal + transportTotal + otherTotal;

  Future<void> savePurchase() async {
    if (tempItems.isEmpty) return;
    final cashTaken = double.tryParse(purCashTaken.text) ?? 0.0;
    final returnedCash = double.tryParse(purReturnedCash.text) ?? 0.0;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    String? investorId;
    if (purSource.value.startsWith('investor:')) {
      investorId = purSource.value.substring(9);
    }

    await _purchaseDao.insertPurchase(
      PurchasesCompanion.insert(
        id: id,
        date: AppDateUtils.today(),
        source: Value(purSource.value),
        cashTaken: Value(cashTaken),
        investorId: Value(investorId ?? ''),
        notes: Value(purNotes.text),
        memoPhotoPath: Value(purMemoFile?.path ?? ''),
        returnedCash: Value(returnedCash),
      ),
    );

    for (final item in tempItems) {
      await _purchaseDao.addItem(
        PurchaseItemsCompanion.insert(
          purchaseId: id,
          shopName: Value(item.shopName),
          itemName: item.itemName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        ),
      );
    }
    for (final t in tempTransport) {
      await _purchaseDao.addTransport(
        TransportCostsCompanion.insert(
          purchaseId: id,
          vehicle: t.vehicle,
          cost: t.cost,
        ),
      );
    }
    for (final o in tempOtherCosts) {
      await _purchaseDao.addOtherCost(
        OtherCostsCompanion.insert(
          purchaseId: id,
          description: o.description,
          cost: o.cost,
        ),
      );
    }

    // Update investor balance if linked
    if (investorId != null) {
      final netUsed = cashTaken - returnedCash;
      if (netUsed > 0) {
        final inv = await _investorDao.getById(investorId);
        if (inv != null) {
          await _investorDao.updateInvestor(
            investorId,
            InvestorsCompanion(
              investedAmount: Value(inv.investedAmount + netUsed),
            ),
          );
        }
      }
    }

    _clearPurchaseForm();
    await loadPurchases();
  }

  Future<void> deletePurchase(String id) async {
    await _purchaseDao.deletePurchase(id);
    await loadPurchases();
  }

  void _clearPurchaseForm() {
    tempItems.clear();
    tempTransport.clear();
    tempOtherCosts.clear();
    purCashTaken.clear();
    purReturnedCash.clear();
    purNotes.clear();
    purMemoFile = null;
    purSource.value = 'cash';
    update();
  }

  // --- Summary ---

  double get totalExpenses => expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalPurchases => purchases.fold(0.0, (s, p) => s + p.cashTaken);

  @override
  void onClose() {
    expAmount.dispose();
    expNote.dispose();
    expVendor.dispose();
    purCashTaken.dispose();
    purReturnedCash.dispose();
    purNotes.dispose();
    purItemShop.dispose();
    purItemName.dispose();
    purItemQty.dispose();
    purItemPrice.dispose();
    purVehicle.dispose();
    purCost.dispose();
    purOtherDesc.dispose();
    purOtherCost.dispose();
    super.onClose();
  }
}
