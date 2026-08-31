import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/delete_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/data/usecases/fixed_asset_usecases.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/features/recycle_bin_v2/controller/recycle_bin_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late RecycleBinController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
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
    expect(controller.deletedProducts, isEmpty);
    expect(controller.deletedFixedAssets, isEmpty);
    expect(controller.deletedPurchaseTrips, isEmpty);
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
    'a soft-deleted product appears, and restore removes it again',
    () async {
      await ProductUseCases(db).create(
        Product(
          id: 'prod-1',
          name: 'Notebook',
          category: 'Stationery',
          costPrice: Money.fromMinor(5000),
          suggestedSellPrice: Money.fromMinor(8000),
          qty: 0,
          fundSource: FundSource.shop(),
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await ProductUseCases(db).softDelete(
        'prod-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedProducts, hasLength(1));
      expect(controller.deletedProducts.single.name, 'Notebook');

      final ok = await controller.restoreProduct('prod-1');
      expect(ok, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedProducts, isEmpty);
      expect(await db.productDao.getById('prod-1'), isNotNull);
    },
  );

  test(
    'a soft-deleted fixed asset appears in the bin (view-only, no restore method)',
    () async {
      final result = await FixedAssetUseCases(db).createFromCashPurchase(
        name: 'Display Showcase',
        value: Money.fromMinor(1500000),
        dateAcquired: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final assetId = (await (db.select(db.fixedAssets)).get()).single.id;
      await FixedAssetUseCases(
        db,
      ).delete(id: assetId, shopId: defaultShopId, now: DateTime.now().toUtc());
      await Future<void>.delayed(Duration.zero);

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      expect(controller.deletedFixedAssets, hasLength(1));
      expect(controller.deletedFixedAssets.single.name, 'Display Showcase');
    },
  );

  test(
    'a soft-deleted purchase trip appears in the bin (view-only, no restore method)',
    () async {
      await ProductUseCases(db).create(
        Product(
          id: 'prod-1',
          name: 'Notebook',
          category: 'Stationery',
          costPrice: Money.fromMinor(5000),
          suggestedSellPrice: Money.fromMinor(8000),
          qty: 0,
          fundSource: FundSource.shop(),
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final trip = PurchaseTrip(
        id: 'trip-1',
        date: DateTime.utc(2026, 1, 1),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Market Shop',
            productId: 'prod-1',
            qty: 2,
            unitPrice: Money.fromMinor(4000),
            fundSource: FundSource.shop(),
          ),
        ],
      );
      await SavePurchaseTripUseCase(
        db,
      ).call(trip, shopId: defaultShopId, now: DateTime.now().toUtc());
      final deleteResult = await DeletePurchaseTripUseCase(db).call(
        tripId: 'trip-1',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        deleteResult.isOk,
        isTrue,
        reason: deleteResult.failureOrNull?.toString(),
      );
      expect(controller.deletedPurchaseTrips, hasLength(1));
      expect(controller.deletedPurchaseTrips.single.id, 'trip-1');
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

  test(
    'permanentDeleteCustomer deletes row from DB and records audit log',
    () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-perm', name: 'Permanent Customer'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await CustomerUseCases(db).softDelete(
        'cust-perm',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.deletedCustomers, hasLength(1));

      final ok = await controller.permanentDeleteCustomer('cust-perm');
      expect(ok, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(controller.deletedCustomers, isEmpty);
      expect(await db.customerDao.getAnyById('cust-perm'), isNull);

      final auditLogs = await db.auditLogDao.watchAll(defaultShopId).first;
      expect(auditLogs.any((a) => a.action == 'PERMANENT_DELETE' && a.recordId == 'cust-perm'), isTrue);
    },
  );

  test(
    'searchQuery filters deleted items reactively',
    () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-a', name: 'Rahim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-b', name: 'Karim'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await CustomerUseCases(db).softDelete(
        'cust-a',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await CustomerUseCases(db).softDelete(
        'cust-b',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.filteredCustomers, hasLength(2));

      controller.searchQuery.value = 'Rahim';
      expect(controller.filteredCustomers, hasLength(1));
      expect(controller.filteredCustomers.single.name, 'Rahim');

      controller.searchQuery.value = '';
      expect(controller.filteredCustomers, hasLength(2));
    },
  );
}
