import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/domain/entities/storage_usage.dart';

void main() {
  group('ShopStorageUsage.formatBytes', () {
    test('formats 0 and negative bytes as 0 B', () {
      expect(ShopStorageUsage.formatBytes(0), '0 B');
      expect(ShopStorageUsage.formatBytes(-50), '0 B');
    });

    test('formats bytes under 1 KB', () {
      expect(ShopStorageUsage.formatBytes(512), '512 B');
      expect(ShopStorageUsage.formatBytes(1023), '1023 B');
    });

    test('formats kilobytes', () {
      expect(ShopStorageUsage.formatBytes(1024), '1.0 KB');
      expect(ShopStorageUsage.formatBytes(51200), '50.0 KB');
    });

    test('formats megabytes', () {
      expect(ShopStorageUsage.formatBytes(1048576), '1.0 MB');
      expect(ShopStorageUsage.formatBytes(15728640), '15.0 MB');
      expect(ShopStorageUsage.formatBytes(12400000), '11.8 MB');
    });

    test('formats gigabytes', () {
      expect(ShopStorageUsage.formatBytes(1073741824), '1.0 GB');
      expect(ShopStorageUsage.formatBytes(2147483648), '2.0 GB');
    });
  });

  group('CloudStorageStats', () {
    test('calculates usedPercentage and remainingBytes accurately', () {
      const stats = CloudStorageStats(
        totalBytes: 268435456, // 256 MB
        quotaBytes: 1073741824, // 1 GB (1024 MB)
        productImages: BucketStorageStats(bytes: 200000000, count: 20),
        customerImages: BucketStorageStats(bytes: 50000000, count: 5),
        fixedAssetImages: BucketStorageStats(bytes: 18435456, count: 2),
      );

      expect(stats.usedPercentage, 25.0);
      expect(stats.remainingBytes, 805306368); // 768 MB
    });

    test('handles zero quota gracefully without division by zero', () {
      const stats = CloudStorageStats(
        totalBytes: 500,
        quotaBytes: 0,
        productImages: BucketStorageStats(bytes: 500, count: 1),
        customerImages: BucketStorageStats(bytes: 0, count: 0),
        fixedAssetImages: BucketStorageStats(bytes: 0, count: 0),
      );

      expect(stats.usedPercentage, 0.0);
      expect(stats.remainingBytes, 0);
    });

    test('parses from valid JSON', () {
      final json = {
        'total_bytes': 10485760,
        'quota_bytes': 1073741824,
        'product_images': {'bytes': 6291456, 'count': 6},
        'customer_images': {'bytes': 2097152, 'count': 2},
        'fixed_asset_images': {'bytes': 2097152, 'count': 1},
      };

      final stats = CloudStorageStats.fromJson(json);
      expect(stats.totalBytes, 10485760);
      expect(stats.productImages.count, 6);
      expect(stats.customerImages.count, 2);
      expect(stats.fixedAssetImages.count, 1);
    });
  });

  group('LocalDeviceStorageStats', () {
    test('sums database and cache size correctly', () {
      const stats = LocalDeviceStorageStats(
        databaseSizeBytes: 2000000,
        imageCacheSizeBytes: 8000000,
        pendingOutboxCount: 3,
      );

      expect(stats.totalLocalBytes, 10000000);
      expect(stats.pendingOutboxCount, 3);
    });
  });
}
