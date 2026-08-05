import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../controller/recycle_bin_controller.dart';

/// The v2 Recycle Bin screen — see `RecycleBinController`'s own doc
/// comment for exactly which entities appear here and why (Customers/
/// Orders restorable, Expenses view-only, everything else out of scope
/// for this change).
class RecycleBinScreen extends GetView<RecycleBinController> {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('recycleBinTitle'.tr),
        actions: [
          IconButton(
            tooltip: 'cleanUpOldItemsNow'.tr,
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => _confirmPrune(context),
          ),
        ],
      ),
      body: Obx(() {
        final customers = controller.deletedCustomers;
        final orders = controller.deletedOrders;
        final expenses = controller.deletedExpenses;

        if (customers.isEmpty && orders.isEmpty && expenses.isEmpty) {
          return Center(child: Text('noDeletedItems'.tr));
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (customers.isNotEmpty) ...[
              Text(
                'deletedCustomersSectionTitle'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final customer in customers)
                _RecycleBinTile(
                  title: customer.name,
                  subtitle: _deletedOnLabel(customer.deletedAt),
                  onRestore: () => controller.restoreCustomer(customer.id),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (orders.isNotEmpty) ...[
              Text(
                'deletedOrdersSectionTitle'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final order in orders)
                _RecycleBinTile(
                  title: order.itemDescription,
                  subtitle: _deletedOnLabel(order.deletedAt),
                  onRestore: () => controller.restoreOrder(order.id),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (expenses.isNotEmpty) ...[
              Text(
                'deletedExpensesSectionTitle'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final expense in expenses)
                _RecycleBinTile(
                  title: Money.fromMinor(expense.amountMinor).format(),
                  subtitle: _deletedOnLabel(expense.deletedAt),
                  trailingNote: 'cannotRestoreExpenseNote'.tr,
                  onRestore: null,
                ),
            ],
          ],
        );
      }),
    );
  }

  String _deletedOnLabel(DateTime? deletedAt) {
    if (deletedAt == null) return '';
    final d = deletedAt.toLocal();
    return '${'deletedOnLabel'.tr}${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmPrune(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('pruneConfirmTitle'.tr),
        content: Text('pruneConfirmMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('cleanUpOldItemsNow'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.pruneNow();
    final result = controller.lastPruneResult.value;
    if (result != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('cleanUpOldItemsNow'.tr),
          content: Text('${'pruneResultMessage'.tr}${result.totalDeleted}'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('ok'.tr),
            ),
          ],
        ),
      );
    }
  }
}

class _RecycleBinTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailingNote;
  final VoidCallback? onRestore;

  const _RecycleBinTile({
    required this.title,
    required this.subtitle,
    this.trailingNote,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          trailingNote == null ? subtitle : '$subtitle · $trailingNote',
        ),
        trailing: onRestore == null
            ? null
            : OutlinedButton(
                onPressed: onRestore,
                child: Text('restoreAction'.tr),
              ),
      ),
    );
  }
}
