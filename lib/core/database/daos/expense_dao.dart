import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Future<List<Expense>> getAll() => select(expenses).get();

  Stream<List<Expense>> watchAll() => select(expenses).watch();

  Future<List<Expense>> getByDate(String date) {
    return (select(expenses)..where((t) => t.date.equals(date))).get();
  }

  Future<List<Expense>> getUnpaid() {
    return (select(expenses)..where((t) => t.isPaid.equals(false))).get();
  }

  Future<void> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<void> updateExpense(String id, ExpensesCompanion entry) {
    return (update(expenses)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteExpense(String id) {
    return (delete(expenses)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markPaid(String id) {
    return (update(expenses)..where((t) => t.id.equals(id))).write(
      const ExpensesCompanion(isPaid: Value(true)),
    );
  }
}
