import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/storage_usage.dart';
import 'app_database.dart';

/// Measures local on-device database and cache file sizes.
class LocalStorageMetricsService {
  final AppDatabase _db;

  LocalStorageMetricsService(this._db);

  Future<LocalDeviceStorageStats> fetchLocalMetrics() async {
    int dbSize = 0;
    int imageCacheSize = 0;
    int pendingOutbox = 0;

    try {
      final docDir = await getApplicationDocumentsDirectory();

      // Check database and sqlite journal/wal files
      final dbCandidates = [
        File(p.join(docDir.path, 'al_ashab_v2.sqlite')),
        File(p.join(docDir.path, 'al_ashab_v2.sqlite-wal')),
        File(p.join(docDir.path, 'al_ashab_v2.sqlite-shm')),
        File(p.join(docDir.path, 'al_ashab_v2.db')),
      ];

      for (final candidate in dbCandidates) {
        if (await candidate.exists()) {
          dbSize += await candidate.length();
        }
      }

      // Check local image directory if it exists
      final imagesDir = Directory(p.join(docDir.path, 'images'));
      if (await imagesDir.exists()) {
        await for (final entity
            in imagesDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            imageCacheSize += await entity.length();
          }
        }
      }

      // Pending outbox and pending upload entries
      final pendingEntries =
          await _db.syncMetadataDao.pendingEntries(limit: 1000);
      final pendingUploads =
          await _db.syncMetadataDao.pendingUploads(limit: 1000);
      pendingOutbox = pendingEntries.length + pendingUploads.length;
    } catch (_) {
      // Best-effort local inspection — non-fatal on environments where file access is restricted
    }

    return LocalDeviceStorageStats(
      databaseSizeBytes: dbSize,
      imageCacheSizeBytes: imageCacheSize,
      pendingOutboxCount: pendingOutbox,
    );
  }

  /// Calculates actual photo metrics stored in Cloudinary from database image tables.
  Future<({BucketStorageStats productImages, BucketStorageStats customerImages, BucketStorageStats fixedAssetImages, int totalBytes})>
      fetchCloudinaryMetrics() async {
    int productBytes = 0;
    int productCount = 0;
    int customerBytes = 0;
    int customerCount = 0;
    int fixedAssetBytes = 0;
    int fixedAssetCount = 0;

    try {
      final pImages = await _db.productImageDao.select(_db.productImages).get();
      productCount = pImages.length;
      for (final img in pImages) {
        if (img.localPath != null) {
          final f = File(img.localPath!);
          if (f.existsSync()) {
            productBytes += f.lengthSync();
            continue;
          }
        }
        if (img.remoteUrl != null && img.remoteUrl!.isNotEmpty) {
          productBytes += 153600; // ~150 KB default
        }
      }

      final cImages = await _db.customerImageDao.select(_db.customerImages).get();
      customerCount = cImages.length;
      for (final img in cImages) {
        if (img.localPath != null) {
          final f = File(img.localPath!);
          if (f.existsSync()) {
            customerBytes += f.lengthSync();
            continue;
          }
        }
        if (img.remoteUrl != null && img.remoteUrl!.isNotEmpty) {
          customerBytes += 153600;
        }
      }

      final fImages = await _db.fixedAssetImageDao.select(_db.fixedAssetImages).get();
      fixedAssetCount = fImages.length;
      for (final img in fImages) {
        if (img.localPath != null) {
          final f = File(img.localPath!);
          if (f.existsSync()) {
            fixedAssetBytes += f.lengthSync();
            continue;
          }
        }
        if (img.remoteUrl != null && img.remoteUrl!.isNotEmpty) {
          fixedAssetBytes += 153600;
        }
      }
    } catch (_) {}

    final totalBytes = productBytes + customerBytes + fixedAssetBytes;
    return (
      productImages: BucketStorageStats(bytes: productBytes, count: productCount),
      customerImages: BucketStorageStats(bytes: customerBytes, count: customerCount),
      fixedAssetImages: BucketStorageStats(bytes: fixedAssetBytes, count: fixedAssetCount),
      totalBytes: totalBytes,
    );
  }
}
