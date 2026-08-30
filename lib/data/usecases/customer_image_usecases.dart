import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

class CustomerImageUseCases {
  static const bucketName = 'customer-images';
  static const _uuid = Uuid();

  final AppDatabase db;

  CustomerImageUseCases(this.db);

  Future<String> add({
    required String customerId,
    required String localPath,
    required DateTime now,
  }) async {
    final imageId = _uuid.v7();
    final extension = path.extension(localPath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final storagePath = '$customerId/$imageId$safeExtension';

    await db.transaction(() async {
      await writeAndEnqueue(
        db: db,
        eventType: 'customer_image_created',
        upserts: [
          TableUpsert(
            table: 'customer_images',
            row: {'id': imageId, 'customer_id': customerId, 'sort_order': 0},
          ),
        ],
        localWrite: () => db.customerImageDao.create(
          CustomerImagesCompanion.insert(
            id: imageId,
            customerId: customerId,
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
        entityType: 'customer_image',
        entityId: imageId,
        priority: 0,
        now: now,
      );
    });

    return imageId;
  }
}
