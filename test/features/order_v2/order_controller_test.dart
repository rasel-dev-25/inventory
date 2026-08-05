import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/features/order_v2/controller/order_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late OrderController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = OrderController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('createOrder adds a pending order visible in the list', () async {
    final ok = await controller.createOrder(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.orders, hasLength(1));
    expect(controller.orders.single.status, OrderStatus.pending);
    expect(controller.customerName('cust-1'), 'Test Customer');
  });

  test('selectedStatus filters visibleOrders', () async {
    await controller.createOrder(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);
    final order = controller.orders.single;

    controller.selectedStatus.value = OrderStatus.fulfilled;
    expect(controller.visibleOrders, isEmpty);

    controller.selectedStatus.value = null;
    expect(controller.visibleOrders, hasLength(1));

    await controller.markFulfilled(order.id);
    await Future<void>.delayed(Duration.zero);

    controller.selectedStatus.value = OrderStatus.fulfilled;
    expect(controller.visibleOrders, hasLength(1));
  });

  test('markCancelled updates the order status', () async {
    await controller.createOrder(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);
    final order = controller.orders.single;

    final ok = await controller.markCancelled(order.id);
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.orders.single.status, OrderStatus.cancelled);
  });

  test('deleteOrder removes it from the visible list', () async {
    await controller.createOrder(
      customerId: 'cust-1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.orders, hasLength(1));

    await controller.deleteOrder(controller.orders.single.id);
    await Future<void>.delayed(Duration.zero);

    expect(controller.orders, isEmpty);
  });
}
