import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/issue_rent_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/return_rent_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late ReturnRentUseCase useCase;
  late String rentId;

  Future<String> issueRental({required Money deposit, Money? rentPrice}) async {
    await IssueRentUseCase(db).call(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: deposit,
      days: 15,
      rentPrice: rentPrice ?? Money.fromMinor(2000),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      startDate: DateTime.utc(2026, 1, 1),
    );
    return (await (db.select(db.rentTransactions)).get()).single.id;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = ReturnRentUseCase(db);

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 3,
        fundSource: FundSource.shop(),
        isRentable: true,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a deposit that exactly covers the total settles with no cash movement',
    () async {
      rentId = await issueRental(deposit: Money.fromMinor(2000));

      final result = await useCase.call(
        rentId: rentId,
        actualReturnDate: DateTime.utc(2026, 1, 16),
        amountReceivedNow: Money.zero(),
        paymentMethod: PaymentMethod.cash,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final rent = (await (db.select(db.rentTransactions)).get()).single;
      expect(rent.status, RentStatus.returned);
      expect(rent.extraDayChargeMinor, 0);
      expect(rent.damageChargeMinor, 0);
      // Only the deposit collected at issue time — the settlement itself
      // (netAmount == 0) writes no additional ledger entry.
      final ledgerEntries = await (db.select(db.cashLedgerEntries)).get();
      expect(ledgerEntries, hasLength(1));
      expect(ledgerEntries.single.description, 'Rental deposit');
      expect(await (db.select(db.dues)).get(), isEmpty);
    },
  );

  test(
    'extra-day and damage charges beyond the deposit create cash-in plus a due for the rest',
    () async {
      rentId = await issueRental(deposit: Money.fromMinor(2000));

      // total = 2000 (rent) + 500 (extra day) + 1000 (damage) = 3500;
      // deposit 2000 -> owed 1500. Pay 1000 now, 500 goes to a due.
      final result = await useCase.call(
        rentId: rentId,
        actualReturnDate: DateTime.utc(2026, 1, 20),
        extraDayCharge: Money.fromMinor(500),
        damageCharge: Money.fromMinor(1000),
        amountReceivedNow: Money.fromMinor(1000),
        paymentMethod: PaymentMethod.mobileBanking,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      // The deposit entry (from issue time) plus the settlement entry
      // (from this return) — two real, distinct cash events.
      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('rent'))).get();
      expect(ledgerEntries, hasLength(2));
      final settlementEntry = ledgerEntries.firstWhere(
        (e) => e.description == 'Rental settlement',
      );
      expect(settlementEntry.amountMinor, 1000);

      final dues = await (db.select(db.dues)).get();
      expect(dues, hasLength(1));
      expect(dues.single.originalAmountMinor, 500);
      expect(dues.single.sourceType, DueSourceType.rent);
    },
  );

  test('a deposit larger than the total produces a refund, no due', () async {
    rentId = await issueRental(deposit: Money.fromMinor(5000));

    final result = await useCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 10),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

    // The deposit entry (issue time, +5000) plus the refund entry
    // (return time, -3000).
    final ledgerEntries = await (db.select(
      db.cashLedgerEntries,
    )..where((l) => l.sourceType.equals('rent'))).get();
    expect(ledgerEntries, hasLength(2));
    final refundEntry = ledgerEntries.firstWhere(
      (e) => e.description == 'Rental deposit refund',
    );
    expect(
      refundEntry.amountMinor,
      -3000,
      reason: 'deposit 5000 - rent price 2000 = 3000 refunded, cash out',
    );
    expect(await (db.select(db.dues)).get(), isEmpty);
  });

  test('rejects receiving a payment when a refund is actually owed', () async {
    rentId = await issueRental(deposit: Money.fromMinor(5000));

    final result = await useCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 10),
      amountReceivedNow: Money.fromMinor(100),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects an amount received greater than what is owed', () async {
    rentId = await issueRental(deposit: Money.zero());

    final result = await useCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 10),
      amountReceivedNow: Money.fromMinor(999999),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects returning an already-returned rental', () async {
    rentId = await issueRental(deposit: Money.fromMinor(2000));
    final first = await useCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 16),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(first.isOk, isTrue);

    final second = await useCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 17),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(second.isErr, isTrue);
    expect(second.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects returning a nonexistent rental', () async {
    final result = await useCase.call(
      rentId: 'does-not-exist',
      actualReturnDate: DateTime.utc(2026, 1, 10),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
