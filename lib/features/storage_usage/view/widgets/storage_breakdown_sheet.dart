import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/storage_usage.dart';
import '../../controller/storage_usage_controller.dart';

/// Modal bottom sheet displaying detailed storage and cloud usage breakdown.
class StorageBreakdownSheet extends StatelessWidget {
  const StorageBreakdownSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StorageBreakdownSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StorageUsageController>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Iconsax.cloud5, color: kTeal, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'storageBreakdownTitle'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'freeTierQuota'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: Obx(() {
              final stats = controller.storageUsage.value;
              final isLoading = controller.isLoading.value;

              if (stats == null && isLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: kTeal),
                      const SizedBox(height: 12),
                      Text('storageLoading'.tr),
                    ],
                  ),
                );
              }

              final cloud = stats?.cloud ??
                  const CloudStorageStats(
                    totalBytes: 0,
                    quotaBytes: 1073741824,
                    productImages: BucketStorageStats(bytes: 0, count: 0),
                    customerImages: BucketStorageStats(bytes: 0, count: 0),
                    fixedAssetImages: BucketStorageStats(bytes: 0, count: 0),
                  );

              final db = stats?.database ??
                  const DatabaseStorageStats(
                    totalRecords: 0,
                    productsCount: 0,
                    customersCount: 0,
                    salesCount: 0,
                    duesCount: 0,
                    ordersCount: 0,
                    expensesCount: 0,
                    purchasesCount: 0,
                  );

              final local = stats?.local ??
                  const LocalDeviceStorageStats(
                    databaseSizeBytes: 0,
                    imageCacheSizeBytes: 0,
                    pendingOutboxCount: 0,
                  );

              final pct = cloud.usedPercentage;
              Color progressColor = kTeal;
              if (pct >= 90) {
                progressColor = Colors.redAccent;
              } else if (pct >= 70) {
                progressColor = Colors.orangeAccent;
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Cloud Storage Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kTeal.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'cloudStorage'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}% ${'usedOf'.tr} ${ShopStorageUsage.formatBytes(cloud.quotaBytes)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (pct / 100.0).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${ShopStorageUsage.formatBytes(cloud.totalBytes)} used',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${ShopStorageUsage.formatBytes(cloud.remainingBytes)} ${'remainingFree'.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bucket Breakdown
                  _sectionTitle('cloudStorage'.tr),
                  const SizedBox(height: 8),
                  _breakdownTile(
                    icon: Iconsax.box,
                    title: 'productImagesLabel'.tr,
                    bytes: cloud.productImages.bytes,
                    count: cloud.productImages.count,
                    color: Colors.blueAccent,
                  ),
                  _breakdownTile(
                    icon: Iconsax.profile_2user,
                    title: 'customerImagesLabel'.tr,
                    bytes: cloud.customerImages.bytes,
                    count: cloud.customerImages.count,
                    color: Colors.purpleAccent,
                  ),
                  _breakdownTile(
                    icon: Iconsax.building,
                    title: 'fixedAssetImagesLabel'.tr,
                    bytes: cloud.fixedAssetImages.bytes,
                    count: cloud.fixedAssetImages.count,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 16),

                  // Database Records Breakdown
                  _sectionTitle('databaseRecordsLabel'.tr),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'databaseRecordsLabel'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${db.totalRecords} ${'recordsCount'.tr}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: kTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _recordChip(
                              'products'.tr,
                              db.productsCount,
                            ),
                            _recordChip(
                              'customers'.tr,
                              db.customersCount,
                            ),
                            _recordChip(
                              'dailySales'.tr,
                              db.salesCount,
                            ),
                            _recordChip(
                              'dues'.tr,
                              db.duesCount,
                            ),
                            _recordChip(
                              'orders'.tr,
                              db.ordersCount,
                            ),
                            _recordChip(
                              'expenses'.tr,
                              db.expensesCount,
                            ),
                            _recordChip(
                              'purchaseEntry'.tr,
                              db.purchasesCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Local Device Storage
                  _sectionTitle('localStorage'.tr),
                  const SizedBox(height: 8),
                  _breakdownTile(
                    icon: Iconsax.document_1,
                    title: 'localDatabaseLabel'.tr,
                    bytes: local.databaseSizeBytes,
                    color: Colors.teal,
                  ),
                  _breakdownTile(
                    icon: Iconsax.gallery,
                    title: 'localCacheLabel'.tr,
                    bytes: local.imageCacheSizeBytes,
                    color: Colors.indigoAccent,
                  ),
                  if (local.pendingOutboxCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.warning_2,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${'pendingSyncLabel'.tr}: ${local.pendingOutboxCount} ${'recordsCount'.tr}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Help note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          size: 16,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'storageHelpNote'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Refresh Button
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => controller.fetchUsage(showLoading: true),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Iconsax.refresh, size: 18),
                    label: Text('refreshStorage'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: kTeal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    );
  }

  Widget _breakdownTile({
    required IconData icon,
    required String title,
    required int bytes,
    required Color color,
    int? count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count != null)
                  Text(
                    '$count ${'filesCount'.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            ShopStorageUsage.formatBytes(bytes),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
