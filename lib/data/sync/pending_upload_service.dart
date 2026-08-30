import '../local/app_database.dart';
import '../local/daos/sync_metadata_dao.dart';
import '../usecases/sync_enqueue_helper.dart';
import 'outbox_event.dart';
import 'storage_upload_transport.dart';

class PendingUploadSummary {
  final int succeeded;
  final int failed;

  const PendingUploadSummary({required this.succeeded, required this.failed});
}

class PendingUploadService {
  final AppDatabase _db;
  final SyncMetadataDao _metadataDao;
  final StorageUploadTransport _transport;

  PendingUploadService(this._db, this._metadataDao, this._transport);

  Future<PendingUploadSummary> uploadPending() async {
    final uploads = await _metadataDao.pendingUploads();
    var succeeded = 0;
    var failed = 0;

    for (final upload in uploads) {
      final result = await _transport.upload(
        bucketName: upload.bucketName,
        storagePath: upload.storagePath,
        localPath: upload.localPath,
      );

      await result.fold(
        onOk: (_) async {
          if (upload.entityType == 'product_image') {
            final image = await _db.productImageDao.getById(upload.entityId);
            if (image != null) {
              final now = DateTime.now().toUtc();
              await writeAndEnqueue(
                db: _db,
                eventType: 'product_image_uploaded',
                upserts: [
                  TableUpsert(
                    table: 'product_images',
                    row: {
                      'id': image.id,
                      'product_id': image.productId,
                      'remote_url': upload.storagePath,
                    },
                  ),
                ],
                localWrite: () => _db.transaction(() async {
                  await _db.productImageDao.markUploaded(
                    id: image.id,
                    remoteUrl: upload.storagePath,
                    syncedAt: now,
                  );
                  await _metadataDao.markUploadDone(upload.id);
                }),
              );
            }
          } else if (upload.entityType == 'customer_image') {
            final image = await _db.customerImageDao.getById(upload.entityId);
            if (image != null) {
              final now = DateTime.now().toUtc();
              await writeAndEnqueue(
                db: _db,
                eventType: 'customer_image_uploaded',
                upserts: [
                  TableUpsert(
                    table: 'customer_images',
                    row: {
                      'id': image.id,
                      'customer_id': image.customerId,
                      'remote_url': upload.storagePath,
                    },
                  ),
                ],
                localWrite: () => _db.transaction(() async {
                  await _db.customerImageDao.markUploaded(
                    id: image.id,
                    remoteUrl: upload.storagePath,
                    syncedAt: now,
                  );
                  await _metadataDao.markUploadDone(upload.id);
                }),
              );
            }
          } else if (upload.entityType == 'fixed_asset_image') {
            final image = await _db.fixedAssetImageDao.getById(upload.entityId);
            if (image != null) {
              final now = DateTime.now().toUtc();
              await writeAndEnqueue(
                db: _db,
                eventType: 'fixed_asset_image_uploaded',
                upserts: [
                  TableUpsert(
                    table: 'fixed_asset_images',
                    row: {
                      'id': image.id,
                      'asset_id': image.assetId,
                      'remote_url': upload.storagePath,
                    },
                  ),
                ],
                localWrite: () => _db.transaction(() async {
                  await _db.fixedAssetImageDao.markUploaded(
                    id: image.id,
                    remoteUrl: upload.storagePath,
                    syncedAt: now,
                  );
                  await _metadataDao.markUploadDone(upload.id);
                }),
              );
            }
          } else {
            await _metadataDao.markUploadDone(upload.id);
          }
          succeeded++;
        },
        onErr: (_) async {
          await _metadataDao.incrementUploadAttemptCount(upload.id);
          failed++;
        },
      );
    }

    return PendingUploadSummary(succeeded: succeeded, failed: failed);
  }
}
