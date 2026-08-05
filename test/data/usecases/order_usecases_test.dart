import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late OrderUseCases useCases;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCases = OrderUseCases(db);

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
    'create writes a pending order locally and enqueues a matching outbox event',
    () async {
      final result = await useCases.create(
        customerId: 'cust-1',
        itemDescription: 'A red backpack',
        requestedDate: DateTime.utc(2026, 1, 1),
        neededByDate: DateTime.utc(2026, 1, 10),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final orders = await (db.select(db.orders)).get();
      expect(orders, hasLength(1));
      expect(orders.single.status, OrderStatus.pending);
      expect(orders.single.itemDescription, 'A red backpack');
      expect(orders.single.fulfilledDate, isNull);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere((e) => e.eventType == 'order_created');
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'orders');
    },
  );

  test('rejects an empty item description', () async {
    final result = await useCases.create(
      customerId: 'cust-1',
      itemDescription: '   ',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(await (db.select(db.orders)).get(), isEmpty);
  });

  test(
    'marking fulfilled sets both status and fulfilledDate together',
    () async {
      await useCases.create(
        customerId: 'cust-1',
        itemDescription: 'A red backpack',
        requestedDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final orderId = (await (db.select(db.orders)).get()).single.id;

      final result = await useCases.updateStatus(
        orderId: orderId,
        status: OrderStatus.fulfilled,
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 5),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final order = await db.orderDao.getById(orderId);
      expect(order!.status, OrderStatus.fulfilled);
      // Drift's NativeDatabase round-trips DateTime columns without
      // necessarily preserving isUtc — compare the instant, not the
      // representation (same subtlety documented in the rent module's
      // tests).
      expect(
        order.fulfilledDate!.isAtSameMomentAs(DateTime.utc(2026, 1, 5)),
        isTrue,
      );
    },
  );

  test('marking cancelled leaves fulfilledDate null', () async {
    await useCases.create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;

    final result = await useCases.updateStatus(
      orderId: orderId,
      status: OrderStatus.cancelled,
      shopId: defaultShopId,
      now: DateTime.utc(2026, 1, 5),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
    final order = await db.orderDao.getById(orderId);
    expect(order!.status, OrderStatus.cancelled);
    expect(order.fulfilledDate, isNull);
  });

  test('rejects moving an order back to pending', () async {
    await useCases.create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;

    final result = await useCases.updateStatus(
      orderId: orderId,
      status: OrderStatus.pending,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('rejects updating an already-settled order', () async {
    await useCases.create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;

    final first = await useCases.updateStatus(
      orderId: orderId,
      status: OrderStatus.fulfilled,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(first.isOk, isTrue);

    final second = await useCases.updateStatus(
      orderId: orderId,
      status: OrderStatus.cancelled,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(second.isErr, isTrue);
    expect(second.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects updating a nonexistent order', () async {
    final result = await useCases.updateStatus(
      orderId: 'does-not-exist',
      status: OrderStatus.fulfilled,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('softDelete hides the order from getById/watchAll', () async {
    await useCases.create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;

    await useCases.softDelete(
      orderId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(await db.orderDao.getById(orderId), isNull);
  });

  test('softDelete records a delete audit log entry', () async {
    await useCases.create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;

    await useCases.softDelete(
      orderId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
    expect(auditEntries, hasLength(1));
    expect(auditEntries.single.action, 'delete');
    expect(auditEntries.single.changedTableName, 'orders');
    expect(auditEntries.single.recordId, orderId);
    expect(auditEntries.single.oldValueJson, contains('A red backpack'));
  });

  test(
    'restore un-hides the order and records a restore audit log entry',
    () async {
      await useCases.create(
        customerId: 'cust-1',
        itemDescription: 'A red backpack',
        requestedDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final orderId = (await (db.select(db.orders)).get()).single.id;
      await useCases.softDelete(
        orderId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      await useCases.restore(
        orderId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final restored = await db.orderDao.getById(orderId);
      expect(restored, isNotNull);
      expect(restored!.itemDescription, 'A red backpack');

      final auditEntries = await db.auditLogDao.watchAll(defaultShopId).first;
      final restoreEntry = auditEntries.firstWhere(
        (e) => e.action == 'restore',
      );
      expect(restoreEntry.changedTableName, 'orders');
      expect(restoreEntry.newValueJson, contains('A red backpack'));
    },
  );
}
