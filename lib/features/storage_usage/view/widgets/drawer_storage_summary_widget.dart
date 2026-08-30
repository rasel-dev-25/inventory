import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../controller/storage_usage_controller.dart';
import 'storage_breakdown_sheet.dart';

/// Compact, elegant storage usage card designed for the upper section of [AppDrawer].
class DrawerStorageSummaryWidget extends StatelessWidget {
  const DrawerStorageSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StorageUsageController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            controller.fetchUsage(showLoading: false);
            StorageBreakdownSheet.show(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kTeal.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Obx(() {
              final stats = controller.storageUsage.value;
              final pct = controller.usedPercentage;
              final fraction = (pct / 100.0).clamp(0.0, 1.0);

              Color progressColor = kTeal;
              if (pct >= 90) {
                progressColor = Colors.redAccent;
              } else if (pct >= 70) {
                progressColor = Colors.orangeAccent;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.cloud5, size: 16, color: kTeal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'cloudStorage'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats == null && controller.isLoading.value
                          ? null
                          : fraction,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${controller.formattedCloudUsed} / ${controller.formattedCloudQuota}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${controller.formattedCloudRemaining} ${'remainingFree'.tr}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
