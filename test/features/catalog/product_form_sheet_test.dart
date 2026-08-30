import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/features/catalog/view/product_form_sheet.dart';

void main() {
  testWidgets('creates and selects a category from the product form', (
    tester,
  ) async {
    String? createdCategory;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: ProductFormSheet(
            categories: const ['Book'],
            investors: const [],
            onCreateCategory: (name) async {
              createdCategory = name;
              return name;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add Category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Stationery');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(createdCategory, 'Stationery');
    expect(find.text('Stationery'), findsOneWidget);
  });

  testWidgets('captures and previews a product photo', (tester) async {
    var captureCalls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: ProductFormSheet(
            categories: const ['Book'],
            investors: const [],
            onCapturePhoto: () async {
              captureCalls++;
              return 'missing-test-photo.jpg';
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add product photo'));
    await tester.pump();

    expect(captureCalls, 1);
    expect(find.text('Change product photo'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
