import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';
import '../controller/order_controller.dart';

/// The v2 Order screen — customer pre-orders, per
/// `notes/business_logic.md` §Order, backed by [OrderController].
class OrderScreen extends GetView<OrderController> {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'orders'.tr} (v2)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip(context, null, 'all'.tr),
                    const SizedBox(width: AppSpacing.sm),
                    _statusChip(context, OrderStatus.pending, 'pending'.tr),
                    const SizedBox(width: AppSpacing.sm),
                    _statusChip(context, OrderStatus.fulfilled, 'fulfilled'.tr),
                    const SizedBox(width: AppSpacing.sm),
                    _statusChip(context, OrderStatus.cancelled, 'cancelled'.tr),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.visibleOrders;
              if (items.isEmpty) {
                return Center(child: Text('noOrdersYet'.tr));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _OrderCard(order: items[index]),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statusChip(BuildContext context, OrderStatus? status, String label) {
    final selected = controller.selectedStatus.value == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.selectedStatus.value = status,
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    String? customerId;
    final descriptionController = TextEditingController();
    final neededByController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('addOrder'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: customerId,
                          decoration: InputDecoration(
                            labelText: 'customerName'.tr,
                          ),
                          items: [
                            for (final c in controller.customers)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => customerId = v),
                          validator: (v) =>
                              v == null ? 'nameRequired'.tr : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'itemDescription'.tr,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'nameRequired'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: neededByController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${'dateNeeded'.tr} (${'days'.tr})',
                        ),
                        validator: (v) => (v != null && v.trim().isNotEmpty)
                            ? (int.tryParse(v) == null ? 'invalidQty'.tr : null)
                            : null,
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
                    final neededInDays = int.tryParse(neededByController.text);
                    final now = DateTime.now();
                    final ok = await controller.createOrder(
                      customerId: customerId!,
                      itemDescription: descriptionController.text,
                      requestedDate: now,
                      neededByDate: neededInDays == null
                          ? null
                          : now.add(Duration(days: neededInDays)),
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
}

class _OrderCard extends GetView<OrderController> {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(order.id),
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
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => controller.deleteOrder(order.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.itemDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _statusBadge(context),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                controller.customerName(order.customerId),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (order.neededByDate != null)
                Text(
                  '${'dateNeeded'.tr}: ${_fmt(order.neededByDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => controller.markCancelled(order.id),
                      child: Text('cancelled'.tr),
                    ),
                    FilledButton(
                      onPressed: () => controller.markFulfilled(order.id),
                      child: Text('fulfilled'.tr),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, onColor) = switch (order.status) {
      OrderStatus.pending => (
        'pending'.tr,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      OrderStatus.fulfilled => (
        'fulfilled'.tr,
        Colors.green.shade100,
        Colors.green.shade900,
      ),
      OrderStatus.cancelled => (
        'cancelled'.tr,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _fmt(DateTime d) => d.toLocal().toString().split(' ').first;
}
