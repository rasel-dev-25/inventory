import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import '../sync/storage_upload_transport.dart';
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

  Future<void> delete({
    required String imageId,
    StorageUploadTransport? storage,
  }) async {
    final image = await db.productImageDao.getById(imageId);
    if (image == null) return;

    if (image.remoteUrl != null && storage != null) {
      await storage.delete(
        bucketName: bucketName,
        storagePath: image.remoteUrl!,
      );
    }
    if (image.localPath != null) {
      final file = File(image.localPath!);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    await db.productImageDao.deleteImage(imageId);
  }
}
