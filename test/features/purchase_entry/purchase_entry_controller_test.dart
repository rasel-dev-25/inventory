import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/purchase_entry/controller/purchase_entry_controller.dart';
import 'package:test/test.dart';

/// Covers [PurchaseEntryController.recentTrips]/[PurchaseEntryController.deleteTrip]
/// — the first real UI trigger for `DeletePurchaseTripUseCase`, previously
/// dead code with no reachable delete action anywhere (see that use
/// case's own doc comment). The save/reconciliation-preview behavior
/// this controller also holds is exercised by `SavePurchaseTripUseCase`'s
/// own tests, not duplicated here.
void main() {
  late AppDatabaseV2 db;
  late PurchaseEntryController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());

    await ProductUseCases(db).create(
      Product(
        id: 'notebook',
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

    controller = PurchaseEntryController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  Future<void> saveOneItemTrip() async {
    controller.addItem();
    final item = controller.items.single;
    item.productId = 'notebook';
    item.qty = 2;
    item.unitPrice = Money.fromMinor(4000);
    controller.items.refresh();

    final ok = await controller.save();
    await Future<void>.delayed(Duration.zero);
    expect(ok, isTrue);
  }

  test('a saved trip appears in recentTrips', () async {
    await saveOneItemTrip();

    expect(controller.recentTrips, hasLength(1));
    expect(controller.recentTrips.single.items.single.productId, 'notebook');
  });

  test(
    'deleteTrip removes it from recentTrips and reverses its stock impact',
    () async {
      await saveOneItemTrip();
      final tripId = controller.recentTrips.single.id;
      final afterSave = await db.productDao.getById('notebook');
      expect(afterSave!.qty, 2);

      final ok = await controller.deleteTrip(tripId);
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.recentTrips, isEmpty);

      final afterDelete = await db.productDao.getById('notebook');
      expect(
        afterDelete!.qty,
        0,
        reason: 'deleting the trip must reverse the stock it brought in',
      );
    },
  );

  test(
    'deleteTrip surfaces an error for a nonexistent id and leaves recentTrips untouched',
    () async {
      await saveOneItemTrip();

      final ok = await controller.deleteTrip('does-not-exist');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.recentTrips, hasLength(1));
    },
  );
}
