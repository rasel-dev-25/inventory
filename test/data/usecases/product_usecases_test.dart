import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late ProductUseCases useCases;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = ProductUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  Product buildProduct({String id = 'prod-1', double qty = 0}) {
    return Product(
      id: id,
      name: 'Notebook',
      category: 'Stationery',
      costPrice: Money.fromMinor(5000),
      suggestedSellPrice: Money.fromMinor(8000),
      qty: qty,
      fundSource: FundSource.shop(),
    );
  }

  test(
    'create writes the product locally and enqueues a matching outbox event',
    () async {
      final product = buildProduct();
      final now = DateTime.now().toUtc();

      await useCases.create(product, shopId: defaultShopId, now: now);

      final stored = await db.productDao.getById('prod-1');
      expect(stored, isNotNull);
      expect(stored!.name, 'Notebook');
      expect(stored.costPrice.minorUnits, 5000);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere((e) => e.eventType == 'product_created');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      final row = upserts.single.row;
      expect(row['id'], 'prod-1');
      expect(row['cost_price_minor'], 5000);
      expect(row['suggested_sell_price_minor'], 8000);
      expect(row['fund_source_type'], 'shop');
      expect(row['fund_source_investor_id'], isNull);
    },
  );

  test(
    'an investor-funded product carries the investor id in both places',
    () async {
      final product = Product(
        id: 'prod-2',
        name: 'Attar Bottle',
        category: 'Attar',
        costPrice: Money.fromMinor(2000),
        suggestedSellPrice: Money.fromMinor(3000),
        qty: 0,
        fundSource: FundSource.investor('investor-1'),
      );

      await useCases.create(
        product,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final stored = await db.productDao.getById('prod-2');
      expect(stored!.fundSource, FundSource.investor('investor-1'));

      final pending = await db.syncMetadataDao.pendingEntries();
      final row = OutboxEvent.decodePayload(
        pending.single.payloadJson,
      ).single.row;
      expect(row['fund_source_type'], 'investor');
      expect(row['fund_source_investor_id'], 'investor-1');
    },
  );

  test(
    'update round-trips the existing qty rather than resetting it',
    () async {
      final created = buildProduct(qty: 0);
      await useCases.create(
        created,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      // Simulates a purchase trip having since increased on-hand qty to 12
      // via ProductDao.adjustQty (a separate, deliberate write path — see
      // SavePurchaseTripUseCase) before this product is edited.
      await db.productDao.adjustQty('prod-1', 12, DateTime.now().toUtc());
      final afterStockIn = await db.productDao.getById('prod-1');
      expect(afterStockIn!.qty, 12);

      // A correct edit-product flow loads the current product (qty: 12)
      // and only changes non-qty fields before calling update().
      final edited = afterStockIn.copyWith(name: 'Notebook (Renamed)');
      await useCases.update(
        edited,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final afterEdit = await db.productDao.getById('prod-1');
      expect(afterEdit!.name, 'Notebook (Renamed)');
      expect(afterEdit.qty, 12, reason: 'editing a product must not reset qty');

      final pending = await db.syncMetadataDao.pendingEntries();
      final updateEntry = pending.firstWhere(
        (e) => e.eventType == 'product_updated',
      );
      final row = OutboxEvent.decodePayload(updateEntry.payloadJson).single.row;
      expect(row['qty'], 12);
    },
  );

  test('create records an audit log insert entry', () async {
    final product = buildProduct();
    await useCases.create(
      product,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
    expect(auditEntries, hasLength(1));
    expect(auditEntries.single.action, 'insert');
    expect(auditEntries.single.changedTableName, 'products');
    expect(auditEntries.single.recordId, 'prod-1');
    expect(auditEntries.single.newValueJson, contains('Notebook'));
    expect(auditEntries.single.oldValueJson, isNull);
  });

  test(
    'update records an audit log entry with both the old and new selling price '
    "— the spec's own \"who changed the selling price\" example",
    () async {
      final created = buildProduct();
      await useCases.create(
        created,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final repriced = created.copyWith(
        suggestedSellPrice: Money.fromMinor(9500),
      );
      await useCases.update(
        repriced,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
      final updateEntry = auditEntries.firstWhere((e) => e.action == 'update');
      expect(updateEntry.changedTableName, 'products');
      expect(updateEntry.recordId, 'prod-1');
      expect(updateEntry.oldValueJson, contains('8000'));
      expect(updateEntry.newValueJson, contains('9500'));
    },
  );

  test('softDelete hides the product locally, pushes a partial update, and '
      'records an audit log entry', () async {
    final product = buildProduct();
    await useCases.create(
      product,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await useCases.softDelete(
      'prod-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(
      await db.productDao.getById('prod-1'),
      isNull,
      reason: 'soft-deleted rows are hidden',
    );

    final pending = await db.syncMetadataDao.pendingEntries();
    final entry = pending.lastWhere((e) => e.eventType == 'product_deleted');
    final upserts = OutboxEvent.decodePayload(entry.payloadJson);
    expect(upserts.single.row.keys, {'id', 'shop_id', 'deleted_at'});

    final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
    final deleteEntry = auditEntries.firstWhere((e) => e.action == 'delete');
    expect(deleteEntry.changedTableName, 'products');
    expect(deleteEntry.recordId, 'prod-1');
    expect(deleteEntry.oldValueJson, contains('Notebook'));
  });

  test('restore un-hides the product without touching qty, and records an '
      'audit log entry', () async {
    final product = buildProduct(qty: 7);
    await useCases.create(
      product,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await useCases.softDelete(
      'prod-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(await db.productDao.getById('prod-1'), isNull);

    await useCases.restore(
      'prod-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    final restored = await db.productDao.getById('prod-1');
    expect(restored, isNotNull);
    expect(restored!.name, 'Notebook');
    expect(restored.qty, 7, reason: 'restore must not touch qty');

    final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
    final restoreEntry = auditEntries.firstWhere((e) => e.action == 'restore');
    expect(restoreEntry.changedTableName, 'products');
    expect(restoreEntry.newValueJson, contains('Notebook'));
    expect(restoreEntry.oldValueJson, isNull);
  });
}
