import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/expense.dart' as domain;
import '../app_database.dart';
import '../tables/expenses.dart';

part 'expense_dao.g.dart';

extension _ExpenseRowMapping on ExpenseRow {
  domain.Expense toDomain() {
    return domain.Expense(
      id: id,
      category: category,
      amount: Money.fromMinor(amountMinor),
      date: date,
      description: description,
      paymentMethod: paymentMethod,
    );
  }
}

/// Data access for [Expenses]. Only `create` and `softDelete` — no
/// `update` — matching the same convention `PurchaseDao`/`SaleDao`
/// already establish for any row with a direct, paired
/// `cash_ledger_entries` write: editing the amount/category/payment
/// method after the fact would leave the ledger entry it was recorded
/// alongside silently wrong, since `CashLedgerEntries` is append-only and
/// cannot be corrected in place. A mistaken expense is deleted, not
/// edited — `ExpenseUseCases.softDelete` (not this DAO method directly)
/// also reverses the ledger entry via `ledger_reversal.dart`, so this
/// method alone (hides the row, no reversal) should only ever be called
/// from there, never on its own.
@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabaseV2>
    with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Future<domain.Expense?> getById(String id) async {
    final row = await (select(
      expenses,
    )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Expense>> watchAll(String shopId) {
    final query = select(expenses)
      ..where((e) => e.shopId.equals(shopId) & e.deletedAt.isNull())
      ..orderBy([(e) => OrderingTerm.desc(e.date)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Expense expense, {
    required String shopId,
    required DateTime now,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        id: expense.id,
        shopId: shopId,
        category: expense.category,
        amountMinor: expense.amount.minorUnits,
        date: expense.date,
        description: Value(expense.description),
        paymentMethod: expense.paymentMethod,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Only hides the expense from every read (`watchAll`/`getById`) — does
  /// **not** touch `CashLedgerEntries`. `ExpenseUseCases.softDelete` pairs
  /// this with a ledger reversal in the same transaction; calling this
  /// method directly (bypassing that use case) would reproduce the gap
  /// its own doc comment describes.
  Future<void> softDelete(String id, DateTime now) {
    return (update(expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
