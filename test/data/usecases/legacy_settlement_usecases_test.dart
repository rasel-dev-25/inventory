import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/data/usecases/legacy_settlement_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late LegacySettlementUseCases useCases;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = LegacySettlementUseCases(db);

    await InvestorUseCases(db).create(
      const Investor(
        id: 'abba',
        name: 'Abba',
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

  group('create', () {
    test('writes a pending settlement with a computed net amount and enqueues '
        'a matching outbox event', () async {
      final result = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.fromMinor(10000000),
        settlementDate: DateTime.utc(2026, 1, 1),
        notes: 'From the old ledger book, pages 1-40',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final settlement = await db.investorDao.getSettlementForInvestor('abba');
      expect(settlement, isNotNull);
      expect(settlement!.status, LegacySettlementStatus.pending);
      expect(settlement.netSettlementAmount, Money.fromMinor(40000000));
      expect(settlement.id, result.valueOrNull);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'legacy_settlement_created',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'legacy_settlements');
    });

    test(
      'defaults totalAlreadyReturned to zero when nothing was returned',
      () async {
        final result = await useCases.create(
          investorId: 'abba',
          totalHistoricalInvestment: Money.fromMinor(50000000),
          totalAlreadyReturned: Money.zero(),
          settlementDate: DateTime.utc(2026, 1, 1),
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );

        expect(result.isOk, isTrue);
        final settlement = await db.investorDao.getSettlementForInvestor(
          'abba',
        );
        expect(settlement!.netSettlementAmount, Money.fromMinor(50000000));
      },
    );

    test('rejects a nonexistent investor', () async {
      final result = await useCases.create(
        investorId: 'does-not-exist',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('rejects a negative total historical investment', () async {
      final result = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(-100),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test(
      'rejects totalAlreadyReturned exceeding totalHistoricalInvestment',
      () async {
        final result = await useCases.create(
          investorId: 'abba',
          totalHistoricalInvestment: Money.fromMinor(10000),
          totalAlreadyReturned: Money.fromMinor(20000),
          settlementDate: DateTime.utc(2026, 1, 1),
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      },
    );

    test('rejects a second settlement for the same investor', () async {
      final first = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      expect(first.isOk, isTrue);

      final second = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(1000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 2),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(second.isErr, isTrue);
      expect(second.failureOrNull, isA<BusinessRuleFailure>());
    });
  });

  group('markSettled', () {
    test('flips a pending settlement to settled', () async {
      final created = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final settlementId = created.valueOrNull!;

      final result = await useCases.markSettled(
        settlementId: settlementId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final settlement = await db.investorDao.getSettlementForInvestor('abba');
      expect(settlement!.status, LegacySettlementStatus.settled);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'legacy_settlement_settled',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'legacy_settlements');
    });

    test('rejects settling a nonexistent settlement', () async {
      final result = await useCases.markSettled(
        settlementId: 'does-not-exist',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('rejects settling an already-settled settlement twice', () async {
      final created = await useCases.create(
        investorId: 'abba',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final settlementId = created.valueOrNull!;

      final first = await useCases.markSettled(
        settlementId: settlementId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      expect(first.isOk, isTrue);

      final second = await useCases.markSettled(
        settlementId: settlementId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(second.isErr, isTrue);
      expect(second.failureOrNull, isA<BusinessRuleFailure>());
    });
  });
}
