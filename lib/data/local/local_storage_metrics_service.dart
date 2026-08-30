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
}
