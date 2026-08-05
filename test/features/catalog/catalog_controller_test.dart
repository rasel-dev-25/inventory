import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/core/settings/key_value_store.dart';
import 'package:inventory/core/settings/settings_registry.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/features/catalog/controller/catalog_controller.dart';
import 'package:inventory/features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late PricingSettingsController pricingSettings;
  late CatalogController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    pricingSettings = PricingSettingsController(
      db,
      SettingsRegistry(InMemoryKeyValueStore()),
    );
    pricingSettings.onInit();
    await Future<void>.delayed(Duration.zero);

    controller = CatalogController(db, pricingSettings);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    pricingSettings.onClose();
    await db.close();
  });

  test(
    'overheadMarkupPercent passes through PricingSettingsController, null before bootstrap',
    () {
      expect(controller.overheadMarkupPercent, isNull);
    },
  );

  test('overheadMarkupPercent reflects a manually-set pricing estimate', () {
    pricingSettings.setMonthlyShopRent(Money.fromMinor(1000000));
    pricingSettings.setManualEstimatedMonthlySalesRevenue(
      Money.fromMinor(10000000),
    );

    expect(controller.overheadMarkupPercent, closeTo(0.1, 0.0001));
  });

  test('deleteProduct removes it from the visible list', () async {
    await controller.createProduct(
      name: 'Notebook',
      category: 'Stationery',
      costPrice: Money.fromMinor(5000),
      suggestedSellPrice: Money.fromMinor(8000),
      fundSource: FundSource.shop(),
    );
    await Future<void>.delayed(Duration.zero);
    final productId = controller.products.single.id;

    final ok = await controller.deleteProduct(productId);
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.products, isEmpty);
  });
}
