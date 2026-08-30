import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SavePurchaseTripUseCase useCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = SavePurchaseTripUseCase(db);

    // Seed two real products — stock movements have a real FK to
    // Products, so the use case can't be exercised against invented ids.
    final productUseCases = ProductUseCases(db);
    await productUseCases.create(
      Product(
        id: 'prod-book',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(1000),
        suggestedSellPrice: Money.fromMinor(1500),
        qty: 0,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await productUseCases.create(
      Product(
        id: 'prod-attar',
        name: 'Attar B',
        category: 'Attar',
        costPrice: Money.fromMinor(2000),
        suggestedSellPrice: Money.fromMinor(3000),
        qty: 5,
        fundSource: FundSource.investor('investor-1'),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a simple all-cash, single-fund-source trip writes trip+item+stock+ledger together',
    () async {
      final trip = PurchaseTrip(
        id: 'trip-1',
        date: DateTime.utc(2026, 1, 1),
        transportCost: Money.fromMinor(200),
        cashReturned: Money.zero(),
        actualCashTakenOut: Money.fromMinor(10200),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Book Mokam',
            productId: 'prod-book',
            qty: 10,
            unitPrice: Money.fromMinor(1000),
            fundSource: FundSource.shop(),
          ),
        ],
      );

      await useCase.call(
        trip,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      // Trip + item persisted.
      final storedTrip = await db.purchaseDao.getById('trip-1');
      expect(storedTrip, isNotNull);
      expect(storedTrip!.items, hasLength(1));
      expect(storedTrip.transportCost.minorUnits, 200);
      expect(storedTrip.actualCashTakenOut, Money.fromMinor(10200));

      // Product qty increased by the item's qty.
      final product = await db.productDao.getById('prod-book');
      expect(product!.qty, 10);

      // One stock movement recorded, traceable to this trip.
      final movements = await (db.select(
        db.stockMovements,
      )..where((m) => m.productId.equals('prod-book'))).get();
      expect(movements, hasLength(1));
      expect(movements.single.deltaQty, 10);
      expect(movements.single.sourceType, 'purchase');
      expect(movements.single.sourceId, 'trip-1');

      // One cash ledger entry: 10*1000 (items) + 200 (transport) = 10200,
      // negated (cash out) — matches reconcilePurchaseTrip's formula.
      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceId.equals('trip-1'))).get();
      expect(ledgerEntries, hasLength(1));
      expect(ledgerEntries.single.amountMinor, -10200);
      expect(ledgerEntries.single.paymentMethod.name, 'cash');

      // Outbox payload mirrors every local write: trip + item + stock
      // movement + ledger entry = 4 upserts.
      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'purchase_trip_recorded',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.map((u) => u.table).toList(), [
        'purchase_trips',
        'purchase_items',
        'stock_movements',
        'cash_ledger_entries',
      ]);
      final pushedLedgerRow = upserts
          .firstWhere((u) => u.table == 'cash_ledger_entries')
          .row;
      expect(pushedLedgerRow['amount_minor'], -10200);
    },
  );

  test(
    'in-kind items add stock and no cash but do not skip the fund-source split',
    () async {
      final trip = PurchaseTrip(
        id: 'trip-2',
        date: DateTime.utc(2026, 1, 2),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-2',
            shopName: 'Attar Mokam',
            productId: 'prod-attar',
            qty: 3,
            unitPrice: Money.fromMinor(2000),
            fundSource: FundSource.investor('investor-1'),
            isInKind: true,
          ),
        ],
      );

      await useCase.call(
        trip,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      // Stock still increases for an in-kind item — it is real physical
      // stock, only the funding is different.
      final product = await db.productDao.getById('prod-attar');
      expect(product!.qty, 5 + 3);

      // No cash ledger entry at all: the only fund-source bucket
      // (investor-1) is entirely in-kind, so its cash total is zero and
      // reconcilePurchaseTrip's byFundSource omits/zeroes it — see the
      // `if (bucket.amount.minorUnits == 0) continue` guard.
      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceId.equals('trip-2'))).get();
      expect(ledgerEntries, isEmpty);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'purchase_trip_recorded',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.any((u) => u.table == 'cash_ledger_entries'), isFalse);
    },
  );

  test(
    'trip-level overhead is charged to the shop even when all items are investor-funded',
    () async {
      final trip = PurchaseTrip(
        id: 'trip-3',
        date: DateTime.utc(2026, 1, 3),
        transportCost: Money.fromMinor(500),
        otherCosts: const [],
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-3',
            shopName: 'Attar Mokam',
            productId: 'prod-attar',
            qty: 1,
            unitPrice: Money.fromMinor(2000),
            fundSource: FundSource.investor('investor-1'),
          ),
        ],
      );

      await useCase.call(
        trip,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceId.equals('trip-3'))).get();
      // Two buckets: investor-1's item cost (2000) and the shop's trip
      // overhead (500 transport) — see purchase_reconciliation.dart's
      // "trip-level costs are charged to the shop" decision.
      expect(ledgerEntries, hasLength(2));
      final total = ledgerEntries.fold<int>(0, (sum, e) => sum + e.amountMinor);
      expect(total, -2500);
    },
  );

  test(
    'multiple items across two trips each get their own traceable stock movement',
    () async {
      final trip = PurchaseTrip(
        id: 'trip-4',
        date: DateTime.utc(2026, 1, 4),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-4a',
            shopName: 'Book Mokam',
            productId: 'prod-book',
            qty: 2,
            unitPrice: Money.fromMinor(1000),
            fundSource: FundSource.shop(),
          ),
          PurchaseItem(
            id: 'item-4b',
            shopName: 'Book Mokam',
            productId: 'prod-book',
            qty: 3,
            unitPrice: Money.fromMinor(1000),
            fundSource: FundSource.shop(),
          ),
        ],
      );

      await useCase.call(
        trip,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final product = await db.productDao.getById('prod-book');
      expect(product!.qty, 5);

      final movements = await (db.select(
        db.stockMovements,
      )..where((m) => m.sourceId.equals('trip-4'))).get();
      expect(movements, hasLength(2));
      expect(
        movements.map((m) => m.id).toSet(),
        hasLength(2),
        reason: 'each movement needs its own id',
      );
    },
  );
}
