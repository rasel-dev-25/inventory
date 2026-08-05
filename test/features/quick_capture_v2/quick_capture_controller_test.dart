import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/quick_capture_v2/controller/quick_capture_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late QuickCaptureController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 10,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = QuickCaptureController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    await controller.createCapture(
      type: QuickCaptureType.voiceNote,
      note: 'Sold some books, forgot to log it',
    );
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('a new capture starts pending', () {
    expect(controller.pending, hasLength(1));
    expect(controller.converted, isEmpty);
  });

  test(
    'convertToExpense creates a real expense and moves the capture to converted',
    () async {
      final captureId = controller.pending.single.id;

      final ok = await controller.convertToExpense(
        captureId: captureId,
        category: ExpenseCategory.dailyOther,
        amount: Money.fromMinor(50000),
        paymentMethod: PaymentMethod.cash,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.pending, isEmpty);
      expect(controller.converted, hasLength(1));
      expect(controller.converted.single.convertedToType, 'expense');

      final expenses = await (db.select(db.expenses)).get();
      expect(expenses, hasLength(1));
      expect(expenses.single.amountMinor, 50000);
      expect(
        expenses.single.id,
        controller.converted.single.convertedToId,
        reason: 'the capture must link to the real expense it became',
      );
    },
  );

  test(
    'convertToSale creates a real sale, decreases stock, and links the capture',
    () async {
      final captureId = controller.pending.single.id;

      final ok = await controller.convertToSale(
        captureId: captureId,
        productId: 'book-a',
        qty: 2,
        actualSellPrice: Money.fromMinor(15000),
        amountReceivedNow: Money.fromMinor(30000),
        paymentMethod: PaymentMethod.cash,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.converted.single.convertedToType, 'sale');

      final product = await db.productDao.getById('book-a');
      expect(product!.qty, 8);

      final sales = await (db.select(db.sales)).get();
      expect(sales, hasLength(1));
      expect(sales.single.id, controller.converted.single.convertedToId);
    },
  );

  test(
    'convertToPurchase creates a real purchase trip and increases stock',
    () async {
      final captureId = controller.pending.single.id;

      final ok = await controller.convertToPurchase(
        captureId: captureId,
        shopName: 'Mokam Bazar',
        productId: 'book-a',
        qty: 5,
        unitPrice: Money.fromMinor(9000),
        fundSource: FundSource.shop(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.converted.single.convertedToType, 'purchase');

      final product = await db.productDao.getById('book-a');
      expect(product!.qty, 15);

      final trips = await (db.select(db.purchaseTrips)).get();
      expect(trips, hasLength(1));
      expect(trips.single.id, controller.converted.single.convertedToId);
    },
  );

  test(
    'a failed conversion (insufficient stock) leaves the capture pending',
    () async {
      final captureId = controller.pending.single.id;

      final ok = await controller.convertToSale(
        captureId: captureId,
        productId: 'book-a',
        qty: 9999,
        actualSellPrice: Money.fromMinor(15000),
        amountReceivedNow: Money.fromMinor(15000),
        paymentMethod: PaymentMethod.cash,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect(
        controller.pending,
        hasLength(1),
        reason: 'a failed conversion must never mark the capture converted',
      );
      expect(controller.converted, isEmpty);
    },
  );
}
