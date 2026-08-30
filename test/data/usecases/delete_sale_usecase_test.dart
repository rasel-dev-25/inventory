import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/delete_sale_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late DeleteSaleUseCase deleteUseCase;
  late SaveSaleUseCase saveSaleUseCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    deleteUseCase = DeleteSaleUseCase(db);
    saveSaleUseCase = SaveSaleUseCase(db);

    await ProductUseCases(db).create(
      Product(
        id: 'prod-1',
        name: 'Item 1',
        category: 'General',
        costPrice: Money.fromMinor(5000),
        suggestedSellPrice: Money.fromMinor(8000),
        qty: 10,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await CustomerUseCases(db).create(
      Customer(
        id: 'cust-1',
        name: 'Rahim',
        contact: '01700000000',
        address: 'Dhaka',
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('deleting a cash sale restores stock, negates cash ledger, and enqueues outbox event', () async {
    final now = DateTime.now().toUtc();
    final saveResult = await saveSaleUseCase.call(
      productId: 'prod-1',
      qty: 4,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(32000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );
    expect(saveResult.isOk, isTrue);
    final saleId = saveResult.valueOrNull!;

    // Verify post-sale state
    final productAfterSale = await db.productDao.getById('prod-1');
    expect(productAfterSale?.qty, 6.0); // 10 - 4

    final cashEntriesAfterSale = await db.ledgerDao.getEntriesForSource('sale', saleId);
    expect(cashEntriesAfterSale.length, 1);
    expect(cashEntriesAfterSale.first.amount, Money.fromMinor(32000));

    // Delete sale
    final deleteResult = await deleteUseCase.call(
      saleId: saleId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(deleteResult.isOk, isTrue);

    // Verify stock is restored
    final productAfterDelete = await db.productDao.getById('prod-1');
    expect(productAfterDelete?.qty, 10.0);

    // Verify sale is soft-deleted
    final deletedSale = await db.saleDao.getById(saleId);
    expect(deletedSale, isNull);

    // Verify cash ledger reversal is recorded
    final cashEntriesAfterDelete = await db.ledgerDao.getEntriesForSource('sale', saleId);
    expect(cashEntriesAfterDelete.length, 2);
    final reversalEntry = cashEntriesAfterDelete.last;
    expect(reversalEntry.amount, Money.fromMinor(-32000));

    // Verify outbox entry
    final outboxRows = await db.syncMetadataDao.pendingEntries();
    final deleteOutbox = outboxRows.firstWhere((r) => r.eventType == 'sale_deleted');
    final upserts = OutboxEvent.decodePayload(deleteOutbox.payloadJson);
    expect(upserts.any((u) => u.table == 'sales'), isTrue);
    expect(upserts.any((u) => u.table == 'stock_movements'), isTrue);
    expect(upserts.any((u) => u.table == 'cash_ledger_entries'), isTrue);
  });

  test('deleting a partial sale also soft-deletes the associated due', () async {
    final now = DateTime.now().toUtc();
    final saveResult = await saveSaleUseCase.call(
      productId: 'prod-1',
      qty: 2,
      actualSellPrice: Money.fromMinor(8000), // total 16000
      amountReceivedNow: Money.fromMinor(10000), // remaining 6000
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
      customerId: 'cust-1',
    );
    expect(saveResult.isOk, isTrue);
    final saleId = saveResult.valueOrNull!;

    final due = await db.dueDao.getBySource('sale', saleId);
    expect(due, isNotNull);
    expect(due?.originalAmount, Money.fromMinor(6000));

    // Delete sale
    final deleteResult = await deleteUseCase.call(
      saleId: saleId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(deleteResult.isOk, isTrue);

    // Verify due is soft-deleted
    final dueAfterDelete = await db.dueDao.getBySource('sale', saleId);
    expect(dueAfterDelete, isNull);
  });

  test('returns NotFoundFailure when deleting non-existent sale', () async {
    final result = await deleteUseCase.call(
      saleId: 'missing-sale',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
