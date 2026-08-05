import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/expense_usecases.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/expense.dart';

/// Backs the Expense screen — `notes/business_logic.md` §চ section 1
/// ("মাসিক ভাড়া ও অন্যান্য খরচ"), via [ExpenseUseCases]. Purchases and
/// investor repayments are their own dedicated screens
/// (`PurchaseEntryScreen`/`InvestorScreen`) — this one covers everything
/// else the spec's "Finance" concept used to bundle together.
class ExpenseController extends GetxController {
  final AppDatabase db;
  static const _uuid = Uuid();

  ExpenseController(this.db);

  late final ExpenseUseCases _useCases = ExpenseUseCases(db);

  final expenses = <Expense>[].obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.expenseDao
          .watchAll(defaultShopId)
          .listen((rows) => expenses.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Future<bool> addExpense({
    required ExpenseCategory category,
    required Money amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.create(
      Expense(
        id: _uuid.v7(),
        category: category,
        amount: amount,
        date: DateTime.now(),
        paymentMethod: paymentMethod,
        description: description,
      ),
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

  Future<void> deleteExpense(String id) {
    return _useCases.softDelete(
      id,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  }
}
