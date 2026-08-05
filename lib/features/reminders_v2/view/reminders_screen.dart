import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/services/reminder_engine.dart';
import '../controller/reminder_controller.dart';

/// The v2 Reminders inbox — every reminder `ReminderController.inbox`
/// computes (`reminder_engine.dart`), overdue ones highlighted, sorted
/// with the no-date "follow up" flags pinned first, then soonest-due.
/// See `CatalogScreen`'s doc comment for why this reads the v2 database
/// only.
class RemindersScreen extends GetView<ReminderController> {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('remindersTitle'.tr)),
      body: Obx(() {
        final reminders = controller.inbox;
        if (reminders.isEmpty) {
          return Center(child: Text('noReminders'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: reminders.length,
          itemBuilder: (context, index) => _ReminderCard(reminders[index]),
        );
      }),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard(this.reminder);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final overdue = reminder.isOverdueAsOf(now);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: overdue ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              _iconFor(reminder),
              color: overdue ? theme.colorScheme.error : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleFor(reminder), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleFor(reminder),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (reminder.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateLabel(reminder.dueDate!, overdue),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue ? theme.colorScheme.error : null,
                        fontWeight: overdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ],
              ),
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
    };
  }

  String _titleFor(Reminder r) {
    return switch (r) {
      DueBalanceReminder v => v.customerName,
      InvestorCapitalReturnReminder v => v.investor.name,
      InvestorProfitPayoutReminder v => v.investor.name,
      SuspiciousCustomerReminder v => v.customer.name,
      OverdueRentReminder v => '${v.customerName} · ${v.bookName}',
      OrderDeadlineReminder v =>
        '${v.customerName} · ${v.order.itemDescription}',
    };
  }

  String _subtitleFor(Reminder r) {
    return switch (r) {
      DueBalanceReminder v =>
        '${'dueBalanceReminderLabel'.tr}${v.remaining.format()}',
      InvestorCapitalReturnReminder _ => 'investorCapitalReminderLabel'.tr,
      InvestorProfitPayoutReminder _ => 'investorPayoutReminderLabel'.tr,
      SuspiciousCustomerReminder _ => 'suspiciousCustomerReminderLabel'.tr,
      OverdueRentReminder v =>
        '${'overdueRentReminderLabel'.tr}${v.extraDaysAsOf(DateTime.now().toUtc())}',
      OrderDeadlineReminder _ => 'orderDeadlineReminderLabel'.tr,
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
