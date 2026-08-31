import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../features/reminders_v2/controller/reminder_controller.dart';

/// Top-right AppBar notification bell action that displays a live badge
/// counter of all pending/overdue reminders (low stock, overdue dues, etc.).
class NotificationBellAction extends StatelessWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ReminderController>()) {
      return const SizedBox.shrink();
    }

    final reminderController = Get.find<ReminderController>();
    final theme = Theme.of(context);

    return Obx(() {
      final total = reminderController.activeCount;
      final overdue = reminderController.activeOverdueCount;
      final badgeCount = overdue > 0 ? overdue : total;

      return IconButton(
        icon: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text(
            badgeCount > 99 ? '99+' : '$badgeCount',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: overdue > 0
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          child: Icon(
            badgeCount > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_rounded,
          ),
        ),
        tooltip: 'রিমাইন্ডার ও নোটিফিকেশন',
        onPressed: () => Get.toNamed(AppRoutes.remindersV2),
      );
    });
  }
}
