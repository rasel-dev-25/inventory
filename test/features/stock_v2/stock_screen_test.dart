import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/stock_v2/controller/stock_controller.dart';
import 'package:inventory/features/stock_v2/view/stock_screen.dart';

void main() {
  late AppDatabase db;
  late StockController controller;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();

    await db.investorDao.create(
      const Investor(
        id: 'inv-1',
        name: 'Rahim Bhai',
        investmentType: InvestmentType.cashMudaraba,
      ),
      shopId: defaultShopId,
      now: now,
    );

    final productUseCases = ProductUseCases(db);
    await productUseCases.create(
      Product(
        id: 'p1',
        name: 'Attar Oud',
        category: 'Attar',
        costPrice: Money.fromMinor(50000), // ৳500
        suggestedSellPrice: Money.fromMinor(80000), // ৳800
        qty: 12,
        fundSource: FundSource.shop(),
        barcode: '111222333',
      ),
      shopId: defaultShopId,
      now: now,
    );

    await productUseCases.create(
      Product(
        id: 'p2',
        name: 'Iman Book',
        category: 'Book',
        costPrice: Money.fromMinor(10000), // ৳100
        suggestedSellPrice: Money.fromMinor(15000), // ৳150
        qty: 2, // low stock
        fundSource: FundSource.investor('inv-1'),
      ),
      shopId: defaultShopId,
      now: now,
    );

    Get.put<AppDatabase>(db);
    controller = StockController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    Get.put<StockController>(controller);
  });

  tearDown(() async {
    controller.onClose();
    Get.reset();
    await db.close();
  });

  testWidgets('renders category chips, investor chips, summary cards, and product list',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const StockScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify category chips
    expect(find.widgetWithText(ChoiceChip, 'All categories (2)'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Attar (1)'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Book (1)'), findsOneWidget);

    // Verify products rendered
    expect(find.text('Attar Oud'), findsOneWidget);
    expect(find.text('Iman Book'), findsOneWidget);

    // Verify summary values
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Stock Value'), findsOneWidget);
    expect(find.text('Potential profit'), findsOneWidget);

    // Verify FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tapping a category chip filters the product list reactively',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const StockScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Book category chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Book (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Iman Book'), findsOneWidget);
    expect(find.text('Attar Oud'), findsNothing);
  });
}
