import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../controller/expense_controller.dart';

/// The v2 Expense screen — record and list monthly-rent/daily-other
/// expenses, per `notes/business_logic.md` §চ section 1, backed by
/// [ExpenseController].
class ExpenseScreen extends GetView<ExpenseController> {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'expenses'.tr} (v2)')),
      body: Obx(() {
        if (controller.expenses.isEmpty) {
          return Center(child: Text('noExpensesYet'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.expenses.length,
          itemBuilder: (context, index) {
            final expense = controller.expenses[index];
            return Dismissible(
              key: ValueKey(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onDismissed: (_) => controller.deleteExpense(expense.id),
              child: ListTile(
                title: Text(_categoryLabel(expense.category)),
                subtitle: Text(
                  expense.description?.isNotEmpty == true
                      ? expense.description!
                      : expense.date.toLocal().toString().split(' ').first,
                ),
                trailing: Text(
                  expense.amount.format(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    ExpenseCategory category = ExpenseCategory.dailyOther;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('addExpense'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        selected: {category},
                        onSelectionChanged: (s) =>
                            setState(() => category = s.first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: amountController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: 'amount'.tr),
                        validator: (v) => _parseMoneyOrNull(v ?? '') == null
                            ? 'invalidQty'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'description'.tr,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                        selected: {method},
                        onSelectionChanged: (s) =>
                            setState(() => method = s.first),
                      ),
                      Obx(
                        () => controller.errorMessage.value == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  controller.errorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = _parseMoneyOrNull(amountController.text)!;
                    final ok = await controller.addExpense(
                      category: category,
                      amount: amount,
                      paymentMethod: method,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _categoryLabel(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.monthlyRent => 'monthlyRent'.tr,
      ExpenseCategory.dailyOther => 'dailyOther'.tr,
    };
  }
}

/// Same pattern as every other v2 form field — `Money` has no `tryParse`,
/// see `daily_sales_v2`'s doc comment for why every live-input field
/// wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
