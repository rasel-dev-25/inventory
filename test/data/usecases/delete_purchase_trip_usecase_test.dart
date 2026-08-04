import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/delete_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late DeletePurchaseTripUseCase useCase;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCase = DeletePurchaseTripUseCase(db);

    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 0,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await SavePurchaseTripUseCase(db).call(
      PurchaseTrip(
        id: 'trip-1',
        date: DateTime.utc(2026, 1, 1),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Mokam',
            productId: 'book-a',
            qty: 10,
            unitPrice: Money.fromMinor(10000),
            fundSource: FundSource.shop(),
          ),
        ],
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'reverses the stock movement, product qty, and cash ledger entry',
    () async {
      final product = await db.productDao.getById('book-a');
      expect(product!.qty, 10, reason: 'sanity check before deleting');

      final result = await useCase.call(
        tripId: 'trip-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      expect(await db.purchaseDao.getById('trip-1'), isNull);

      final reverted = await db.productDao.getById('book-a');
      expect(reverted!.qty, 0, reason: 'the +10 purchase movement is undone');

      final movements = await (db.select(
        db.stockMovements,
      )..where((m) => m.sourceType.equals('purchase'))).get();
      expect(movements, hasLength(2), reason: 'the +10 plus its -10 reversal');
      expect(
        movements.fold<double>(0, (sum, m) => sum + m.deltaQty),
        0,
        reason: 'net stock movement for this trip is now zero',
      );

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('purchase'))).get();
      expect(ledgerEntries, hasLength(2));
      expect(
        ledgerEntries.fold<int>(0, (sum, e) => sum + e.amountMinor),
        0,
        reason: 'a deleted purchase trip must net to zero cash impact',
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'purchase_trip_deleted',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toSet(), {
        'purchase_trips',
        'stock_movements',
        'cash_ledger_entries',
      });
    },
  );

  test('rejects deleting a nonexistent trip', () async {
    final result = await useCase.call(
      tripId: 'does-not-exist',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
