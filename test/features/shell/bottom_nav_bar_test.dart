import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/features/shell/controller/shell_controller.dart';
import 'package:inventory/features/shell/view/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('purchase entry is directly available in bottom navigation', (
    tester,
  ) async {
    final controller = Get.put(ShellController());
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(bottomNavigationBar: AppBottomNav()),
      ),
    );

    expect(find.text('Purchase'), findsOneWidget);
    await tester.tap(find.text('Purchase'));
    await tester.pump();

    expect(controller.currentIndex.value, 5);
  });
}
