import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import 'customer_detail_sheet.dart';
import 'customer_form_sheet.dart';

/// The Customers screen — organized, clean, and professional view for
/// managing customer relationships, flags, contact, and dues.
class CustomersScreen extends GetView<CustomersController> {
  final VoidCallback? onMenuTap;

  const CustomersScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'customers'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Column(
        children: [
          // ── Search & Filter Section ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                Obx(() {
                  final query = controller.searchQuery.value;
                  return TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '${'search'.tr}...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'clearSearch'.tr,
                              onPressed: () {
                                searchController.clear();
                                controller.searchQuery.value = '';
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onChanged: (v) => controller.searchQuery.value = v,
                  );
                }),
                const SizedBox(height: AppSpacing.sm),

                // Quick Filter Chips Bar
                Obx(() {
                  final total = controller.totalCustomersCount;
                  final buyers = controller.buyersCount;
                  final withDues = controller.withDuesCustomersCount;
                  final withOrders = controller.withOrdersCustomersCount;
                  final isBuyersSelected = controller.showBuyersOnly.value;
                  final isDuesSelected = controller.showWithDuesOnly.value;
                  final isOrdersSelected = controller.showWithOrdersOnly.value;
                  final isAllSelected =
                      !isBuyersSelected && !isDuesSelected && !isOrdersSelected;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: isAllSelected,
                          label: Text('${'allCustomers'.tr} ($total)'),
                          showCheckmark: false,
                          onSelected: (_) {
                            controller.showBuyersOnly.value = false;
                            controller.showWithDuesOnly.value = false;
                            controller.showWithOrdersOnly.value = false;
                          },
                        ),
                        if (buyers > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilterChip(
                            selected: isBuyersSelected,
                            avatar: Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: isBuyersSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : Colors.blue.shade700,
                            ),
                            label: Text('${'buyersTab'.tr} ($buyers)'),
                            showCheckmark: false,
                            onSelected: (v) {
                              controller.showBuyersOnly.value = v;
                              if (v) {
                                controller.showWithDuesOnly.value = false;
                                controller.showWithOrdersOnly.value = false;
                              }
                            },
                          ),
                        ],
                        if (withDues > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilterChip(
                            selected: isDuesSelected,
                            avatar: Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                              color: isDuesSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.error,
                            ),
                            label: Text('${'withDues'.tr} ($withDues)'),
                            showCheckmark: false,
                            onSelected: (v) {
                              controller.showWithDuesOnly.value = v;
                              if (v) {
                                controller.showBuyersOnly.value = false;
                                controller.showWithOrdersOnly.value = false;
                              }
                            },
                          ),
                        ],
                        if (withOrders > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilterChip(
                            selected: isOrdersSelected,
                            avatar: Icon(
                              Icons.assignment_outlined,
                              size: 16,
                              color: isOrdersSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : Colors.purple.shade700,
                            ),
                            label: Text('${'ordersTab'.tr} ($withOrders)'),
                            showCheckmark: false,
                            onSelected: (v) {
                              controller.showWithOrdersOnly.value = v;
                              if (v) {
                                controller.showBuyersOnly.value = false;
                                controller.showWithDuesOnly.value = false;
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Customer List Section ───────────────────────────────────────
          Expanded(
            child: Obx(() {
              final items = controller.visibleCustomers;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'noCustomers'.tr
                              : 'noCustomersYet'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (controller.customers.isEmpty)
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text('addCustomer'.tr),
                            onPressed: () => _openForm(context),
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
                  final customer = items[index];
                  return _CustomerCard(
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
          onDelete: existing == null
              ? null
              : () async {
                  await controller.deleteCustomer(existing.id);
                  Get.snackbar(
                    'customerDeleted'.tr,
                    existing.name,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
        );
      },
    );
    if (result == null) return;

    if (existing == null) {
      await controller.createCustomer(
        name: result.name,
        address: result.address,
        contact: result.contact,
        photoLocalPath: result.photoLocalPath,
      );
    } else {
      await controller.updateCustomer(
        existing,
        name: result.name,
        address: result.address,
        contact: result.contact,
        photoLocalPath: result.photoLocalPath,
      );
    }
  }

  void _openDetails(BuildContext context, Customer customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

/// A compact, readable card representing a single customer with badges,
/// contact details, quick call action, and delete confirmation.
class _CustomerCard extends GetView<CustomersController> {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
  });

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueMinorUnits = controller.outstandingDueFor(customer.id);
    final hasDue = dueMinorUnits > 0;
    final totalPurchased = controller.totalPurchasedFor(customer.id);
    final hasPurchased = totalPurchased.isPositive;
    final activeRentCount = controller.activeRentalsCountFor(customer.id);
    final ordersCount = controller.ordersCountFor(customer.id);

    return Dismissible(
      key: ValueKey(customer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => controller.deleteCustomer(customer.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Avatar ───────────────────────────────────────
                _customerAvatar(context),
                const SizedBox(width: AppSpacing.md),

                // ── Customer Info ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Status Badges
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        children: [
                          Text(
                            customer.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hasPurchased)
                            _badge(
                              context,
                              '${totalPurchased.format()} ${'purchasedLabel'.tr}',
                              color: Colors.blue.shade50,
                              textColor: Colors.blue.shade800,
                            ),
                          if (hasDue)
                            _badge(
                              context,
                              '${Money.fromMinor(dueMinorUnits).format()} ${'dueLabel'.tr}',
                              color: theme.colorScheme.error.withValues(alpha: 0.1),
                              textColor: theme.colorScheme.error,
                            ),
                          if (activeRentCount > 0)
                            _badge(
                              context,
                              '$activeRentCount ${'customerRentCount'.tr}',
                              color: theme.colorScheme.tertiaryContainer,
                              textColor: theme.colorScheme.onTertiaryContainer,
                            ),
                          if (ordersCount > 0)
                            _badge(
                              context,
                              '$ordersCount ${'customerOrderCount'.tr}',
                              color: Colors.purple.shade50,
                              textColor: Colors.purple.shade800,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Phone Number
                      if (customer.contact != null && customer.contact!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.contact!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Address
                      if (customer.address != null && customer.address!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.address!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // ── Quick Action Buttons ──────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customer.contact != null &&
                        customer.contact!.trim().isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.call_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'callCustomer'.tr,
                        onPressed: () => _makeCall(customer.contact!),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'edit'.tr,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'delete'.tr,
                      onPressed: () async {
                        final confirmed = await _confirmDelete(context);
                        if (confirmed) {
                          await controller.deleteCustomer(customer.id);
                          Get.snackbar(
                            'customerDeleted'.tr,
                            customer.name,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final image = controller.primaryImageFor(customer.id);
    final source = image == null ? null : controller.imageSourceFor(image);

    final initial = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim().characters.first.toUpperCase();
    final fallbackAvatar = CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );

    if (source == null || source.trim().isEmpty) {
      return fallbackAvatar;
    }

    return GestureDetector(
      onTap: () => showFullScreenImageViewer(
        context,
        imagePath: source,
        title: customer.name,
        subtitle: customer.contact,
        heroTag: 'customer_avatar_${customer.id}',
      ),
      child: Hero(
        tag: 'customer_avatar_${customer.id}',
        child: SafeImage(
          source: source,
          width: 44,
          height: 44,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          fallbackWidget: fallbackAvatar,
        ),
      ),
    );
  }

  Widget _badge(
    BuildContext context,
    String text, {
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'delete'.tr} ${customer.name}?'),
        content: Text('deleteCustomerConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
