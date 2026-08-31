import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/features/catalog/view/product_form_sheet.dart';
import 'package:inventory/core/widgets/safe_image.dart';

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
            onCreateCategory: (cat) async {
              createdCategory = cat;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Islamic');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(createdCategory, 'Islamic');
    expect(find.text('Islamic'), findsWidgets);
  });

  testWidgets('captures and previews a product photo', (tester) async {
    var captureCalls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: ProductFormSheet(
            categories: const [],
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
    expect(find.byType(SafeImage), findsOneWidget);
  });
}
