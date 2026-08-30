import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

class FixedAssetImageUseCases {
  static const bucketName = 'fixed-asset-images';
  static const _uuid = Uuid();

  final AppDatabase db;

  FixedAssetImageUseCases(this.db);

  Future<String> add({
    required String assetId,
    required String localPath,
    required DateTime now,
  }) async {
    final imageId = _uuid.v7();
    final extension = path.extension(localPath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final storagePath = '$assetId/$imageId$safeExtension';

    await db.transaction(() async {
      await writeAndEnqueue(
        db: db,
        eventType: 'fixed_asset_image_created',
        upserts: [
          TableUpsert(
            table: 'fixed_asset_images',
            row: {'id': imageId, 'asset_id': assetId, 'sort_order': 0},
          ),
        ],
        localWrite: () => db.fixedAssetImageDao.create(
          FixedAssetImagesCompanion.insert(
            id: imageId,
            assetId: assetId,
            localPath: Value(localPath),
            createdAt: now,
            syncedAt: now,
          ),
        ),
      );
      await db.syncMetadataDao.enqueueUpload(
        id: _uuid.v7(),
        localPath: localPath,
        storagePath: storagePath,
        bucketName: bucketName,
        entityType: 'fixed_asset_image',
        entityId: imageId,
        priority: 0,
        now: now,
      );
    });

    return imageId;
  }
}
