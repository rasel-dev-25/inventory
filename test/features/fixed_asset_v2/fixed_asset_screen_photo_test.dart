import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/features/fixed_asset_v2/controller/fixed_asset_controller.dart';
import 'package:inventory/features/fixed_asset_v2/view/fixed_asset_screen.dart';

class _TestFixedAssetController extends FixedAssetController {
  _TestFixedAssetController(super.db);

  var captureCalls = 0;

  @override
  Future<String?> captureFixedAssetPhoto() async {
    captureCalls++;
    return 'missing-fixed-asset-photo.jpg';
  }
}

void main() {
  testWidgets('cash purchase dialog captures and previews an asset photo', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _TestFixedAssetController(db);
    controller.onInit();
    Get.put<FixedAssetController>(controller);
    addTearDown(() async {
      controller.onClose();
      await db.close();
      Get.reset();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const FixedAssetScreen(),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direct Purchase'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add asset photo'));
    await tester.pump();

    expect(controller.captureCalls, 1);
    expect(find.text('Change asset photo'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
