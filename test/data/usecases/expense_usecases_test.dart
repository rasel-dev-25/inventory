import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late ExpenseUseCases useCases;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCases = ExpenseUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes the expense locally and a matching negative cash ledger entry',
    () async {
      final result = await useCases.create(
        Expense(
          id: 'expense-1',
          category: ExpenseCategory.monthlyRent,
          amount: Money.fromMinor(500000),
          date: DateTime.utc(2026, 1, 1),
          paymentMethod: PaymentMethod.cash,
          description: 'August shop rent',
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final stored = await db.expenseDao.getById('expense-1');
      expect(stored!.category, ExpenseCategory.monthlyRent);
      expect(stored.amount, Money.fromMinor(500000));

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('expense'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(
        ledgerEntries.single.amountMinor,
        -500000,
        reason: 'an expense is cash out, so the ledger entry is negative',
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'expense_recorded',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'expenses',
        'cash_ledger_entries',
      ]);
    },
  );

  test('rejects a zero or negative amount', () async {
    final result = await useCases.create(
      Expense(
        id: 'expense-1',
        category: ExpenseCategory.dailyOther,
        amount: Money.zero(),
        date: DateTime.utc(2026, 1, 2),
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(await (db.select(db.expenses)).get(), isEmpty);
  });

  test('softDelete hides the expense from getById/watchAll', () async {
    await useCases.create(
      Expense(
        id: 'expense-1',
        category: ExpenseCategory.dailyOther,
        amount: Money.fromMinor(1000),
        date: DateTime.utc(2026, 1, 3),
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await useCases.softDelete(
      'expense-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(await db.expenseDao.getById('expense-1'), isNull);
  });
}
