import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/record_investor_repayment_usecase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late RecordInvestorRepaymentUseCase useCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = RecordInvestorRepaymentUseCase(db);

    await db.investorDao.create(
      const Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 30,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'records a capital-return repayment and a matching negative cash ledger entry',
    () async {
      final result = await useCase.call(
        investorId: 'investor-1',
        amount: Money.fromMinor(50000),
        type: RepaymentType.capitalReturn,
        paymentMethod: PaymentMethod.cash,
        date: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final repayments = await (db.select(db.investorRepayments)).get();
      expect(repayments, hasLength(1));
      expect(repayments.single.amountMinor, 50000);
      expect(repayments.single.type, RepaymentType.capitalReturn);

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('investor_repayment'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(
        ledgerEntries.single.amountMinor,
        -50000,
        reason: 'a repayment is cash out, so the ledger entry is negative',
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'investor_repayment_recorded',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'investor_repayments',
        'cash_ledger_entries',
      ]);
    },
  );

  test('rejects a zero or negative amount', () async {
    final result = await useCase.call(
      investorId: 'investor-1',
      amount: Money.zero(),
      type: RepaymentType.profitShare,
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 2),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(await (db.select(db.investorRepayments)).get(), isEmpty);
  });

  test('rejects a nonexistent investor', () async {
    final result = await useCase.call(
      investorId: 'does-not-exist',
      amount: Money.fromMinor(1000),
      type: RepaymentType.capitalReturn,
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 3),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
