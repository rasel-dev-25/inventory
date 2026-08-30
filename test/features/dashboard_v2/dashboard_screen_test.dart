import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/features/dashboard_v2/controller/dashboard_controller.dart';
import 'package:inventory/features/dashboard_v2/view/dashboard_screen.dart';
import 'package:inventory/features/shell/controller/shell_controller.dart';

void main() {
  late AppDatabase db;
  late DashboardController dashboardController;
  late ShellController shellController;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Create an expense
    await ExpenseUseCases(db).create(
      Expense(
        id: 'e1',
        category: ExpenseCategory.dailyOther,
        amount: Money.fromMinor(50000), // ৳500
        date: DateTime.now().toUtc(),
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    Get.put<AppDatabase>(db);
    dashboardController = DashboardController(db);
    dashboardController.onInit();
    await Future<void>.delayed(Duration.zero);
    shellController = ShellController();

    Get.put<DashboardController>(dashboardController);
    Get.put<ShellController>(shellController);
  });

  tearDown(() async {
    dashboardController.onClose();
    Get.reset();
    await db.close();
  });

  testWidgets('renders all overview cards including due, expense, and toGiveAway',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Cash'), findsOneWidget);
    expect(find.text('Stock Value'), findsOneWidget);
    expect(find.text('Total sale'), findsOneWidget);
    expect(find.text('Total purchase'), findsOneWidget);
    expect(find.text('Total Due'), findsOneWidget);
    expect(find.text('Total Expense'), findsOneWidget);
    expect(find.text('To Give Away'), findsOneWidget);
    expect(find.text('Net Loss'), findsOneWidget); // -৳500 from expense
  });

  testWidgets('tapping stock card switches shell tab to 2', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(shellController.currentIndex.value, 0);

    // Tap on Stock Value card
    await tester.tap(find.text('Stock Value'));
    await tester.pump();

    expect(shellController.currentIndex.value, 2);
  });

  testWidgets('tapping total due card switches shell tab to 3', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Total Due card
    await tester.tap(find.text('Total Due'));
    await tester.pump();

    expect(shellController.currentIndex.value, 3);
  });
}
