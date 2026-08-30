import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/delete_sale_usecase.dart';
import '../../../data/usecases/edit_sale_usecase.dart';
import '../../../data/usecases/save_sale_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';

/// Backs the Daily Sales screen — date-based filtering, daily sales metrics,
/// product autosuggest, cash vs. due breakdown for every sale, and full sale create/edit/delete flows.
class DailySalesController extends GetxController {
  final AppDatabase db;

  DailySalesController(this.db);

  late final SaveSaleUseCase _useCase = SaveSaleUseCase(db);
  late final DeleteSaleUseCase _deleteUseCase = DeleteSaleUseCase(db);
  late final EditSaleUseCase _editUseCase = EditSaleUseCase(db);

  final products = <Product>[].obs;
  final customers = <Customer>[].obs;
  final allSales = <Sale>[].obs;
  final recentSales = <Sale>[].obs;
  final dues = <Due>[].obs;

  final selectedDate = Rx<DateTime>(DateTime.now());

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.customerDao
          .watchAll(defaultShopId)
          .listen((rows) => customers.assignAll(rows)),
    );
    _subscriptions.add(
      db.saleDao
          .watchAll(defaultShopId)
          .listen((rows) {
            allSales.assignAll(rows);
            recentSales.assignAll(rows.take(50));
          }),
    );
    _subscriptions.add(
      db.dueDao
          .watchAll(defaultShopId)
          .listen((rows) => dues.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  // --- Date navigation ---
  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
  }

  void goToToday() {
    selectedDate.value = DateTime.now();
  }

  bool get isToday {
    final now = DateTime.now();
    final sel = selectedDate.value;
    return now.year == sel.year && now.month == sel.month && now.day == sel.day;
  }

  // --- Filtered Sales & Metrics for Selected Date ---
  List<Sale> get salesForSelectedDate {
    final sel = selectedDate.value;
    final list = allSales.where((s) {
      final d = s.date.toLocal();
      return d.year == sel.year && d.month == sel.month && d.day == sel.day;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Due? dueForSale(String saleId) {
    for (final d in dues) {
      if (d.sourceType == DueSourceType.sale && d.sourceId == saleId) {
        return d;
      }
    }
    return null;
  }

  Money cashReceivedForSale(Sale sale) {
    final total = sale.actualSellPrice * sale.qty;
    if (sale.paymentStatus == PaymentStatus.fullCash) {
      return total;
    }
    if (sale.paymentStatus == PaymentStatus.fullDue) {
      return Money.zero();
    }
    final due = dueForSale(sale.id);
    if (due != null) {
      final cash = total - due.originalAmount;
      return cash.isNegative ? Money.zero() : cash;
    }
    return total;
  }

  Money dueAmountForSale(Sale sale) {
    final total = sale.actualSellPrice * sale.qty;
    if (sale.paymentStatus == PaymentStatus.fullCash) {
      return Money.zero();
    }
    if (sale.paymentStatus == PaymentStatus.fullDue) {
      return total;
    }
    final due = dueForSale(sale.id);
    if (due != null) {
      return due.originalAmount;
    }
    return Money.zero();
  }

  Money get totalSalesAmount {
    return salesForSelectedDate.fold(
      Money.zero(),
      (acc, s) => acc + (s.actualSellPrice * s.qty),
    );
  }

  Money get totalProfitAmount {
    return salesForSelectedDate.fold(
      Money.zero(),
      (acc, s) => acc + ((s.actualSellPrice - s.costPriceAtSale) * s.qty),
    );
  }

  Money get totalCashAmount {
    return salesForSelectedDate.fold(Money.zero(), (acc, s) {
      return acc + cashReceivedForSale(s);
    });
  }

  Money get totalDueAmount {
    return salesForSelectedDate.fold(Money.zero(), (acc, s) {
      return acc + dueAmountForSale(s);
    });
  }

  double get totalUnitsSold {
    return salesForSelectedDate.fold(0.0, (acc, s) => acc + s.qty);
  }

  int get totalTransactionsCount => salesForSelectedDate.length;

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Customer? customerById(String? id) {
    if (id == null) return null;
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<bool> logSale({
    required String productId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    DateTime? date,
    String? customerId,
    int? promisedDays,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final saleDate = date ?? selectedDate.value;
    final result = await _useCase.call(
      productId: productId,
      qty: qty,
      actualSellPrice: actualSellPrice,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: paymentMethod,
      date: saleDate,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      customerId: customerId,
      promisedDays: promisedDays,
    );
    isSaving.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> editSale({
    required String saleId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    String? customerId,
    int? promisedDays,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _editUseCase.call(
      saleId: saleId,
      qty: qty,
      actualSellPrice: actualSellPrice,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: paymentMethod,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      customerId: customerId,
      promisedDays: promisedDays,
    );
    isSaving.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> deleteSale(String saleId) async {
    errorMessage.value = null;
    final result = await _deleteUseCase.call(
      saleId: saleId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }
}
