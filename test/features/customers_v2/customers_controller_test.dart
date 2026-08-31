import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/order.dart';
import 'package:inventory/domain/entities/sale.dart';
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

  test('calculates totalPurchasedFor and filters visible customers by buyer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CustomersController(db);
    addTearDown(db.close);

    const c1 = Customer(id: 'c1', name: 'Buyer Customer');
    const c2 = Customer(id: 'c2', name: 'Non Buyer Customer');

    controller.customers.value = [c1, c2];
    controller.sales.value = [
      Sale(
        id: 's1',
        productId: 'p1',
        qty: 2,
        actualSellPrice: Money.fromMinor(1500),
        costPriceAtSale: Money.fromMinor(1000),
        date: DateTime.utc(2026, 8, 17),
        customerId: c1.id,
        paymentStatus: PaymentStatus.fullCash,
        paymentMethod: PaymentMethod.cash,
        fundSource: FundSource.shop(),
      ),
    ];

    expect(controller.totalPurchasedFor('c1'), Money.fromMinor(3000));
    expect(controller.purchasesCountFor('c1'), 1);
    expect(controller.totalPurchasedFor('c2'), Money.zero());
    expect(controller.buyersCount, 1);

    // When showBuyersOnly is false
    expect(controller.visibleCustomers.length, 2);

    // When showBuyersOnly is true
    controller.showBuyersOnly.value = true;
    expect(controller.visibleCustomers.length, 1);
    expect(controller.visibleCustomers.single.id, 'c1');
  });

  test('calculates ordersCountFor and filters visible customers by orders', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CustomersController(db);
    addTearDown(db.close);

    const c1 = Customer(id: 'c1', name: 'Order Customer');
    const c2 = Customer(id: 'c2', name: 'No Order Customer');

    controller.customers.value = [c1, c2];
    controller.orders.value = [
      Order(
        id: 'o1',
        customerId: 'c1',
        itemDescription: 'Pre-order item',
        requestedDate: DateTime.utc(2026, 8, 30),
        status: OrderStatus.pending,
      ),
    ];

    expect(controller.ordersCountFor('c1'), 1);
    expect(controller.ordersCountFor('c2'), 0);
    expect(controller.withOrdersCustomersCount, 1);

    // Initial (All)
    expect(controller.visibleCustomers.length, 2);

    // With orders filter
    controller.showWithOrdersOnly.value = true;
    expect(controller.visibleCustomers.length, 1);
    expect(controller.visibleCustomers.single.id, 'c1');
  });
}
