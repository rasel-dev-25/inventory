import 'package:get/get.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/local/local_storage_metrics_service.dart';
import '../../../data/remote/supabase_storage_metrics_service.dart';
import '../../../domain/entities/storage_usage.dart';
import '../../auth/controller/auth_controller.dart';

/// Reactive controller managing cloud and local storage metrics for the app drawer.
class StorageUsageController extends GetxController {
  static const _tag = 'StorageUsageController';

  final SupabaseStorageMetricsService _remoteService;
  final LocalStorageMetricsService _localService;
  final AuthController _authController;

  StorageUsageController({
    required SupabaseStorageMetricsService remoteService,
    required LocalStorageMetricsService localService,
    required AuthController authController,
  })  : _remoteService = remoteService,
        _localService = localService,
        _authController = authController;

  final storageUsage = Rxn<ShopStorageUsage>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsage(showLoading: false);
  }

  /// Fetches both cloud and local storage stats, updating [storageUsage].
  Future<void> fetchUsage({bool showLoading = true}) async {
    if (showLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final localStats = await _localService.fetchLocalMetrics();

      CloudStorageStats cloudStats = const CloudStorageStats(
        totalBytes: 0,
        quotaBytes: 1073741824, // 1 GB default
        productImages: BucketStorageStats(bytes: 0, count: 0),
        customerImages: BucketStorageStats(bytes: 0, count: 0),
        fixedAssetImages: BucketStorageStats(bytes: 0, count: 0),
      );

      DatabaseStorageStats dbStats = const DatabaseStorageStats(
        totalRecords: 0,
        productsCount: 0,
        customersCount: 0,
        salesCount: 0,
        duesCount: 0,
        ordersCount: 0,
        expensesCount: 0,
        purchasesCount: 0,
      );

      final hasShop = _authController.session.value?.hasShop == true;
      if (hasShop) {
        final result = await _remoteService.fetchRemoteMetrics();
        result.fold(
          onOk: (metrics) {
            cloudStats = metrics.cloud;
            dbStats = metrics.database;
          },
          onErr: (failure) {
            AppLogger.w(
              _tag,
              'Could not fetch remote metrics: ${failure.message}',
            );
          },
        );
      }

      storageUsage.value = ShopStorageUsage(
        cloud: cloudStats,
        database: dbStats,
        local: localStats,
        updatedAt: DateTime.now(),
      );
    } catch (e, stack) {
      AppLogger.e(
        _tag,
        'Failed to fetch storage usage: $e',
        error: e,
        stackTrace: stack,
      );
      errorMessage.value = 'storageError'.tr;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  double get usedPercentage => storageUsage.value?.cloud.usedPercentage ?? 0.0;

  String get formattedCloudUsed =>
      ShopStorageUsage.formatBytes(storageUsage.value?.cloud.totalBytes ?? 0);

  String get formattedCloudQuota =>
      ShopStorageUsage.formatBytes(storageUsage.value?.cloud.quotaBytes ?? 1073741824);

  String get formattedCloudRemaining =>
      ShopStorageUsage.formatBytes(storageUsage.value?.cloud.remainingBytes ?? 1073741824);
}
