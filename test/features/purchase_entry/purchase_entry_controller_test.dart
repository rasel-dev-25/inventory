import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/enums.dart';
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
  late AppDatabase db;
  late PurchaseEntryController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

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
    controller.actualCashTakenOut.value = Money.fromMinor(8000);

    final ok = await controller.save();
    await Future<void>.delayed(Duration.zero);
    expect(ok, isTrue);
  }

  test('a saved trip appears in recentTrips', () async {
    await saveOneItemTrip();

    expect(controller.recentTrips, hasLength(1));
    expect(controller.recentTrips.single.items.single.productId, 'notebook');
    expect(
      controller.recentTrips.single.actualCashTakenOut,
      Money.fromMinor(8000),
    );
  });

  test('save requires the actual cash taken out', () async {
    controller.addItem();
    controller.items.single.productId = 'notebook';
    controller.items.single.unitPrice = Money.fromMinor(4000);
    controller.items.refresh();

    final ok = await controller.save();

    expect(ok, isFalse);
    expect(controller.errorMessage.value, 'actualCashRequired');
  });

  test('reconciliation preview compares calculated and actual cash', () {
    controller.addItem();
    final item = controller.items.single;
    item.productId = 'notebook';
    item.qty = 2;
    item.unitPrice = Money.fromMinor(4000);
    controller.items.refresh();

    final preview = controller.reconciliationPreview!;

    expect(preview.totalCashOut, Money.fromMinor(8000));
    expect(preview.reconciles(Money.fromMinor(8000)), isTrue);
    expect(preview.reconciles(Money.fromMinor(7000)), isFalse);
  });

  test(
    'inline investor creation makes the investor selectable immediately',
    () async {
      final investor = await controller.createInvestor(
        name: 'Mina',
        investmentType: InvestmentType.cashLoan,
        profitSharePercent: 25,
        profitPayoutCycle: ProfitPayoutCycle.monthly,
      );

      expect(investor, isNotNull);
      expect(investor!.profitSharePercent, 0);
      expect(
        controller.investors.any((item) => item.id == investor.id),
        isTrue,
      );
      expect(await db.investorDao.getById(investor.id), isNotNull);
    },
  );

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
    'editTrip reverses the old effects and records the corrected trip',
    () async {
      await saveOneItemTrip();
      final original = controller.recentTrips.single;

      controller.editTrip(original);
      final editedItem = controller.items.single;
      editedItem.qty = 5;
      controller.actualCashTakenOut.value = Money.fromMinor(20000);
      controller.items.refresh();

      final ok = await controller.save();
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(await db.purchaseDao.getById(original.id), isNull);
      expect(controller.recentTrips, hasLength(1));
      expect(controller.recentTrips.single.id, isNot(original.id));
      expect(controller.recentTrips.single.items.single.qty, 5);
      expect((await db.productDao.getById('notebook'))!.qty, 5);

      final ledgerEntries = await (db.select(
        db.cashLedgerEntries,
      )..where((l) => l.sourceType.equals('purchase'))).get();
      expect(
        ledgerEntries.fold<int>(0, (sum, entry) => sum + entry.amountMinor),
        -20000,
      );
      expect(
        (await db.syncMetadataDao.pendingEntries()).any(
          (entry) => entry.eventType == 'purchase_trip_edited',
        ),
        isTrue,
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
