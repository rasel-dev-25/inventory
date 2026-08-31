import 'dart:math' as math;

/// Stats for a single Supabase Storage bucket.
class BucketStorageStats {
  final int bytes;
  final int count;

  const BucketStorageStats({
    required this.bytes,
    required this.count,
  });

  factory BucketStorageStats.fromJson(Map<String, dynamic> json) {
    return BucketStorageStats(
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'bytes': bytes,
    'count': count,
  };
}

/// Aggregated Supabase Cloud Storage statistics across all shop buckets.
class CloudStorageStats {
  final int totalBytes;
  final int quotaBytes;
  final BucketStorageStats productImages;
  final BucketStorageStats customerImages;
  final BucketStorageStats fixedAssetImages;

  const CloudStorageStats({
    required this.totalBytes,
    required this.quotaBytes,
    required this.productImages,
    required this.customerImages,
    required this.fixedAssetImages,
  });

  factory CloudStorageStats.fromJson(Map<String, dynamic> json) {
    return CloudStorageStats(
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
      quotaBytes: (json['quota_bytes'] as num?)?.toInt() ?? 26843545600, // 25 GB Cloudinary quota
      productImages: BucketStorageStats.fromJson(
        (json['product_images'] as Map<String, dynamic>?) ?? const {},
      ),
      customerImages: BucketStorageStats.fromJson(
        (json['customer_images'] as Map<String, dynamic>?) ?? const {},
      ),
      fixedAssetImages: BucketStorageStats.fromJson(
        (json['fixed_asset_images'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  double get usedPercentage {
    if (quotaBytes <= 0) return 0.0;
    final pct = (totalBytes / quotaBytes) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  int get remainingBytes => math.max(0, quotaBytes - totalBytes);
}

/// Aggregated record counts in the remote database for the shop.
class DatabaseStorageStats {
  final int totalRecords;
  final int productsCount;
  final int customersCount;
  final int salesCount;
  final int duesCount;
  final int ordersCount;
  final int expensesCount;
  final int purchasesCount;

  const DatabaseStorageStats({
    required this.totalRecords,
    required this.productsCount,
    required this.customersCount,
    required this.salesCount,
    required this.duesCount,
    required this.ordersCount,
    required this.expensesCount,
    required this.purchasesCount,
  });

  factory DatabaseStorageStats.fromJson(Map<String, dynamic> json) {
    return DatabaseStorageStats(
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
      productsCount: (json['products_count'] as num?)?.toInt() ?? 0,
      customersCount: (json['customers_count'] as num?)?.toInt() ?? 0,
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
      duesCount: (json['dues_count'] as num?)?.toInt() ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      expensesCount: (json['expenses_count'] as num?)?.toInt() ?? 0,
      purchasesCount: (json['purchases_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Local device storage usage stats.
class LocalDeviceStorageStats {
  final int databaseSizeBytes;
  final int imageCacheSizeBytes;
  final int pendingOutboxCount;

  const LocalDeviceStorageStats({
    required this.databaseSizeBytes,
    required this.imageCacheSizeBytes,
    required this.pendingOutboxCount,
  });

  int get totalLocalBytes => databaseSizeBytes + imageCacheSizeBytes;
}

/// Overall storage and quota snapshot combining cloud and local stats.
class ShopStorageUsage {
  final CloudStorageStats cloud;
  final DatabaseStorageStats database;
  final LocalDeviceStorageStats local;
  final DateTime updatedAt;

  const ShopStorageUsage({
    required this.cloud,
    required this.database,
    required this.local,
    required this.updatedAt,
  });

  /// Formats byte counts into human readable strings (e.g. "12.4 MB", "1.0 GB").
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor().clamp(0, suffixes.length - 1);
    final size = bytes / math.pow(1024, i);
    if (i == 0) return '$bytes B';
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
