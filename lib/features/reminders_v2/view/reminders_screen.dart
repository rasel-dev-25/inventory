import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/services/reminder_engine.dart';
import '../controller/reminder_controller.dart';

/// The v2 Reminders inbox — every reminder `ReminderController.inbox`
/// computes (`reminder_engine.dart`), with interactive tick / resolve
/// buttons, green completion status, and active vs resolved filter tabs.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _filter = 'active'; // 'active', 'all', 'resolved', 'low_stock', 'dues'

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReminderController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('remindersTitle'.tr),
        actions: [
          Obx(() {
            final hasActive = controller.hasAnyActiveAlerts;
            if (!hasActive) {
              return TextButton.icon(
                onPressed: () => controller.unresolveAll(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('রিসেট'),
              );
            }
            return TextButton.icon(
              onPressed: () {
                controller.markAllResolved();
                Get.snackbar(
                  'সব টিক দেওয়া হয়েছে',
                  'সকল অ্যালার্ট সম্পন্ন হিসেবে চিহ্নিত করা হয়েছে।',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('সব টিক দিন'),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final allReminders = controller.inbox;
        final activeCount = controller.activeCount;
        final resolvedCount = controller.resolvedCount;
        final lowStockCount = controller.lowStockCount;
        final dueCount = controller.dueCount;

        final filtered = allReminders.where((r) {
          final isRes = controller.isResolved(r.id);
          if (_filter == 'active') return !isRes;
          if (_filter == 'resolved') return isRes;
          if (_filter == 'low_stock') return r is LowStockReminder;
          if (_filter == 'dues') return r is DueBalanceReminder;
          return true;
        }).toList();

        return Column(
          children: [
            // ── Filter Chips Bar ───────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.notifications_active_outlined, size: 16),
                    label: Text('বাকি ($activeCount)'),
                    selected: _filter == 'active',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'active');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text('সম্পন্ন ($resolvedCount)'),
                    selected: _filter == 'resolved',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'resolved');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('সব (${allReminders.length})'),
                    selected: _filter == 'all',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('স্টক কম ($lowStockCount)'),
                    selected: _filter == 'low_stock',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'low_stock');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text('বকেয়া ($dueCount)'),
                    selected: _filter == 'dues',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'dues');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Reminders List ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 56,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'active'
                                ? 'কোনো বাকি অ্যালার্ট নেই! সব ঠিক আছে।'
                                : 'noReminders'.tr,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isResolved = controller.isResolved(item.id);
                        return _ReminderCard(
                          reminder: item,
                          isResolved: isResolved,
                          onToggleResolved: () => controller.toggleResolved(item.id),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final bool isResolved;
  final VoidCallback onToggleResolved;

  const _ReminderCard({
    required this.reminder,
    required this.isResolved,
    required this.onToggleResolved,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final overdue = reminder.isOverdueAsOf(now) && !isResolved;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      color: isResolved
          ? Colors.green.shade50
          : (overdue ? theme.colorScheme.errorContainer.withValues(alpha: 0.7) : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isResolved
              ? Colors.green.shade300
              : (overdue ? theme.colorScheme.error.withValues(alpha: 0.3) : Colors.grey.shade300),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isResolved
                    ? Colors.green.withValues(alpha: 0.15)
                    : (overdue
                        ? theme.colorScheme.error.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isResolved ? Icons.check_circle_rounded : _iconFor(reminder),
                color: isResolved
                    ? Colors.green.shade700
                    : (overdue ? theme.colorScheme.error : theme.colorScheme.primary),
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleFor(reminder),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: isResolved ? TextDecoration.lineThrough : null,
                            color: isResolved ? Colors.grey.shade700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleFor(reminder),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isResolved ? Colors.grey.shade600 : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (reminder.dueDate != null)
                        Text(
                          _dateLabel(reminder.dueDate!, overdue),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: overdue ? theme.colorScheme.error : Colors.grey.shade600,
                            fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      if (isResolved) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓ সম্পন্ন',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Checkmark Toggle Button
            IconButton(
              icon: Icon(
                isResolved
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isResolved ? Colors.green.shade700 : Colors.grey.shade500,
                size: 26,
              ),
              tooltip: isResolved ? 'আবার চালু করুন' : 'টিক দিন (সম্পন্ন)',
              onPressed: onToggleResolved,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Reminder r) {
    return switch (r) {
      DueBalanceReminder _ => Icons.receipt_long,
      InvestorCapitalReturnReminder _ => Icons.savings_outlined,
      InvestorProfitPayoutReminder _ => Icons.payments_outlined,
      SuspiciousCustomerReminder _ => Icons.warning_amber,
      OverdueRentReminder _ => Icons.menu_book,
      OrderDeadlineReminder _ => Icons.shopping_bag_outlined,
      LowStockReminder _ => Icons.inventory_2_outlined,
    };
  }

  String _titleFor(Reminder r) {
    return switch (r) {
      final DueBalanceReminder v => v.customerName,
      final InvestorCapitalReturnReminder v => v.investor.name,
      final InvestorProfitPayoutReminder v => v.investor.name,
      final SuspiciousCustomerReminder v => v.customer.name,
      final OverdueRentReminder v => '${v.customerName} · ${v.bookName}',
      final OrderDeadlineReminder v =>
        '${v.customerName} · ${v.order.itemDescription}',
      final LowStockReminder v => v.product.name,
    };
  }

  String _subtitleFor(Reminder r) {
    return switch (r) {
      final DueBalanceReminder v =>
        '${'dueBalanceReminderLabel'.tr}${v.remaining.format()}',
      final InvestorCapitalReturnReminder _ => 'investorCapitalReminderLabel'.tr,
      final InvestorProfitPayoutReminder _ => 'investorPayoutReminderLabel'.tr,
      final SuspiciousCustomerReminder _ => 'suspiciousCustomerReminderLabel'.tr,
      final OverdueRentReminder v =>
        '${'overdueRentReminderLabel'.tr}${v.extraDaysAsOf(DateTime.now().toUtc())}',
      final OrderDeadlineReminder _ => 'orderDeadlineReminderLabel'.tr,
      final LowStockReminder v => '${'lowStockReminderLabel'.tr}: ${v.product.qty}',
    };
  }

  String _dateLabel(DateTime date, bool overdue) {
    final formatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return overdue
        ? '${'overdueSinceLabel'.tr}$formatted'
        : '${'dueOnLabel'.tr}$formatted';
  }
}
