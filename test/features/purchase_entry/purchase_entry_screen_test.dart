import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/features/purchase_entry/controller/purchase_entry_controller.dart';
import 'package:inventory/features/purchase_entry/view/purchase_entry_screen.dart';
import 'package:inventory/features/purchase_entry/view/purchase_trip_form_sheet.dart';

void main() {
  late AppDatabase db;
  late PurchaseEntryController controller;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();

    final productUseCases = ProductUseCases(db);
    await productUseCases.create(
      Product(
        id: 'p1',
        name: 'Attar Oud',
        category: 'Attar',
        costPrice: Money.fromMinor(50000),
        suggestedSellPrice: Money.fromMinor(80000),
        qty: 10,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: now,
    );

    controller = PurchaseEntryController(db);
    Get.put<AppDatabase>(db);
    Get.put<PurchaseEntryController>(controller);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
    Get.reset();
  });

  Widget createSubject() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const PurchaseEntryScreen(),
    );
  }

  testWidgets('shows empty state and FAB when no purchase trips exist', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('No purchase trips yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add Purchase'), findsOneWidget);
  });

  testWidgets('tapping FAB opens PurchaseTripFormSheet modal bottom sheet', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseTripFormSheet), findsOneWidget);
    expect(find.text('New Purchase Trip'), findsOneWidget);
    expect(find.text('Trip Date'), findsOneWidget);
    expect(find.text('Transport Cost'), findsOneWidget);
    expect(find.text('Save Purchase'), findsOneWidget);

    Navigator.of(tester.element(find.byType(PurchaseTripFormSheet))).pop(false);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseTripFormSheet), findsNothing);
  });

  testWidgets('shows list of trips and tapping a trip opens edit sheet', (tester) async {
    final now = DateTime.now().toUtc();
    final trip = PurchaseTrip(
      id: 'trip-1',
      date: DateTime.now(),
      transportCost: Money.fromMinor(20000),
      cashReturned: Money.zero(),
      actualCashTakenOut: Money.fromMinor(70000),
      items: [
        PurchaseItem(
          id: 'item-1',
          shopName: 'Main Store',
          productId: 'p1',
          qty: 1,
          unitPrice: Money.fromMinor(50000),
          fundSource: FundSource.shop(),
        ),
      ],
    );

    await db.purchaseDao.saveTrip(trip, shopId: defaultShopId, now: now);
    controller.recentTrips.assignAll([trip]);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Attar Oud'), findsOneWidget);
    expect(find.textContaining('700.00'), findsWidgets);

    await tester.tap(find.textContaining('Attar Oud'));
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseTripFormSheet), findsOneWidget);
    expect(find.text('Edit Purchase Trip'), findsOneWidget);

    Navigator.of(tester.element(find.byType(PurchaseTripFormSheet))).pop(false);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseTripFormSheet), findsNothing);
  });
}
