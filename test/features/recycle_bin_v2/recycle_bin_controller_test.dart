import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/features/recycle_bin_v2/controller/recycle_bin_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late RecycleBinController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    controller = RecycleBinController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('starts empty with nothing deleted', () {
    expect(controller.deletedCustomers, isEmpty);
    expect(controller.deletedOrders, isEmpty);
    expect(controller.deletedExpenses, isEmpty);
  });

  test(
    'a soft-deleted customer appears, and restore removes it again',
    () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-1', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await CustomerUseCases(db).softDelete(
        'cust-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedCustomers, hasLength(1));
      expect(controller.deletedCustomers.single.name, 'Karim');

      final ok = await controller.restoreCustomer('cust-1');
      expect(ok, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedCustomers, isEmpty);
      expect(await db.customerDao.getById('cust-1'), isNotNull);
    },
  );

  test('a soft-deleted order appears, and restore removes it again', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'cust-1', name: 'Karim'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await OrderUseCases(db).create(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;
    await OrderUseCases(
      db,
    ).softDelete(orderId, shopId: defaultShopId, now: DateTime.now().toUtc());
    await Future<void>.delayed(Duration.zero);

    expect(controller.deletedOrders, hasLength(1));

    final ok = await controller.restoreOrder(orderId);
    expect(ok, isTrue, reason: controller.errorMessage.value);
    await Future<void>.delayed(Duration.zero);

    expect(controller.deletedOrders, isEmpty);
  });

  test(
    'a soft-deleted expense appears in the bin (view-only, no restore method)',
    () async {
      await ExpenseUseCases(db).create(
        Expense(
          id: 'expense-1',
          category: ExpenseCategory.dailyOther,
          amount: Money.fromMinor(5000),
          date: DateTime.utc(2026, 1, 1),
          paymentMethod: PaymentMethod.cash,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await ExpenseUseCases(db).softDelete(
        'expense-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedExpenses, hasLength(1));
      expect(controller.deletedExpenses.single.amountMinor, 5000);
    },
  );

  test(
    'pruneNow removes items past the retention window and reports the count',
    () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-old', name: 'Old'),
        shopId: defaultShopId,
        now: DateTime.utc(2020, 1, 1),
      );
      await CustomerUseCases(db).softDelete(
        'cust-old',
        shopId: defaultShopId,
        now: DateTime.utc(2020, 1, 1),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.deletedCustomers, hasLength(1));

      await controller.pruneNow(recycleBinRetentionDays: 30);
      await Future<void>.delayed(Duration.zero);

      expect(controller.lastPruneResult.value, isNotNull);
      expect(controller.lastPruneResult.value!.customersDeleted, 1);
      expect(controller.deletedCustomers, isEmpty);
    },
  );
}
