import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

class ProductImageUseCases {
  static const bucketName = 'product-images';
  static const _uuid = Uuid();

  final AppDatabase db;

  ProductImageUseCases(this.db);

  Future<String> add({
    required String productId,
    required String localPath,
    required DateTime now,
  }) async {
    final imageId = _uuid.v7();
    final extension = path.extension(localPath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final storagePath = '$productId/$imageId$safeExtension';

    await db.transaction(() async {
      await writeAndEnqueue(
        db: db,
        eventType: 'product_image_created',
        upserts: [
          TableUpsert(
            table: 'product_images',
            row: {'id': imageId, 'product_id': productId, 'sort_order': 0},
          ),
        ],
        localWrite: () => db.productImageDao.create(
          ProductImagesCompanion.insert(
            id: imageId,
            productId: productId,
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
        entityType: 'product_image',
        entityId: imageId,
        priority: 0,
        now: now,
      );
    });

    return imageId;
  }
}
