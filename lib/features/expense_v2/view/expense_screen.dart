import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/expense.dart';
import '../controller/expense_controller.dart';
import 'widgets/recurring_expenses_sheet.dart';

/// The upgraded Expense screen — record, list, edit, and delete
/// monthly-rent and daily-other expenses with instant financial totals,
/// recurring monthly expense templates & 1-tap payment, and cloud sync.
class ExpenseScreen extends GetView<ExpenseController> {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'expenses'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_rounded),
            tooltip: 'নিয়মিত খরচসমূহ',
            onPressed: () => RecurringExpensesSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final pendingRecurring = controller.pendingRecurringThisMonth;
        final total = controller.totalExpenses;
        final count = controller.expenses.length;

        if (controller.expenses.isEmpty && pendingRecurring.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'noExpensesYet'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => _showFormSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text('addExpense'.tr),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Monthly Recurring Pending Banner ────────────────────────
            if (pendingRecurring.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_repeat_rounded,
                            size: 18, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'এই মাসের বকেয়া নিয়মিত খরচ (${pendingRecurring.length}টি)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => RecurringExpensesSheet.show(context),
                          child: Text(
                            'সব দেখুন',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: pendingRecurring.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${item.title}: ${item.amount.format()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
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
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'পরিশোধ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 2. Top Total Expenses Summary Card ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade700,
                    Colors.teal.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'মোট খরচ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total.format(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$countটি এন্ট্রি',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3. Expenses List ───────────────────────────────────────────
            for (final expense in controller.expenses)
              _ExpenseCard(
                expense: expense,
                onEdit: () => _showFormSheet(context, existing: expense),
                onDelete: () => _confirmDelete(context, expense),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: () => _showFormSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormSheet(BuildContext context, {Expense? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseFormSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final title = expense.description?.isNotEmpty == true
        ? expense.description!
        : (expense.category == ExpenseCategory.monthlyRent
            ? 'monthlyRent'.tr
            : 'dailyOther'.tr);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteExpense'.tr),
        content: Text('deleteExpenseConfirm'.trParams({'title': title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      await controller.deleteExpense(expense.id);
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRent = expense.category == ExpenseCategory.monthlyRent;
    final hasDescription = expense.description != null &&
        expense.description!.trim().isNotEmpty;
    final dateStr = DateFormat('dd MMM, yyyy').format(expense.date);

    final headline = isRent
        ? 'monthlyRent'.tr
        : (hasDescription ? expense.description!.trim() : 'dailyOther'.tr);

    final subtext = isRent
        ? (hasDescription ? expense.description!.trim() : null)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRent
                      ? Colors.indigo.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRent
                      ? Icons.home_work_outlined
                      : Icons.receipt_long_outlined,
                  color: isRent ? Colors.indigo : Colors.orange.shade800,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title, Custom Name & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (subtext != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtext,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (!isRent && hasDescription)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'অন্যান্য খরচ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _paymentMethodLabel(expense.paymentMethod),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.amount.format(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('edit'.tr),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'delete'.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentMethodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'cash'.tr,
      PaymentMethod.mobileBanking => 'mobile'.tr,
      PaymentMethod.bankTransfer => 'bank'.tr,
    };
  }
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final Expense? existing;

  const _ExpenseFormSheet({this.existing});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late ExpenseCategory _category;
  late PaymentMethod _method;
  bool _isRecurring = false;

  static const _commonExpenseSuggestions = [
    'বিদ্যুৎ বিল',
    'চা-নাস্তা',
    'যাতায়াত',
    'প্যাকেজিং',
    'দোকান মেরামত',
    'বেতন / মজুরি',
    'ইন্টারনেট বিল',
    'পরিষ্কার-পরিচ্ছন্নতা',
  ];

  ExpenseController get controller => Get.find<ExpenseController>();

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _amountController = TextEditingController(
      text: ex != null
          ? (ex.amount.minorUnits / 100).toStringAsFixed(
              ex.amount.minorUnits % 100 == 0 ? 0 : 2,
            )
          : '',
    );
    _descriptionController = TextEditingController(text: ex?.description ?? '');
    _category = ex?.category ?? ExpenseCategory.dailyOther;
    _method = ex?.paymentMethod ?? PaymentMethod.cash;

    final title = ex?.description?.trim().toLowerCase() ?? '';
    final isMatchingRecurring = ex != null &&
        (ex.category == ExpenseCategory.monthlyRent ||
            controller.recurringExpenses.any(
              (r) => r.title.trim().toLowerCase() == title,
            ));
    _isRecurring = isMatchingRecurring;

    _descriptionController.addListener(() {
      final text = _descriptionController.text.trim().toLowerCase();
      if (text.isNotEmpty) {
        final matches = controller.recurringExpenses.any(
          (r) => r.title.trim().toLowerCase() == text,
        );
        if (matches && !_isRecurring && mounted) {
          setState(() => _isRecurring = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseMoneyOrNull(_amountController.text);
    if (amount == null || amount <= Money.zeroBdt) {
      Get.snackbar(
        'সঠিক পরিমাণ দিন',
        'খরচের টাকার পরিমাণ শূন্যের বেশি হতে হবে।',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    bool ok = false;
    if (widget.existing == null) {
      ok = await controller.addExpense(
        category: _category,
        amount: amount,
        paymentMethod: _method,
        description: description,
        isRecurring: _isRecurring,
      );
    } else {
      ok = await controller.updateExpense(
        id: widget.existing!.id,
        category: _category,
        amount: amount,
        paymentMethod: _method,
        date: widget.existing!.date,
        description: description,
        isRecurring: _isRecurring,
      );
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;
    final isOther = _category == ExpenseCategory.dailyOther;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'editExpense'.tr : 'addExpense'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Category Toggle ─────────────────────────────────────────
                  SegmentedButton<ExpenseCategory>(
                    segments: [
                      ButtonSegment(
                        value: ExpenseCategory.monthlyRent,
                        label: Text('monthlyRent'.tr),
                      ),
                      ButtonSegment(
                        value: ExpenseCategory.dailyOther,
                        label: Text('dailyOther'.tr),
                      ),
                    ],
                    selected: {_category},
                    onSelectionChanged: (s) {
                      setState(() {
                        _category = s.first;
                        if (_category == ExpenseCategory.monthlyRent) {
                          _isRecurring = true;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Direct Amount TextFormField ─────────────────────────────
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: !isEditing,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'টাকার পরিমাণ *',
                      hintText: '0.00',
                      prefixText: '৳ ',
                      prefixStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'টাকার পরিমাণ লিখুন';
                      }
                      final parsed = _parseMoneyOrNull(val);
                      if (parsed == null || parsed <= Money.zeroBdt) {
                        return 'সঠিক টাকার পরিমাণ দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Custom Expense Name / Description ───────────────────────
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: isOther
                          ? 'খরচের নাম / উদ্দেশ্য'
                          : 'বিবরণ / নোট (ঐচ্ছিক)',
                      hintText: isOther
                          ? 'যেমন: বিদ্যুৎ বিল, চা-নাস্তা, যাতায়াত'
                          : 'যেমন: আগস্ট মাসের দোকান ভাড়া',
                      prefixIcon: Icon(
                        isOther ? Icons.edit_note_rounded : Icons.notes_rounded,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // ── Quick Suggestion Chips for Other Expenses ───────────────
                  if (isOther) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _commonExpenseSuggestions.map((suggestion) {
                          final isSelected =
                              _descriptionController.text == suggestion;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              backgroundColor: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              side: BorderSide.none,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                setState(() {
                                  _descriptionController.text = suggestion;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // ── Monthly Recurring Toggle ────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: _isRecurring
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isRecurring
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      dense: true,
                      secondary: Icon(
                        Icons.repeat_rounded,
                        color: _isRecurring
                            ? theme.colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                      title: const Text(
                        'প্রতি মাসে নিয়মিত পুনরাবৃত্তি করুন',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'প্রতি মাসের শুরুতে বকেয়া হিসেবে মনে করিয়ে দেবে এবং ১-ট্যাপে পরিশোধের সুযোগ পাবেন',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isRecurring,
                      onChanged: (val) {
                        setState(() => _isRecurring = val);
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Payment Method Toggle ───────────────────────────────────
                  SegmentedButton<PaymentMethod>(
                    segments: [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        label: Text('cash'.tr),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.mobileBanking,
                        label: Text('mobile'.tr),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.bankTransfer,
                        label: Text('bank'.tr),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: (s) {
                      setState(() => _method = s.first);
                    },
                  ),
                  Obx(
                    () => controller.errorMessage.value == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              controller.errorMessage.value!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Submit Button ───────────────────────────────────────────
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      isEditing ? 'save'.tr : 'addExpense'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
