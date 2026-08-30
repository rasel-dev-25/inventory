import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/core/widgets/shop_app_bar_title.dart';
import 'package:inventory/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  testWidgets('shows the persisted shop name and page context', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const ShopAppBarTitle(pageTitle: 'Overview')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Shop'), findsOneWidget);
    expect(find.textContaining('Overview'), findsOneWidget);
  });
}
