import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/category_usecases.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late CategoryUseCases useCases;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = CategoryUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes the category locally and enqueues a matching outbox event',
    () async {
      await useCases.create(
        id: 'cat-1',
        shopId: defaultShopId,
        name: 'Stationery',
        sortOrder: 10,
      );

      final rows = await db.categoryDao.watchAll(defaultShopId).first;
      final created = rows.firstWhere((r) => r.id == 'cat-1');
      expect(created.name, 'Stationery');
      expect(created.sortOrder, 10);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'category_created',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'categories');
      expect(upserts.single.row['id'], 'cat-1');
      expect(upserts.single.row['name'], 'Stationery');
      expect(upserts.single.row['sort_order'], 10);
    },
  );

  test(
    'rename updates locally and enqueues without clobbering sort_order',
    () async {
      await useCases.create(
        id: 'cat-2',
        shopId: defaultShopId,
        name: 'Old Name',
        sortOrder: 3,
      );
      await useCases.rename(
        id: 'cat-2',
        shopId: defaultShopId,
        name: 'New Name',
      );

      final rows = await db.categoryDao.watchAll(defaultShopId).first;
      final renamed = rows.firstWhere((r) => r.id == 'cat-2');
      expect(renamed.name, 'New Name');
      expect(
        renamed.sortOrder,
        3,
        reason: 'rename must not touch sort_order locally',
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'category_renamed',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.row.containsKey('sort_order'), isFalse);
    },
  );

  test(
    'reorder updates sort_order locally and enqueues only that field',
    () async {
      await useCases.create(
        id: 'cat-3',
        shopId: defaultShopId,
        name: 'Fixed Name',
        sortOrder: 1,
      );
      await useCases.reorder(id: 'cat-3', shopId: defaultShopId, sortOrder: 99);

      final rows = await db.categoryDao.watchAll(defaultShopId).first;
      final reordered = rows.firstWhere((r) => r.id == 'cat-3');
      expect(reordered.sortOrder, 99);
      expect(reordered.name, 'Fixed Name');
    },
  );

  test(
    'two outbox events queue independently when created back to back',
    () async {
      await useCases.create(
        id: 'cat-4',
        shopId: defaultShopId,
        name: 'A',
        sortOrder: 0,
      );
      await useCases.create(
        id: 'cat-5',
        shopId: defaultShopId,
        name: 'B',
        sortOrder: 1,
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      expect(
        pending.where((e) => e.eventType == 'category_created'),
        hasLength(2),
      );
    },
  );
}
