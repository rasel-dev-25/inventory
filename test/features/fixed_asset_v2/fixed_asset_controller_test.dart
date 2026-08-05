import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/fixed_asset_v2/controller/fixed_asset_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late FixedAssetController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());

    await ProductUseCases(db).create(
      Product(
        id: 'attar-bottle',
        name: 'Attar Showpiece Bottle',
        category: 'Attar',
        costPrice: Money.fromMinor(50000),
        suggestedSellPrice: Money.fromMinor(80000),
        qty: 3,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = FixedAssetController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('createFromCashPurchase adds a visible asset', () async {
    final ok = await controller.createFromCashPurchase(
      name: 'Display Showcase',
      value: Money.fromMinor(1500000),
      dateAcquired: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.assets, hasLength(1));
    expect(
      controller.assets.single.sourceType,
      FixedAssetSource.shopCashPurchase,
    );
  });

  test('createFromStock reduces the product qty visible in products', () async {
    final ok = await controller.createFromStock(
      productId: 'attar-bottle',
      qty: 1,
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.assets, hasLength(1));
    expect(controller.productById('attar-bottle')!.qty, 2);
  });

  test(
    'createFromStock surfaces a business-rule error for too much stock',
    () async {
      final ok = await controller.createFromStock(
        productId: 'attar-bottle',
        qty: 999,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.assets, isEmpty);
    },
  );

  test('deleteAsset removes it from the visible list', () async {
    await controller.createFromCashPurchase(
      name: 'Display Showcase',
      value: Money.fromMinor(1500000),
      dateAcquired: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);
    final assetId = controller.assets.single.id;

    final ok = await controller.deleteAsset(assetId);
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(controller.assets, isEmpty);
  });

  test(
    'deleteAsset surfaces an error for a nonexistent id and leaves the list untouched',
    () async {
      await controller.createFromCashPurchase(
        name: 'Display Showcase',
        value: Money.fromMinor(1500000),
        dateAcquired: DateTime.now(),
      );
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.deleteAsset('does-not-exist');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.assets, hasLength(1));
    },
  );
}
