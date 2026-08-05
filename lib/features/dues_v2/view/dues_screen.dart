import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/services/due_lifecycle.dart';
import '../controller/dues_controller.dart';

/// The Dues screen — outstanding-balance list and paydown, per
/// `notes/business_logic.md` §ছ, backed by [DuesController.payDue] →
/// `PayDueUseCase`. One of the 5 screens `ShellScreen` embeds directly —
/// see `DashboardScreen`'s own doc comment for why [onMenuTap] exists.
class DuesScreen extends GetView<DuesController> {
  final VoidCallback? onMenuTap;

  const DuesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dues'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        final open = controller.outstandingDues;
        if (open.isEmpty) {
          return Center(child: Text('noDuesYet'.tr));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: open.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _DueCard(due: open[index]),
        );
      }),
    );
  }
}

class _DueCard extends GetView<DuesController> {
  final Due due;
  const _DueCard({required this.due});

  @override
  Widget build(BuildContext context) {
    final remaining = controller.remainingOf(due);
    final overdue = controller.dueIsOverdue(due);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.customerName(due.customerId),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (overdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'overdue'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${'dueAmount'.tr}: ${remaining.format()}'
              ' / ${'total'.tr}: ${due.originalAmount.format()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (due.promisedDays != null)
              Text(
                '${'enterDueDay'.tr}: '
                '${promisedByDate(due)!.toLocal().toString().split(' ').first}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _showPayDialog(context, due, remaining),
                child: Text('payNow'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPayDialog(
    BuildContext context,
    Due due,
    Money remaining,
  ) async {
    final amountController = TextEditingController(
      text: remaining.format(showSymbol: false),
    );
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('payNow'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'cashAmount'.tr),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null
                          ? 'invalidQty'.tr
                          : null,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = _parseMoneyOrNull(
                              amountController.text,
                            )!;
                            final ok = await controller.payDue(
                              dueId: due.id,
                              paymentAmount: amount,
                              paymentMethod: method,
                            );
                            if (ok && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            } else {
                              setState(() {});
                            }
                          },
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('completeSale'.tr),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Same pattern as `daily_sales_v2`'s `_parseMoneyOrNull` — `Money` has no
/// `tryParse`, see that file's doc comment for why every live-input field
/// wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
