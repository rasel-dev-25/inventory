import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/audit_log_usecases.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late RetentionPolicyUseCase useCase;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCase = RetentionPolicyUseCase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('recordAuditLog', () {
    test('writes a row with every provided field', () async {
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'delete',
        changedTableName: 'customers',
        recordId: 'cust-1',
        oldValueJson: '{"name":"Karim"}',
        now: DateTime.now().toUtc(),
      );

      final entries = await db.auditLogDao.watchAll(defaultShopId).first;
      expect(entries, hasLength(1));
      expect(entries.single.action, 'delete');
      expect(entries.single.changedTableName, 'customers');
      expect(entries.single.recordId, 'cust-1');
      expect(entries.single.oldValueJson, '{"name":"Karim"}');
      expect(entries.single.newValueJson, isNull);
    });
  });

  group('RetentionPolicyUseCase.pruneAll', () {
    test(
      'hard-deletes audit log entries older than the cutoff, keeps recent ones',
      () async {
        await recordAuditLog(
          db: db,
          shopId: defaultShopId,
          action: 'delete',
          changedTableName: 'customers',
          recordId: 'old-1',
          now: DateTime.utc(2026, 1, 1),
        );
        await recordAuditLog(
          db: db,
          shopId: defaultShopId,
          action: 'delete',
          changedTableName: 'customers',
          recordId: 'recent-1',
          now: DateTime.utc(2026, 8, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          auditLogRetentionDays: 30,
        );

        expect(result.auditLogRowsDeleted, 1);
        final remaining = await db.auditLogDao.watchAll(defaultShopId).first;
        expect(remaining, hasLength(1));
        expect(remaining.single.recordId, 'recent-1');
      },
    );

    test(
      'hard-deletes soft-deleted customers/orders/expenses older than the cutoff',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-old', name: 'Old'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        await CustomerUseCases(db).softDelete(
          'cust-old',
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );

        await CustomerUseCases(db).create(
          const Customer(id: 'cust-recent', name: 'Recent'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 1),
        );
        await CustomerUseCases(db).softDelete(
          'cust-recent',
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
        );

        expect(result.customersDeleted, 1);

        final remainingCustomers = await (db.select(db.customers)).get();
        expect(remainingCustomers.map((c) => c.id).toList(), ['cust-recent']);
      },
    );

    test(
      'never touches a row that was never soft-deleted, regardless of age',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-active', name: 'Still Active'),
          shopId: defaultShopId,
          now: DateTime.utc(2020, 1, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
        );

        expect(result.customersDeleted, 0);
        expect(await db.customerDao.getById('cust-active'), isNotNull);
      },
    );

    test(
      'prunes across customers, orders, and expenses independently',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-1', name: 'Order Customer'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        await OrderUseCases(db).create(
          customerId: 'cust-1',
          itemDescription: 'Old order',
          requestedDate: DateTime.utc(2026, 1, 1),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        final orderId = (await (db.select(db.orders)).get()).single.id;
        await OrderUseCases(db).softDelete(
          orderId,
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
          // The order's own softDelete call also wrote an audit log entry
          // dated 2026-01-01 — isolate this assertion to the recycle-bin
          // side of the policy by keeping every audit entry in this run.
          auditLogRetentionDays: 100000,
        );

        expect(result.ordersDeleted, 1);
        expect(result.customersDeleted, 0);
        expect(result.expensesDeleted, 0);
        expect(result.auditLogRowsDeleted, 0);
        expect(result.totalDeleted, 1);
      },
    );
  });
}
