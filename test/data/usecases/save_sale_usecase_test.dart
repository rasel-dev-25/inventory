import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late SaveSaleUseCase useCase;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCase = SaveSaleUseCase(db);

    final productUseCases = ProductUseCases(db);
    await productUseCases.create(
      Product(
        id: 'prod-book',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(1000),
        suggestedSellPrice: Money.fromMinor(1500),
        qty: 10,
        fundSource: FundSource.investor('investor-1'),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a full-cash sale decreases stock and records cash in, with no due',
    () async {
      final result = await useCase.call(
        productId: 'prod-book',
        qty: 2,
        actualSellPrice: Money.fromMinor(1500),
        amountReceivedNow: Money.fromMinor(3000),
        paymentMethod: PaymentMethod.cash,
        date: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final product = await db.productDao.getById('prod-book');
      expect(product!.qty, 8);

      final sales = await (db.select(db.sales)).get();
      expect(sales, hasLength(1));
      expect(sales.single.paymentStatus, PaymentStatus.fullCash);
      // costPrice/fundSource copied from the product at sale time.
      expect(sales.single.costPriceMinorAtSale, 1000);
      expect(sales.single.fundSourceType, FundSourceType.investor);
      expect(sales.single.fundSourceInvestorId, 'investor-1');

      final movements = await (db.select(
        db.stockMovements,
      )..where((m) => m.sourceType.equals('sale'))).get();
      expect(movements, hasLength(1));
      expect(movements.single.deltaQty, -2);

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('sale'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(
        ledgerEntries.single.amountMinor,
        3000,
        reason: 'cash IN is positive, unlike a purchase',
      );

      expect(await (db.select(db.dues)).get(), isEmpty);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere((e) => e.eventType == 'sale_recorded');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'sales',
        'stock_movements',
        'cash_ledger_entries',
      ]);
    },
  );

  test(
    'a full-due sale creates a due for the entire total and no cash ledger entry',
    () async {
      final result = await useCase.call(
        productId: 'prod-book',
        qty: 1,
        actualSellPrice: Money.fromMinor(1500),
        amountReceivedNow: Money.zero(),
        paymentMethod: PaymentMethod.cash,
        date: DateTime.utc(2026, 1, 2),
        shopId: defaultShopId,
        customerId: 'cust-1',
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final sales = await (db.select(db.sales)).get();
      expect(sales.single.paymentStatus, PaymentStatus.fullDue);

      expect(await (db.select(db.cashLedgerEntries)).get(), isEmpty);

      final dues = await (db.select(db.dues)).get();
      expect(dues, hasLength(1));
      expect(dues.single.originalAmountMinor, 1500);
      expect(dues.single.status, DueStatus.pending);
      expect(dues.single.customerId, 'cust-1');
    },
  );

  test('a partial sale creates a due for exactly the remainder', () async {
    final result = await useCase.call(
      productId: 'prod-book',
      qty: 2,
      actualSellPrice: Money.fromMinor(1500),
      amountReceivedNow: Money.fromMinor(1000),
      paymentMethod: PaymentMethod.mobileBanking,
      date: DateTime.utc(2026, 1, 3),
      shopId: defaultShopId,
      customerId: 'cust-1',
      now: DateTime.now().toUtc(),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

    final sales = await (db.select(db.sales)).get();
    expect(sales.single.paymentStatus, PaymentStatus.partial);

    final ledgerEntries = await (db.select(db.cashLedgerEntries)).get();
    expect(ledgerEntries.single.amountMinor, 1000);

    final dues = await (db.select(db.dues)).get();
    // sale total = 2 * 1500 = 3000; received 1000; remaining 2000.
    expect(dues.single.originalAmountMinor, 2000);
  });

  test('rejects a sale for more than the available stock', () async {
    final result = await useCase.call(
      productId: 'prod-book',
      qty: 999,
      actualSellPrice: Money.fromMinor(1500),
      amountReceivedNow: Money.fromMinor(1500 * 999),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 4),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(
      await (db.select(db.sales)).get(),
      isEmpty,
      reason: 'a rejected sale must write nothing',
    );
  });

  test('rejects a due-creating sale with no customer', () async {
    final result = await useCase.call(
      productId: 'prod-book',
      qty: 1,
      actualSellPrice: Money.fromMinor(1500),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 5),
      shopId: defaultShopId,
      // customerId intentionally omitted.
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(await (db.select(db.sales)).get(), isEmpty);
  });

  test('rejects an amount received greater than the sale total', () async {
    final result = await useCase.call(
      productId: 'prod-book',
      qty: 1,
      actualSellPrice: Money.fromMinor(1500),
      amountReceivedNow: Money.fromMinor(5000),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 6),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects a nonexistent product', () async {
    final result = await useCase.call(
      productId: 'does-not-exist',
      qty: 1,
      actualSellPrice: Money.fromMinor(1500),
      amountReceivedNow: Money.fromMinor(1500),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 7),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
