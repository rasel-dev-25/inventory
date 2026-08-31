import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/expense_usecases.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/recurring_expense.dart';

/// Backs the Expense screen — `notes/business_logic.md` §চ section 1
/// ("মাসিক ভাড়া ও অন্যান্য খরচ"), via [ExpenseUseCases], including
/// recurring monthly expense templates and status tracking.
class ExpenseController extends GetxController {
  final AppDatabase db;
  static const _uuid = Uuid();
  static const _recurringSettingsKey = 'recurring_expenses_list';

  ExpenseController(this.db);

  late final ExpenseUseCases _useCases = ExpenseUseCases(db);

  final expenses = <Expense>[].obs;
  final recurringExpenses = <RecurringExpense>[].obs;
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
    loadRecurringExpenses();
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Money get totalExpenses =>
      expenses.fold(Money.zeroBdt, (sum, e) => sum + e.amount);

  // ── Monthly Recurring Expenses ──────────────────────────────────────────

  Future<void> loadRecurringExpenses() async {
    try {
      final raw = await db.appSettingsDao.get(_recurringSettingsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => RecurringExpense.fromJson(item as Map<String, dynamic>))
            .toList();
        recurringExpenses.assignAll(list);
      }
    } catch (_) {}
  }

  Future<void> saveRecurringExpense(RecurringExpense item) async {
    final index = recurringExpenses.indexWhere((r) => r.id == item.id);
    if (index >= 0) {
      recurringExpenses[index] = item;
    } else {
      recurringExpenses.add(item);
    }
    await _persistRecurringExpenses();
  }

  Future<void> deleteRecurringExpense(String id) async {
    recurringExpenses.removeWhere((r) => r.id == id);
    await _persistRecurringExpenses();
  }

  Future<void> toggleRecurringActive(String id) async {
    final index = recurringExpenses.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final current = recurringExpenses[index];
      recurringExpenses[index] = current.copyWith(isActive: !current.isActive);
      await _persistRecurringExpenses();
    }
  }

  Future<void> _persistRecurringExpenses() async {
    final raw = jsonEncode(recurringExpenses.map((r) => r.toJson()).toList());
    await db.appSettingsDao.upsert(_recurringSettingsKey, raw);
  }

  /// Checks if a recurring expense has already been recorded in the current month.
  bool isRecurringRecordedThisMonth(RecurringExpense item) {
    final now = DateTime.now();
    return expenses.any((e) {
      final matchesMonth = e.date.year == now.year && e.date.month == now.month;
      if (!matchesMonth) return false;

      if (item.category == ExpenseCategory.monthlyRent) {
        return e.category == ExpenseCategory.monthlyRent;
      }
      return e.description?.trim().toLowerCase() ==
          item.title.trim().toLowerCase();
    });
  }

  /// List of active recurring expenses that have NOT yet been recorded this month.
  List<RecurringExpense> get pendingRecurringThisMonth {
    return recurringExpenses
        .where((r) => r.isActive && !isRecurringRecordedThisMonth(r))
        .toList();
  }

  /// 1-tap records a recurring expense for the current month.
  Future<bool> recordRecurringExpense(
    RecurringExpense item, {
    PaymentMethod? method,
    Money? customAmount,
  }) async {
    return addExpense(
      category: item.category,
      amount: customAmount ?? item.amount,
      paymentMethod: method ?? item.paymentMethod,
      description: item.title,
    );
  }

  // ── Standard CRUD ───────────────────────────────────────────────────────

  Future<bool> addExpense({
    required ExpenseCategory category,
    required Money amount,
    required PaymentMethod paymentMethod,
    String? description,
    bool isRecurring = false,
  }) async {
    errorMessage.value = null;
    final id = _uuid.v7();

    final result = await _useCases.create(
      Expense(
        id: id,
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
      onOk: (_) async {
        if (isRecurring) {
          final title = (description != null && description.trim().isNotEmpty)
              ? description.trim()
              : (category == ExpenseCategory.monthlyRent
                  ? 'মাসিক দোকান ভাড়া'
                  : 'অন্যান্য নিয়মিত খরচ');
          final existing = recurringExpenses.firstWhereOrNull(
            (r) => r.title.trim().toLowerCase() == title.trim().toLowerCase(),
          );
          await saveRecurringExpense(
            RecurringExpense(
              id: existing?.id ?? _uuid.v7(),
              title: title,
              category: category,
              amount: amount,
              paymentMethod: paymentMethod,
            ),
          );
        }
        return true;
      },
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> updateExpense({
    required String id,
    required ExpenseCategory category,
    required Money amount,
    required PaymentMethod paymentMethod,
    required DateTime date,
    String? description,
    bool isRecurring = false,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.update(
      Expense(
        id: id,
        category: category,
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        description: description,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    return result.fold(
      onOk: (_) async {
        final title = (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : (category == ExpenseCategory.monthlyRent
                ? 'মাসিক দোকান ভাড়া'
                : 'অন্যান্য নিয়মিত খরচ');

        if (isRecurring) {
          final existing = recurringExpenses.firstWhereOrNull(
            (r) => r.title.trim().toLowerCase() == title.trim().toLowerCase(),
          );
          await saveRecurringExpense(
            RecurringExpense(
              id: existing?.id ?? _uuid.v7(),
              title: title,
              category: category,
              amount: amount,
              paymentMethod: paymentMethod,
            ),
          );
        } else {
          final existing = recurringExpenses.firstWhereOrNull(
            (r) => r.title.trim().toLowerCase() == title.trim().toLowerCase(),
          );
          if (existing != null) {
            await deleteRecurringExpense(existing.id);
          }
        }
        return true;
      },
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
