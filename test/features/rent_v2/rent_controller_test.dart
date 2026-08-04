import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/rent_v2/controller/rent_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late RentController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 3,
        fundSource: FundSource.shop(),
        isRentable: true,
        pageCount: 120,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = RentController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('suggestedTierFor matches the seeded tier for the page count', () {
    final book = controller.productById('book-a')!;
    final suggestion = controller.suggestedTierFor(book);
    expect(suggestion!.days, 15);
    expect(suggestion.price, Money.fromMinor(2000));
  });

  test(
    'issuing a rental decreases available copies and appears in activeRentals',
    () async {
      final book = controller.productById('book-a')!;
      expect(controller.availableCopiesFor(book), 3);

      final ok = await controller.issueRent(
        bookProductId: 'book-a',
        customerId: 'cust-1',
        deposit: Money.fromMinor(1000),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(
        controller.availableCopiesFor(controller.productById('book-a')!),
        2,
      );
      expect(controller.activeRentals, hasLength(1));
      expect(controller.history, isEmpty);
    },
  );

  test('returning a rental moves it from activeRentals to history', () async {
    await controller.issueRent(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: Money.fromMinor(2000),
      days: 15,
      rentPrice: Money.fromMinor(2000),
    );
    await Future<void>.delayed(Duration.zero);
    final rent = controller.activeRentals.single;

    final ok = await controller.returnRent(
      rentId: rent.id,
      amountReceivedNow: Money.zero(),
      paymentMethod: PaymentMethod.cash,
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.activeRentals, isEmpty);
    expect(controller.history, hasLength(1));
    expect(controller.history.single.status, RentStatus.returned);
  });

  test(
    'markStolen removes the rental from activeRentals and blocks the customer',
    () async {
      await controller.issueRent(
        bookProductId: 'book-a',
        customerId: 'cust-1',
        deposit: Money.zero(),
        days: 15,
        rentPrice: Money.fromMinor(2000),
      );
      await Future<void>.delayed(Duration.zero);
      final rent = controller.activeRentals.single;

      final ok = await controller.markStolen(rent.id);
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.activeRentals, isEmpty);
      expect(controller.customers.single.isBlocked, isTrue);
    },
  );

  test(
    'suggestedExtraDayChargeFor derives a per-day rate from the agreed price',
    () async {
      await controller.issueRent(
        bookProductId: 'book-a',
        customerId: 'cust-1',
        deposit: Money.zero(),
        days: 10,
        rentPrice: Money.fromMinor(1000),
      );
      await Future<void>.delayed(Duration.zero);
      final rent = controller.activeRentals.single;

      // 3 days late at ৳100/day (1000 minor / 10 days) = ৳300.
      final actualReturn = rent.dueDate.add(const Duration(days: 3));
      final suggestion = controller.suggestedExtraDayChargeFor(
        rent,
        actualReturn,
      );
      expect(suggestion, Money.fromMinor(300));
    },
  );
}
