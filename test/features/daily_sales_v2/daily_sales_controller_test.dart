import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/daily_sales_v2/controller/daily_sales_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailySalesController controller;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await ProductUseCases(db).create(
      Product(
        id: 'prod-1',
        name: 'Item 1',
        category: 'General',
        costPrice: Money.fromMinor(5000),
        suggestedSellPrice: Money.fromMinor(8000),
        qty: 15,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await CustomerUseCases(db).create(
      const Customer(
        id: 'cust-1',
        name: 'Karim',
        contact: '01711111111',
        address: 'Dhaka',
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = DailySalesController(db);
    controller.onInit();
    await pumpEventQueue();
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('logs sale, edits sale, and deletes sale reactively', () async {
    // 1. Log sale
    final logSuccess = await controller.logSale(
      productId: 'prod-1',
      qty: 3,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(24000),
      paymentMethod: PaymentMethod.cash,
    );
    expect(logSuccess, isTrue);
    await pumpEventQueue();

    expect(controller.recentSales.length, 1);
    final sale = controller.recentSales.first;
    expect(sale.qty, 3.0);

    // 2. Edit sale
    final editSuccess = await controller.editSale(
      saleId: sale.id,
      qty: 5,
      actualSellPrice: Money.fromMinor(8500),
      amountReceivedNow: Money.fromMinor(42500),
      paymentMethod: PaymentMethod.cash,
    );
    expect(editSuccess, isTrue);
    await pumpEventQueue();

    expect(controller.recentSales.length, 1);
    final editedSale = controller.recentSales.first;
    expect(editedSale.qty, 5.0);
    expect(editedSale.actualSellPrice, Money.fromMinor(8500));

    // 3. Delete sale
    final deleteSuccess = await controller.deleteSale(sale.id);
    expect(deleteSuccess, isTrue);
    await pumpEventQueue();

    expect(controller.recentSales.isEmpty, isTrue);

    // Product stock should be restored to initial 15
    final prod = controller.productById('prod-1');
    expect(prod?.qty, 15.0);
  });

  test('filters sales by date and calculates daily summary metrics', () async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Sale on today
    await controller.logSale(
      productId: 'prod-1',
      qty: 2,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(16000),
      paymentMethod: PaymentMethod.cash,
      date: today,
    );

    // Sale on yesterday
    await controller.logSale(
      productId: 'prod-1',
      qty: 1,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(8000),
      paymentMethod: PaymentMethod.cash,
      date: yesterday,
    );
    await pumpEventQueue();

    // Verify today's metrics
    controller.setDate(today);
    expect(controller.salesForSelectedDate.length, 1);
    expect(controller.totalSalesAmount, Money.fromMinor(16000));
    expect(controller.totalProfitAmount, Money.fromMinor(6000)); // (8000-5000)*2
    expect(controller.totalUnitsSold, 2.0);
    expect(controller.isToday, isTrue);

    // Navigate to yesterday
    controller.previousDay();
    expect(controller.salesForSelectedDate.length, 1);
    expect(controller.totalSalesAmount, Money.fromMinor(8000));
    expect(controller.totalProfitAmount, Money.fromMinor(3000)); // (8000-5000)*1
    expect(controller.totalUnitsSold, 1.0);
    expect(controller.isToday, isFalse);

    // Go back to today
    controller.goToToday();
    expect(controller.isToday, isTrue);
  });

  test('correctly calculates cashReceived, dueAmount, and breakdown for partial and full due sales', () async {
    // 1. Partial sale: Total ৳80, Cash ৳20, Due ৳60
    final partialOk = await controller.logSale(
      productId: 'prod-1',
      qty: 1,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(2000),
      paymentMethod: PaymentMethod.cash,
      customerId: 'cust-1',
    );
    expect(partialOk, isTrue);
    await pumpEventQueue();

    final partialSale = controller.recentSales.first;
    expect(partialSale.paymentStatus, PaymentStatus.partial);
    expect(controller.cashReceivedForSale(partialSale), Money.fromMinor(2000));
    expect(controller.dueAmountForSale(partialSale), Money.fromMinor(6000));

    // 2. Full due sale: Total ৳80, Cash ৳0, Due ৳80
    final dueOk = await controller.logSale(
      productId: 'prod-1',
      qty: 1,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
      customerId: 'cust-1',
    );
    expect(dueOk, isTrue);
    await pumpEventQueue();

    final fullDueSale = controller.recentSales.firstWhere(
      (s) => s.paymentStatus == PaymentStatus.fullDue,
    );
    expect(fullDueSale.paymentStatus, PaymentStatus.fullDue);
    expect(controller.cashReceivedForSale(fullDueSale), Money.zero());
    expect(controller.dueAmountForSale(fullDueSale), Money.fromMinor(8000));

    // Daily totals
    expect(controller.totalSalesAmount, Money.fromMinor(16000));
    expect(controller.totalCashAmount, Money.fromMinor(2000));
    expect(controller.totalDueAmount, Money.fromMinor(14000));
  });

  test('createQuickCustomer creates a customer and outstandingDueForCustomer calculates correctly', () async {
    // 1. Create quick customer
    final created = await controller.createQuickCustomer(
      name: 'Rahim Khan',
      contact: '01822222222',
      address: 'Chittagong',
    );
    expect(created, isNotNull);
    expect(created!.name, 'Rahim Khan');
    expect(created.contact, '01822222222');
    await pumpEventQueue();

    // Verify it is in controller.customers
    expect(controller.customers.any((c) => c.id == created.id), isTrue);

    // Initial due should be zero
    expect(controller.outstandingDueForCustomer(created.id), Money.zero());

    // Log a partial sale for this new customer
    await controller.logSale(
      productId: 'prod-1',
      qty: 1,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(3000),
      paymentMethod: PaymentMethod.cash,
      customerId: created.id,
    );
    await pumpEventQueue();

    // Now due should be ৳50.00 (5000 minor units)
    expect(controller.outstandingDueForCustomer(created.id), Money.fromMinor(5000));
  });
}

