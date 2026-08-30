import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/fixed_asset_image_usecases.dart';
import 'package:inventory/data/usecases/fixed_asset_usecases.dart';
import 'package:test/test.dart';

void main() {
  test('add stores fixed asset image metadata and queues upload', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 18);
    final assetResult = await FixedAssetUseCases(db).createFromCashPurchase(
      name: 'Showcase',
      value: Money.fromMinor(100000),
      dateAcquired: now,
      shopId: defaultShopId,
      now: now,
    );
    final assetId = assetResult.unwrap();

    final imageId = await FixedAssetImageUseCases(db).add(
      assetId: assetId,
      localPath: 'fixed_asset_images/showcase.jpg',
      now: now,
    );

    final image = await db.fixedAssetImageDao.getById(imageId);
    expect(image?.assetId, assetId);
    expect(image?.localPath, 'fixed_asset_images/showcase.jpg');
    final uploads = await db.syncMetadataDao.pendingUploads();
    expect(uploads, hasLength(1));
    expect(uploads.single.bucketName, FixedAssetImageUseCases.bucketName);
    expect(uploads.single.entityType, 'fixed_asset_image');

    final outbox = await db.syncMetadataDao.pendingEntries();
    final event = outbox.firstWhere(
      (entry) => entry.eventType == 'fixed_asset_image_created',
    );
    final upserts = OutboxEvent.decodePayload(event.payloadJson);
    expect(upserts.single.table, 'fixed_asset_images');
    expect(upserts.single.row['asset_id'], assetId);
  });
}
