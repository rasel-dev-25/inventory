import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late CustomerUseCases useCases;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = CustomerUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes the customer locally and enqueues a matching outbox event',
    () async {
      await useCases.create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final stored = await db.customerDao.getById('cust-1');
      expect(stored!.name, 'Karim');
      expect(stored.suspicionFlag, isFalse);
      expect(stored.isBlocked, isFalse);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'customer_created',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'customers');
      expect(upserts.single.row['name'], 'Karim');
    },
  );

  test(
    'update round-trips address/contact/flags and enqueues the new values',
    () async {
      await useCases.create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      const updated = Customer(
        id: 'cust-1',
        name: 'Karim Uddin',
        address: 'Dhanmondi',
        contact: '01700000000',
        suspicionFlag: true,
      );
      await useCases.update(
        updated,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final stored = await db.customerDao.getById('cust-1');
      expect(stored!.name, 'Karim Uddin');
      expect(stored.address, 'Dhanmondi');
      expect(stored.contact, '01700000000');
      expect(stored.suspicionFlag, isTrue);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.lastWhere((e) => e.eventType == 'customer_updated');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.row['suspicion_flag'], true);
    },
  );

  test(
    'softDelete marks the customer deleted locally and pushes a partial update',
    () async {
      await useCases.create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      await useCases.softDelete(
        'cust-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(
        await db.customerDao.getById('cust-1'),
        isNull,
        reason: 'soft-deleted rows are hidden',
      );

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.lastWhere((e) => e.eventType == 'customer_deleted');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.row.keys, {'id', 'shop_id', 'deleted_at'});
    },
  );

  test(
    'softDelete records an audit log entry with the pre-delete customer',
    () async {
      await useCases.create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      await useCases.softDelete(
        'cust-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
      expect(auditEntries, hasLength(1));
      expect(auditEntries.single.action, 'delete');
      expect(auditEntries.single.changedTableName, 'customers');
      expect(auditEntries.single.recordId, 'cust-1');
      expect(auditEntries.single.oldValueJson, contains('Karim'));
      expect(auditEntries.single.newValueJson, isNull);
    },
  );

  test(
    'restore un-hides the customer and records an audit log entry',
    () async {
      await useCases.create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await useCases.softDelete(
        'cust-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      expect(await db.customerDao.getById('cust-1'), isNull);

      await useCases.restore(
        'cust-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final restored = await db.customerDao.getById('cust-1');
      expect(restored, isNotNull);
      expect(restored!.name, 'Karim');

      final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
      final restoreEntry = auditEntries.firstWhere(
        (e) => e.action == 'restore',
      );
      expect(restoreEntry.changedTableName, 'customers');
      expect(restoreEntry.newValueJson, contains('Karim'));
      expect(restoreEntry.oldValueJson, isNull);
    },
  );
}
