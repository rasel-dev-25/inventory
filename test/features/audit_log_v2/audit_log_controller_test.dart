import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/features/audit_log_v2/controller/audit_log_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late AuditLogController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = AuditLogController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('starts empty', () {
    expect(controller.entries, isEmpty);
  });

  test('shows an entry after a delete happens elsewhere in the app', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'cust-1', name: 'Karim'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await CustomerUseCases(
      db,
    ).softDelete('cust-1', shopId: defaultShopId, now: DateTime.now().toUtc());
    await Future<void>.delayed(Duration.zero);

    expect(controller.entries, hasLength(2));
    expect(controller.entries.map((e) => e.action), containsAll(['insert', 'delete']));
    expect(controller.entries.first.changedTableName, 'customers');
  });

  test('shows newest entries first', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'cust-1', name: 'Karim'),
      shopId: defaultShopId,
      now: DateTime.utc(2025, 1, 1),
    );
    await CustomerUseCases(db).softDelete(
      'cust-1',
      shopId: defaultShopId,
      now: DateTime.utc(2026, 1, 1),
    );
    await CustomerUseCases(
      db,
    ).restore('cust-1', shopId: defaultShopId, now: DateTime.utc(2026, 6, 1));
    await Future<void>.delayed(Duration.zero);

    expect(controller.entries, hasLength(3));
    expect(controller.entries[0].action, 'restore');
    expect(controller.entries[1].action, 'delete');
    expect(controller.entries[2].action, 'insert');
  });

  test('filters entries by entity and action properly', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'cust-1', name: 'Rahim'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await CustomerUseCases(db).softDelete(
      'cust-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.totalCount, 2);
    expect(controller.deleteCount, 1);
    expect(controller.insertCount, 1);

    // Filter by entity
    controller.setEntityFilter('customers');
    expect(controller.filteredEntries, hasLength(2));

    controller.setEntityFilter('products');
    expect(controller.filteredEntries, isEmpty);

    // Filter by action
    controller.setEntityFilter('all');
    controller.setActionFilter('delete');
    expect(controller.filteredEntries, hasLength(1));

    controller.setActionFilter('update');
    expect(controller.filteredEntries, isEmpty);

    // Search query
    controller.setActionFilter('all');
    controller.setSearchQuery('Rahim');
    expect(controller.filteredEntries, hasLength(2));

    controller.setSearchQuery('Unknown');
    expect(controller.filteredEntries, isEmpty);
  });
}
