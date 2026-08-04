import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import 'customer_form_sheet.dart';

/// The v2 Customers screen — list/create/edit/delete plus the flagged
/// (suspicion/blocked) filter view, backed by
/// [CustomersController]/`CustomerUseCases`. See `CatalogScreen`'s doc
/// comment for why this reads/writes the v2 database only, separate from
/// v1's Customers tab.
class CustomersScreen extends GetView<CustomersController> {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${'customers'.tr} (v2)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: 'search'.tr,
                    isDense: true,
                  ),
                  onChanged: (v) => controller.searchQuery.value = v,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Obx(
                    () => FilterChip(
                      label: Text('showFlaggedOnly'.tr),
                      selected: controller.showFlaggedOnly.value,
                      onSelected: (v) => controller.showFlaggedOnly.value = v,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.visibleCustomers;
              if (items.isEmpty) {
                return Center(child: Text('noCustomersYet'.tr));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final customer = items[index];
                  return _CustomerTile(
                    customer: customer,
                    onTap: () => _openForm(context, existing: customer),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Customer? existing}) async {
    final result = await showModalBottomSheet<CustomerFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomerFormSheet(existing: existing),
    );
    if (result == null) return;

    if (existing == null) {
      await controller.createCustomer(
        name: result.name,
        address: result.address,
        contact: result.contact,
        suspicionFlag: result.suspicionFlag,
        isBlocked: result.isBlocked,
      );
    } else {
      await controller.updateCustomer(
        existing,
        name: result.name,
        address: result.address,
        contact: result.contact,
        suspicionFlag: result.suspicionFlag,
        isBlocked: result.isBlocked,
      );
    }
  }
}

class _CustomerTile extends GetView<CustomersController> {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(customer.id),
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
      onDismissed: (_) => controller.deleteCustomer(customer.id),
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(customer.name)),
            if (customer.isBlocked) ...[
              const SizedBox(width: AppSpacing.xs),
              _badge(context, 'isBlockedLabel'.tr, isError: true),
            ] else if (customer.suspicionFlag) ...[
              const SizedBox(width: AppSpacing.xs),
              _badge(context, 'suspicionFlag'.tr, isError: false),
            ],
          ],
        ),
        subtitle: (customer.contact == null && customer.address == null)
            ? null
            : Text(
                [
                  if (customer.contact != null) customer.contact!,
                  if (customer.address != null) customer.address!,
                ].join(' · '),
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _badge(BuildContext context, String text, {required bool isError}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isError
              ? scheme.onErrorContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr} ${customer.name}?'),
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
}
