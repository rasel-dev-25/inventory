import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/order.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/features/customers_v2/controller/customers_controller.dart';
import 'package:test/test.dart';

void main() {
  test('createCustomer with photo queues it for Supabase upload', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CustomersController(db);
    controller.onInit();
    addTearDown(() async {
      controller.onClose();
      await db.close();
    });
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.createCustomer(
      name: 'Karim',
      photoLocalPath: 'customer_images/karim.jpg',
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.customerImages, hasLength(1));
    expect(
      controller.customerImages.single.localPath,
      'customer_images/karim.jpg',
    );
    expect(await db.syncMetadataDao.pendingUploads(), hasLength(1));
  });

  test('history helpers only return rows for the selected customer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CustomersController(db);
    addTearDown(db.close);
    const selected = Customer(id: 'c1', name: 'Karim');

    controller.orders.value = [
      Order(
        id: 'o1',
        customerId: selected.id,
        itemDescription: 'First',
        requestedDate: DateTime.utc(2026, 8, 18),
        status: OrderStatus.pending,
      ),
      Order(
        id: 'o2',
        customerId: 'c2',
        itemDescription: 'Other customer',
        requestedDate: DateTime.utc(2026, 8, 18),
        status: OrderStatus.pending,
      ),
    ];

    expect(controller.ordersFor(selected.id).map((order) => order.id), ['o1']);
  });
}
