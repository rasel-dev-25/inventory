import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/local/local_row_upserter.dart';
import 'package:inventory/data/usecases/fixed_asset_usecases.dart';
import 'package:test/test.dart';

void main() {
  test('pulling fixed asset image metadata preserves local path', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 18);
    final assetId = (await FixedAssetUseCases(db).createFromCashPurchase(
      name: 'Showcase',
      value: Money.fromMinor(100000),
      dateAcquired: now,
      shopId: defaultShopId,
      now: now,
    )).unwrap();
    await db.fixedAssetImageDao.create(
      FixedAssetImagesCompanion.insert(
        id: 'image-1',
        assetId: assetId,
        localPath: const Value('fixed_asset_images/local.jpg'),
        createdAt: now,
        syncedAt: now,
      ),
    );

    await LocalRowUpserter(db).upsert('fixed_asset_images', {
      'id': 'image-1',
      'asset_id': assetId,
      'local_path': null,
      'remote_url': '$assetId/image-1.jpg',
      'sort_order': 0,
      'created_at': now.toIso8601String(),
      'synced_at': now.add(const Duration(minutes: 1)).toIso8601String(),
    });

    final image = await db.fixedAssetImageDao.getById('image-1');
    expect(image?.localPath, 'fixed_asset_images/local.jpg');
    expect(image?.remoteUrl, '$assetId/image-1.jpg');
  });
}
