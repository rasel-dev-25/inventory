import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/pay_due_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late PayDueUseCase useCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = PayDueUseCase(db);

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await db.dueDao.create(
      Due(
        id: 'due-1',
        customerId: 'cust-1',
        sourceType: DueSourceType.sale,
        sourceId: 'sale-1',
        originalAmount: Money.fromMinor(2000),
        paidAmount: Money.zero(),
        status: DueStatus.pending,
        createdAt: DateTime.now().toUtc(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a partial payment advances paidAmount and status without settling the due',
    () async {
      final result = await useCase.call(
        dueId: 'due-1',
        paymentAmount: Money.fromMinor(800),
        paymentMethod: PaymentMethod.cash,
        shopId: defaultShopId,
        date: DateTime.utc(2026, 1, 10),
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final due = await db.dueDao.getById('due-1');
      expect(due!.paidAmount, Money.fromMinor(800));
      expect(due.status, DueStatus.partiallyPaid);

      final payments = await (db.select(db.duePayments)).get();
      expect(payments, hasLength(1));
      expect(payments.single.amountMinor, 800);

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('due_payment'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(ledgerEntries.single.amountMinor, 800);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'due_payment_recorded',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'dues',
        'due_payments',
        'cash_ledger_entries',
      ]);
    },
  );

  test('a payment for the full remaining balance marks the due paid', () async {
    final result = await useCase.call(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(2000),
      paymentMethod: PaymentMethod.mobileBanking,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 11),
      now: DateTime.now().toUtc(),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

    final due = await db.dueDao.getById('due-1');
    expect(due!.status, DueStatus.paid);
    expect(due.paidAmount, Money.fromMinor(2000));
  });

  test('rejects a payment that would overpay the due', () async {
    final result = await useCase.call(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(5000),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 12),
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(await (db.select(db.duePayments)).get(), isEmpty);
  });

  test('rejects a zero payment amount', () async {
    final result = await useCase.call(
      dueId: 'due-1',
      paymentAmount: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 13),
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('rejects paying a nonexistent due', () async {
    final result = await useCase.call(
      dueId: 'does-not-exist',
      paymentAmount: Money.fromMinor(100),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 14),
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('rejects paying a due that is already fully paid', () async {
    final first = await useCase.call(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(2000),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 15),
      now: DateTime.now().toUtc(),
    );
    expect(first.isOk, isTrue);

    final second = await useCase.call(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(100),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      date: DateTime.utc(2026, 1, 16),
      now: DateTime.now().toUtc(),
    );

    expect(second.isErr, isTrue);
    expect(second.failureOrNull, isA<BusinessRuleFailure>());
  });
}
