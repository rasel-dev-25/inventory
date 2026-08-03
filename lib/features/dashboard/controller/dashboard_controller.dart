import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/daos/sale_dao.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/database/daos/expense_dao.dart';
import '../../../../core/database/daos/purchase_dao.dart';
import '../../../../core/database/daos/rental_dao.dart';
import '../../../../core/database/daos/asset_dao.dart';
import '../../../../core/database/daos/investor_dao.dart';

class DashboardController extends GetxController {
  final _db = Get.find<AppDatabase>();

  final totalCash = 0.0.obs;
  final stockValue = 0.0.obs;
  final netProfit = 0.0.obs;
  final totalSell = 0.0.obs;
  final totalBuy = 0.0.obs;
  final totalDue = 0.0.obs;
  final duePaid = 0.0.obs;
  final totalExpense = 0.0.obs;
  final rentDue = 0.0.obs;
  final rentPaid = 0.0.obs;
  final totalAssets = 0.0.obs;
  final toGiveAway = 0.0.obs;
  final todaySalesCount = 0.obs;
  final currentDate = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final showOtherActivities = false.obs;

  // Activities for selected date
  final dateExpenses = <Map<String, dynamic>>[].obs;
  final datePurchases = <Map<String, dynamic>>[].obs;
  final dateInvestorRepayments = <Map<String, dynamic>>[].obs;
  final dateCustomerActivity = <Map<String, dynamic>>[].obs;

  ProductDao get _productDao => _db.productDao;
  SaleDao get _saleDao => _db.saleDao;
  CustomerDao get _customerDao => _db.customerDao;
  ExpenseDao get _expenseDao => _db.expenseDao;
  PurchaseDao get _purchaseDao => _db.purchaseDao;
  RentalDao get _rentalDao => _db.rentalDao;
  AssetDao get _assetDao => _db.assetDao;
  InvestorDao get _investorDao => _db.investorDao;

  String get dateStr => selectedDate.value != null
      ? DateFormat('dd-MM-yyyy').format(selectedDate.value!)
      : DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    currentDate.value = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final allSales = await _saleDao.getAll();
    totalCash.value = allSales
        .where((s) => s.type == 'cash')
        .fold(0.0, (sum, s) => sum + s.amount);
    totalSell.value = allSales.fold(0.0, (s, e) => s + e.amount);
    netProfit.value = allSales.fold(0.0, (s, e) => s + e.profit);

    final products = await _productDao.getAll();
    double sv = 0, tb = 0;
    for (final p in products) {
      final costPerUnit = p.buyConversionFactor > 0
          ? p.buyPrice / p.buyConversionFactor
          : 0.0;
      sv += costPerUnit * p.qty;
      tb += p.buyQty * p.buyPrice;
    }
    stockValue.value = sv;
    totalBuy.value = tb;

    final customers = await _customerDao.getAll();
    double due = 0, paid = 0;
    for (final c in customers) {
      final ledger = await _customerDao.getLedger(c.id);
      for (final e in ledger) {
        if (e.type == 'due') {
          due += e.amount;
        } else {
          paid += e.amount;
        }
      }
    }
    totalDue.value = due;
    duePaid.value = paid;

    final expenses = await _expenseDao.getAll();
    totalExpense.value = expenses.fold(0.0, (s, e) => s + e.amount);

    final rentals = await _rentalDao.getRentals();
    rentPaid.value = rentals
        .where((r) => r.isPaid)
        .fold(0.0, (s, r) => s + r.cost);
    rentDue.value = rentals
        .where((r) => !r.isPaid)
        .fold(0.0, (s, r) => s + r.cost);

    totalAssets.value = await _assetDao.totalValue();

    final investors = await _investorDao.getAll();
    toGiveAway.value = investors.fold(
      0.0,
      (s, inv) => s + inv.remainingBalance,
    );

    final today = DateTime.now();
    final todayStr =
        '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
    todaySalesCount.value = allSales.where((s) => s.date == todayStr).length;

    await _loadActivitiesForDate();
  }

  Future<void> pickDate() async {
    final picked = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ),
    );
    if (picked != null) {
      selectedDate.value = picked;
      await _loadActivitiesForDate();
    }
  }

  Future<void> _loadActivitiesForDate() async {
    final ds = dateStr;

    // Expenses for date
    final allExpenses = await _expenseDao.getAll();
    dateExpenses.value = allExpenses
        .where((e) => e.date == ds)
        .map((e) => {'title': e.title, 'amount': e.amount, 'note': e.note})
        .toList();

    // Purchases for date
    final allPurchases = await _purchaseDao.getAll();
    final pList = <Map<String, dynamic>>[];
    for (final p in allPurchases) {
      if (p.date == ds) {
        final items = await _purchaseDao.getItems(p.id);
        for (final item in items) {
          pList.add({
            'itemName': item.itemName,
            'quantity': item.quantity,
            'amount': item.quantity * item.unitPrice,
          });
        }
      }
    }
    datePurchases.value = pList;

    // Investor repayments for date
    final investors = await _investorDao.getAll();
    final repList = <Map<String, dynamic>>[];
    for (final inv in investors) {
      final reps = await _investorDao.getRepayments(inv.id);
      for (final r in reps) {
        if (r.date == ds) {
          repList.add({'investor': inv.name, 'amount': r.amount});
        }
      }
    }
    dateInvestorRepayments.value = repList;

    // Customer activity for date
    final customers = await _customerDao.getAll();
    final actList = <Map<String, dynamic>>[];
    for (final c in customers) {
      final purchases = await _customerDao.getPurchases(c.id);
      for (final p in purchases) {
        if (p.date == ds) {
          actList.add({
            'customer': c.name,
            'type': 'purchase',
            'detail': '${p.productName} (৳${p.price.toStringAsFixed(0)})',
          });
        }
      }
      final orders = await _customerDao.getOrders(c.id);
      for (final o in orders) {
        if (o.dateGiven == ds) {
          actList.add({
            'customer': c.name,
            'type': 'order',
            'detail': o.description,
          });
        }
      }
    }
    // Book rentals for date
    final rentals = await _rentalDao.getRentals();
    for (final r in rentals) {
      if (r.dateTaken == ds) {
        actList.add({
          'customer': r.customerName,
          'type': 'rental_taken',
          'detail': r.bookName,
        });
      }
      if (r.dateReturned == ds) {
        actList.add({
          'customer': r.customerName,
          'type': 'rental_returned',
          'detail': '${r.bookName} returned',
        });
      }
    }
    dateCustomerActivity.value = actList;
  }

  void toggleView() {
    showOtherActivities.toggle();
  }
}
