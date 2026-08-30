import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import 'customer_detail_sheet.dart';
import 'customer_form_sheet.dart';

/// The Customers screen — list/create/edit/delete plus the flagged
/// (suspicion/blocked) filter view, backed by
/// [CustomersController]/`CustomerUseCases`. One of the 5 screens
/// `ShellScreen` embeds directly — see `DashboardScreen`'s own doc
/// comment for why [onMenuTap] exists.
class CustomersScreen extends GetView<CustomersController> {
  final VoidCallback? onMenuTap;

  const CustomersScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'customers'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
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
                    onTap: () => _openDetails(context, customer),
                    onEdit: () => _openForm(context, existing: customer),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customers_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Customer? existing}) async {
    final result = await showModalBottomSheet<CustomerFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final image = existing == null
            ? null
            : controller.primaryImageFor(existing.id);
        return CustomerFormSheet(
          existing: existing,
          onCapturePhoto: controller.captureCustomerPhoto,
          existingPhotoSource: image == null
              ? null
              : controller.imageSourceFor(image),
        );
      },
    );
    if (result == null) return;

    if (existing == null) {
      await controller.createCustomer(
        name: result.name,
        address: result.address,
        contact: result.contact,
        suspicionFlag: result.suspicionFlag,
        isBlocked: result.isBlocked,
        photoLocalPath: result.photoLocalPath,
      );
    } else {
      await controller.updateCustomer(
        existing,
        name: result.name,
        address: result.address,
        contact: result.contact,
        suspicionFlag: result.suspicionFlag,
        isBlocked: result.isBlocked,
        photoLocalPath: result.photoLocalPath,
      );
    }
  }

  Future<void> _openDetails(BuildContext context, Customer customer) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerDetailSheet(
        customer: customer,
        onEdit: () {
          Navigator.of(context).pop();
          _openForm(context, existing: customer);
        },
      ),
    );
  }
}

class _CustomerTile extends GetView<CustomersController> {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _CustomerTile({
    required this.customer,
    required this.onTap,
    required this.onEdit,
  });

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
        leading: _customerAvatar(context),
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
        trailing: IconButton(
          tooltip: 'edit'.tr,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }

  Widget _customerAvatar(BuildContext context) {
    final image = controller.primaryImageFor(customer.id);
    final source = image == null ? null : controller.imageSourceFor(image);
    if (source == null) {
      return CircleAvatar(
        child: Text(
          customer.name.trim().isEmpty
              ? '?'
              : customer.name.trim().characters.first.toUpperCase(),
        ),
      );
    }
    return ClipOval(
      child: source.startsWith('http')
          ? Image.network(source, width: 44, height: 44, fit: BoxFit.cover)
          : Image.file(File(source), width: 44, height: 44, fit: BoxFit.cover),
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
