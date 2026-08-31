import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/money/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/recurring_expense.dart';
import '../../controller/expense_controller.dart';

/// Modal bottom sheet allowing shop owners to configure and manage
/// recurring monthly expenses (e.g. Shop Rent, Electricity Bill, Staff Salary, WiFi).
class RecurringExpensesSheet extends StatelessWidget {
  const RecurringExpensesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecurringExpensesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.repeat_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'মাসিক নিয়মিত খরচসমূহ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'প্রতি মাসের নির্দিষ্ট খরচ যেমন দোকান ভাড়া, বিদ্যুৎ বিল',
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

          // Recurring Items List
          Expanded(
            child: Obx(() {
              final items = controller.recurringExpenses;

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'কোনো নিয়মিত খরচ যোগ করা হয়নি',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'দোকান ভাড়া, বিদ্যুৎ বা ইন্টারনেট বিল প্রতি মাসের খরচে নিয়মিত রাখতে নিচে যোগ করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isRecorded =
                      controller.isRecurringRecordedThisMonth(item);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isRecorded
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            item.category == ExpenseCategory.monthlyRent
                                ? Icons.home_work_outlined
                                : Icons.receipt_long_outlined,
                            color: isRecorded
                                ? Colors.green
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.amount.format(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isRecorded
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isRecorded
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.orange
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isRecorded
                                            ? '✓ এই মাসে পরিশোধিত'
                                            : '⚠️ এই মাসে এখনো বাকি',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isRecorded
                                              ? Colors.green.shade800
                                              : Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isRecorded)
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(60, 32),
                              ),
                              onPressed: () async {
                                final ok = await controller
                                    .recordRecurringExpense(item);
                                if (ok && context.mounted) {
                                  Get.snackbar(
                                    'পরিশোধ সফল',
                                    '${item.title} খরচ হিসেবে রেকর্ড করা হয়েছে।',
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                              child: const Text(
                                'পরিশোধ',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () =>
                                controller.deleteRecurringExpense(item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Add Template Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('নতুন নিয়মিত খরচ টেমপ্লেট যোগ করুন'),
              onPressed: () {
                _showAddTemplateDialog(context, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddTemplateDialog(
    BuildContext context,
    ExpenseController controller,
  ) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var category = ExpenseCategory.dailyOther;
    var paymentMethod = PaymentMethod.cash;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('নিয়মিত মাসিক খরচ যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ExpenseCategory>(
                  segments: const [
                    ButtonSegment(
                      value: ExpenseCategory.monthlyRent,
                      label: Text('দোকান ভাড়া'),
                    ),
                    ButtonSegment(
                      value: ExpenseCategory.dailyOther,
                      label: Text('অন্যান্য বিল'),
                    ),
                  ],
                  selected: {category},
                  onSelectionChanged: (s) => setState(() => category = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'খরচের নাম',
                    hintText: 'যেমন: বিদ্যুৎ বিল, দোকান ভাড়া, ইন্টারনেট',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'টাকার পরিমাণ (৳)',
                    hintText: 'যেমন: ১৫০০',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<PaymentMethod>(
                  segments: const [
                    ButtonSegment(
                      value: PaymentMethod.cash,
                      label: Text('ক্যাশ'),
                    ),
                    ButtonSegment(
                      value: PaymentMethod.mobileBanking,
                      label: Text('মোবাইল'),
                    ),
                    ButtonSegment(
                      value: PaymentMethod.bankTransfer,
                      label: Text('ব্যাংক'),
                    ),
                  ],
                  selected: {paymentMethod},
                  onSelectionChanged: (s) =>
                      setState(() => paymentMethod = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final rawAmount = amountCtrl.text.trim();
                if (title.isEmpty || rawAmount.isEmpty) return;

                final amount = Money.parse(rawAmount);
                controller.saveRecurringExpense(
                  RecurringExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    category: category,
                    amount: amount,
                    paymentMethod: paymentMethod,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
