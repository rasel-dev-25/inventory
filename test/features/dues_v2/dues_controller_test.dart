import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/features/dues_v2/controller/dues_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DuesController controller;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();

    // Create a customer "teerer"
    await CustomerUseCases(db).create(
      const Customer(
        id: 'cust-teerer',
        name: 'teerer',
        contact: '01700000000',
        address: 'Dhaka',
      ),
      shopId: defaultShopId,
      now: now,
    );

    // Create a second customer "Rahim"
    await CustomerUseCases(db).create(
      const Customer(
        id: 'cust-rahim',
        name: 'Rahim',
        contact: '01800000000',
        address: 'Chittagong',
      ),
      shopId: defaultShopId,
      now: now,
    );

    // Create 2 dues for "teerer" (20 + 40 = 60)
    await db.dueDao.create(
      Due(
        id: 'due-1',
        customerId: 'cust-teerer',
        originalAmount: Money.fromMinor(2000),
        paidAmount: Money.zero(),
        status: DueStatus.pending,
        sourceType: DueSourceType.sale,
        sourceId: 'sale-1',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      shopId: defaultShopId,
      now: now,
    );

    await db.dueDao.create(
      Due(
        id: 'due-2',
        customerId: 'cust-teerer',
        originalAmount: Money.fromMinor(4000),
        paidAmount: Money.zero(),
        status: DueStatus.pending,
        sourceType: DueSourceType.sale,
        sourceId: 'sale-2',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      shopId: defaultShopId,
      now: now,
    );

    // Create 1 due for "Rahim" (50)
    await db.dueDao.create(
      Due(
        id: 'due-3',
        customerId: 'cust-rahim',
        originalAmount: Money.fromMinor(5000),
        paidAmount: Money.zero(),
        status: DueStatus.pending,
        sourceType: DueSourceType.sale,
        sourceId: 'sale-3',
        createdAt: now,
      ),
      shopId: defaultShopId,
      now: now,
    );

    controller = DuesController(db);
    controller.onInit();
    await pumpEventQueue();
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('groups multiple dues of the same customer under a single CustomerDueGroup', () {
    expect(controller.customerDueGroups.length, 2);

    final teererGroup = controller.customerDueGroups.firstWhere(
      (g) => g.customerId == 'cust-teerer',
    );
    expect(teererGroup.customerName, 'teerer');
    expect(teererGroup.dueCount, 2);
    expect(teererGroup.totalOriginalAmount, Money.fromMinor(6000));
    expect(teererGroup.totalRemainingAmount, Money.fromMinor(6000));

    final rahimGroup = controller.customerDueGroups.firstWhere(
      (g) => g.customerId == 'cust-rahim',
    );
    expect(rahimGroup.customerName, 'Rahim');
    expect(rahimGroup.dueCount, 1);
    expect(rahimGroup.totalRemainingAmount, Money.fromMinor(5000));

    expect(controller.totalDuesAmount, Money.fromMinor(11000));
    expect(controller.totalDueCustomersCount, 2);
  });

  test('payCustomerBalance cascades payment to oldest due first', () async {
    // Pay ৳30 against teerer (who owes ৳20 + ৳40)
    // ৳20 should fully pay due-1 (leaving 0), ৳10 should partially pay due-2 (leaving ৳30)
    final ok = await controller.payCustomerBalance(
      customerId: 'cust-teerer',
      paymentAmount: Money.fromMinor(3000),
      paymentMethod: PaymentMethod.cash,
    );
    expect(ok, isTrue);
    await pumpEventQueue();

    final teererGroup = controller.customerDueGroups.firstWhere(
      (g) => g.customerId == 'cust-teerer',
    );
    expect(teererGroup.dueCount, 1); // due-1 is paid and removed from outstanding
    expect(teererGroup.totalRemainingAmount, Money.fromMinor(3000));

    // Remaining due is due-2 with remaining balance ৳30
    final remainingDue = teererGroup.dues.single;
    expect(remainingDue.id, 'due-2');
    expect(remainingDue.paidAmount, Money.fromMinor(1000));
  });

  test('payDue pays individual due directly', () async {
    final ok = await controller.payDue(
      dueId: 'due-3',
      paymentAmount: Money.fromMinor(5000),
      paymentMethod: PaymentMethod.cash,
    );
    expect(ok, isTrue);
    await pumpEventQueue();

    // Rahim's due is fully paid, so Rahim is no longer in customerDueGroups
    expect(controller.customerDueGroups.any((g) => g.customerId == 'cust-rahim'), isFalse);
    expect(controller.totalDueCustomersCount, 1);
  });

  test('records and tracks payment history for customers and dues', () async {
    // Initial payments should be empty
    expect(controller.duePayments.isEmpty, isTrue);
    expect(controller.totalCollectedAmount, Money.zero());

    // Pay ৳15 to due-1
    await controller.payDue(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(1500),
      paymentMethod: PaymentMethod.mobileBanking,
    );
    await pumpEventQueue();

    expect(controller.duePayments.length, 1);
    expect(controller.totalCollectedAmount, Money.fromMinor(1500));

    final teererPayments = controller.paymentsForCustomer('cust-teerer');
    expect(teererPayments.length, 1);
    expect(teererPayments.first.amount, Money.fromMinor(1500));
    expect(teererPayments.first.paymentMethod, PaymentMethod.mobileBanking);

    final due1Payments = controller.paymentsForDue('due-1');
    expect(due1Payments.length, 1);
    expect(due1Payments.first.amount, Money.fromMinor(1500));

    // Pay another ৳5 to due-1 (settling it completely)
    await controller.payDue(
      dueId: 'due-1',
      paymentAmount: Money.fromMinor(500),
      paymentMethod: PaymentMethod.cash,
    );
    await pumpEventQueue();

    expect(controller.duePayments.length, 2);
    expect(controller.totalCollectedAmount, Money.fromMinor(2000));
    expect(controller.totalCollectedForCustomer('cust-teerer'), Money.fromMinor(2000));
    expect(controller.paymentsForDue('due-1').length, 2);
  });
}
