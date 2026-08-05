import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/issue_rent_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late IssueRentUseCase useCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = IssueRentUseCase(db);

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    // 120 pages -> matches the seeded 200-page/15-day/৳20 tier.
    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 2,
        fundSource: FundSource.shop(),
        isRentable: true,
        pageCount: 120,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await ProductUseCases(db).create(
      Product(
        id: 'not-rentable',
        name: 'Regular item',
        category: 'Other',
        costPrice: Money.fromMinor(1000),
        suggestedSellPrice: Money.fromMinor(1500),
        qty: 5,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'issues a rental using the tier suggested by the book\'s page count',
    () async {
      final result = await useCase.call(
        bookProductId: 'book-a',
        customerId: 'cust-1',
        deposit: Money.fromMinor(5000),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
        startDate: DateTime.utc(2026, 1, 1),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final rentals = await (db.select(db.rentTransactions)).get();
      expect(rentals, hasLength(1));
      final rent = rentals.single;
      expect(rent.rentPriceMinor, 2000, reason: 'the 200-page tier price');
      // Drift's NativeDatabase round-trips DateTime columns back as local
      // time, not necessarily with isUtc still set — compare the instant,
      // not the representation, same reasoning throughout this file.
      expect(
        rent.dueDate.isAtSameMomentAs(DateTime.utc(2026, 1, 16)),
        isTrue,
        reason: '15-day tier',
      );
      expect(rent.status, RentStatus.active);

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('rent'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(ledgerEntries.single.amountMinor, 5000);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere((e) => e.eventType == 'rent_issued');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'rent_transactions',
        'cash_ledger_entries',
      ]);
    },
  );

  test('a manual days/price override skips the tier lookup entirely', () async {
    final result = await useCase.call(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: Money.zero(),
      days: 7,
      rentPrice: Money.fromMinor(9999),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      startDate: DateTime.utc(2026, 1, 1),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
    final rent = (await (db.select(db.rentTransactions)).get()).single;
    expect(rent.rentPriceMinor, 9999);
    expect(rent.dueDate.isAtSameMomentAs(DateTime.utc(2026, 1, 8)), isTrue);
    expect(
      await (db.select(db.cashLedgerEntries)).get(),
      isEmpty,
      reason: 'a zero deposit writes no ledger entry',
    );
  });

  test('rejects a book that is not marked rentable', () async {
    final result = await useCase.call(
      bookProductId: 'not-rentable',
      customerId: 'cust-1',
      deposit: Money.zero(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects issuing once every copy is already out on rent', () async {
    // book-a has qty: 2 — issue twice, then a third must fail.
    for (var i = 0; i < 2; i++) {
      final result = await useCase.call(
        bookProductId: 'book-a',
        customerId: 'cust-1',
        deposit: Money.zero(),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      expect(result.isOk, isTrue);
    }

    final result = await useCase.call(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: Money.zero(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test(
    'rejects when no tier covers the page count and no manual override is given',
    () async {
      await ProductUseCases(db).create(
        Product(
          id: 'huge-book',
          name: 'Huge Book',
          category: 'Book',
          costPrice: Money.fromMinor(10000),
          suggestedSellPrice: Money.fromMinor(15000),
          qty: 1,
          fundSource: FundSource.shop(),
          isRentable: true,
          pageCount: 5000,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final result = await useCase.call(
        bookProductId: 'huge-book',
        customerId: 'cust-1',
        deposit: Money.zero(),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    },
  );

  test('rejects a negative deposit', () async {
    final result = await useCase.call(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: Money.fromMinor(-100),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('rejects a nonexistent product', () async {
    final result = await useCase.call(
      bookProductId: 'does-not-exist',
      customerId: 'cust-1',
      deposit: Money.zero(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
