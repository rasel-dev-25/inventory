import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/features/customers_v2/view/customer_form_sheet.dart';

void main() {
  testWidgets('captures and previews a customer photo', (tester) async {
    var captureCalls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CustomerFormSheet(
            onCapturePhoto: () async {
              captureCalls++;
              return 'missing-customer-photo.jpg';
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add customer photo'));
    await tester.pump();

    expect(captureCalls, 1);
    expect(find.text('Change customer photo'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
