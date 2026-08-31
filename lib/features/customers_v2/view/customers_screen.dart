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
/// managing customer relationships, receivables, orders, and contact actions.
class CustomersScreen extends GetView<CustomersController> {
  final VoidCallback? onMenuTap;

  const CustomersScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'customers'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        actions: [
          Obx(() {
            final hasFilter = controller.searchQuery.value.isNotEmpty ||
                controller.showBuyersOnly.value ||
                controller.showWithDuesOnly.value ||
                controller.showWithOrdersOnly.value ||
                controller.showFlaggedOnly.value;
            if (!hasFilter) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              tooltip: 'clearFilter'.tr,
              onPressed: controller.resetFilters,
            );
          }),
        ],
      ),
      body: Obx(() {
        final totalCustomers = controller.customers.length;
        if (totalCustomers == 0) {
          return _buildEmptyState(context);
        }

        final visibleItems = controller.visibleCustomers;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // 1. Top Customer Financial & Overview Cards
            _buildOverviewCards(context),
            const SizedBox(height: AppSpacing.sm),

            // 2. Search Field & Filter Chips
            _buildSearchAndFilters(context),
            const SizedBox(height: AppSpacing.sm),

            // 3. Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'customers'.tr} (${visibleItems.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (controller.searchQuery.value.isNotEmpty ||
                      controller.showBuyersOnly.value ||
                      controller.showWithDuesOnly.value ||
                      controller.showWithOrdersOnly.value ||
                      controller.showFlaggedOnly.value)
                    InkWell(
                      onTap: controller.resetFilters,
                      child: Text(
                        'clearFilter'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 4. Customers List
            if (visibleItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 48,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'noMatchingCustomers'.tr,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton(
                        onPressed: controller.resetFilters,
                        child: Text('allCustomers'.tr),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final customer in visibleItems)
                _ModernCustomerCard(
                  customer: customer,
                  onTap: () => _openDetails(context, customer),
                  onEdit: () => _openForm(context, existing: customer),
                ),

            const SizedBox(height: 80), // FAB bottom padding
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers_fab',
        tooltip: 'addNewCustomer'.tr,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('addCustomer'.tr),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    final theme = Theme.of(context);
    final total = controller.totalCustomersCount;
    final totalDues = controller.totalReceivables;
    final buyers = controller.buyersCount;
    final hasDues = totalDues.minorUnits > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                context,
                label: 'totalCustomers'.tr,
                value: '$total',
                icon: Icons.people_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
              _buildStatItem(
                context,
                label: 'totalReceivablesLabel'.tr,
                value: totalDues.format(),
                icon: Icons.receipt_long_outlined,
                color: hasDues ? Colors.red.shade700 : Colors.green.shade700,
              ),
              Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
              _buildStatItem(
                context,
                label: 'activeBuyers'.tr,
                value: '$buyers',
                icon: Icons.shopping_bag_outlined,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Input
        TextField(
          onChanged: (v) => controller.searchQuery.value = v,
          decoration: InputDecoration(
            hintText: '${'search'.tr}...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'clearSearch'.tr,
                    onPressed: () => controller.searchQuery.value = '',
                  )
                : const SizedBox.shrink()),
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Quick Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() {
            final total = controller.totalCustomersCount;
            final buyers = controller.buyersCount;
            final withDues = controller.withDuesCustomersCount;
            final withOrders = controller.withOrdersCustomersCount;
            final flagged = controller.flaggedCustomersCount;

            final isBuyersSelected = controller.showBuyersOnly.value;
            final isDuesSelected = controller.showWithDuesOnly.value;
            final isOrdersSelected = controller.showWithOrdersOnly.value;
            final isFlaggedSelected = controller.showFlaggedOnly.value;
            final isAllSelected = !isBuyersSelected && !isDuesSelected && !isOrdersSelected && !isFlaggedSelected;

            return Row(
              children: [
                // All Chip
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.people_alt_outlined,
                      size: 13,
                      color: isAllSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text('${'allCustomers'.tr} ($total)'),
                    selected: isAllSelected,
                    showCheckmark: false,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                      color: isAllSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: isAllSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onSelected: (_) {
                      controller.showBuyersOnly.value = false;
                      controller.showWithDuesOnly.value = false;
                      controller.showWithOrdersOnly.value = false;
                      controller.showFlaggedOnly.value = false;
                    },
                  ),
                ),

                // Buyers Chip
                if (buyers > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.shopping_bag_outlined,
                        size: 13,
                        color: isBuyersSelected ? Colors.blue.shade900 : Colors.blue.shade700,
                      ),
                      label: Text('${'buyersTab'.tr} ($buyers)'),
                      selected: isBuyersSelected,
                      showCheckmark: false,
                      selectedColor: Colors.blue.shade100,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isBuyersSelected ? FontWeight.bold : FontWeight.normal,
                        color: isBuyersSelected ? Colors.blue.shade900 : Colors.blue.shade700,
                      ),
                      side: BorderSide(
                        color: isBuyersSelected ? Colors.blue.shade600 : Colors.blue.shade200,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      onSelected: (v) {
                        controller.showBuyersOnly.value = v;
                        if (v) {
                          controller.showWithDuesOnly.value = false;
                          controller.showWithOrdersOnly.value = false;
                          controller.showFlaggedOnly.value = false;
                        }
                      },
                    ),
                  ),

                // Dues Chip
                if (withDues > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.receipt_long_outlined,
                        size: 13,
                        color: isDuesSelected ? Colors.red.shade900 : Colors.red.shade700,
                      ),
                      label: Text('${'withDues'.tr} ($withDues)'),
                      selected: isDuesSelected,
                      showCheckmark: false,
                      selectedColor: Colors.red.shade100,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isDuesSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDuesSelected ? Colors.red.shade900 : Colors.red.shade700,
                      ),
                      side: BorderSide(
                        color: isDuesSelected ? Colors.red.shade600 : Colors.red.shade200,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      onSelected: (v) {
                        controller.showWithDuesOnly.value = v;
                        if (v) {
                          controller.showBuyersOnly.value = false;
                          controller.showWithOrdersOnly.value = false;
                          controller.showFlaggedOnly.value = false;
                        }
                      },
                    ),
                  ),

                // Orders Chip
                if (withOrders > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.assignment_outlined,
                        size: 13,
                        color: isOrdersSelected ? Colors.purple.shade900 : Colors.purple.shade700,
                      ),
                      label: Text('${'ordersTab'.tr} ($withOrders)'),
                      selected: isOrdersSelected,
                      showCheckmark: false,
                      selectedColor: Colors.purple.shade100,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isOrdersSelected ? FontWeight.bold : FontWeight.normal,
                        color: isOrdersSelected ? Colors.purple.shade900 : Colors.purple.shade700,
                      ),
                      side: BorderSide(
                        color: isOrdersSelected ? Colors.purple.shade600 : Colors.purple.shade200,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      onSelected: (v) {
                        controller.showWithOrdersOnly.value = v;
                        if (v) {
                          controller.showBuyersOnly.value = false;
                          controller.showWithDuesOnly.value = false;
                          controller.showFlaggedOnly.value = false;
                        }
                      },
                    ),
                  ),

                // Flagged Chip
                if (flagged > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.flag_outlined,
                        size: 13,
                        color: isFlaggedSelected ? Colors.amber.shade900 : Colors.amber.shade800,
                      ),
                      label: Text('${'flaggedOnly'.tr} ($flagged)'),
                      selected: isFlaggedSelected,
                      showCheckmark: false,
                      selectedColor: Colors.amber.shade100,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isFlaggedSelected ? FontWeight.bold : FontWeight.normal,
                        color: isFlaggedSelected ? Colors.amber.shade900 : Colors.amber.shade800,
                      ),
                      side: BorderSide(
                        color: isFlaggedSelected ? Colors.amber.shade600 : Colors.amber.shade200,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      onSelected: (v) {
                        controller.showFlaggedOnly.value = v;
                        if (v) {
                          controller.showBuyersOnly.value = false;
                          controller.showWithDuesOnly.value = false;
                          controller.showWithOrdersOnly.value = false;
                        }
                      },
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'noCustomersYet'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text('addCustomer'.tr),
              onPressed: () => _openForm(context),
            ),
          ],
        ),
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

/// A clean, professional, organized customer card with sleek contact & transaction badges.
class _ModernCustomerCard extends GetView<CustomersController> {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ModernCustomerCard({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueMinorUnits = controller.outstandingDueFor(customer.id);
    final hasDue = dueMinorUnits > 0;
    final totalPurchased = controller.totalPurchasedFor(customer.id);
    final hasPurchased = totalPurchased.isPositive;
    final activeRentCount = controller.activeRentalsCountFor(customer.id);
    final ordersCount = controller.ordersCountFor(customer.id);
    final hasPhone = customer.contact != null && customer.contact!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasDue
              ? Colors.red.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Customer Avatar ─────────────────────────────────────────
              _buildAvatar(context),
              const SizedBox(width: AppSpacing.sm),

              // ── Customer Info ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Name & Badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200, width: 0.6),
                            ),
                            child: Text(
                              '${Money.fromMinor(dueMinorUnits).format()} ${'dueLabel'.tr}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          )
                        else if (hasPurchased)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200, width: 0.6),
                            ),
                            child: Text(
                              '${totalPurchased.format()} ${'purchasedLabel'.tr}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Line 2: Contact & Address
                    if (hasPhone || (customer.address != null && customer.address!.isNotEmpty))
                      Row(
                        children: [
                          if (hasPhone) ...[
                            Icon(Icons.phone_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              customer.contact!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (hasPhone && (customer.address != null && customer.address!.isNotEmpty))
                            Text(
                              '  •  ',
                              style: TextStyle(color: theme.colorScheme.outlineVariant),
                            ),
                          if (customer.address != null && customer.address!.isNotEmpty) ...[
                            Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                customer.address!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),

                    // Line 3: Order / Rental / Flags Indicators
                    if (activeRentCount > 0 || ordersCount > 0 || customer.suspicionFlag || customer.isBlocked) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (ordersCount > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$ordersCount ${'customerOrderCount'.tr}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ),
                          if (activeRentCount > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$activeRentCount ${'customerRentCount'.tr}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          if (customer.suspicionFlag || customer.isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade300, width: 0.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_rounded, size: 10, color: Colors.amber.shade900),
                                  const SizedBox(width: 2),
                                  Text(
                                    customer.isBlocked ? 'isBlockedLabel'.tr : 'suspicionFlag'.tr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Right Action Hub ────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPhone)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _makeCall(customer.contact!),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: theme.colorScheme.outline),
                    padding: EdgeInsets.zero,
                    onSelected: (val) async {
                      if (val == 'details') onTap();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') {
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
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('customerProfile'.tr),
                          ],
                        ),
                      ),
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
                            const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text('delete'.tr, style: const TextStyle(color: Colors.red)),
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

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final image = controller.primaryImageFor(customer.id);
    final imageSource = image == null ? null : controller.imageSourceFor(image);

    if (imageSource != null) {
      return GestureDetector(
        onTap: () => showFullScreenImageViewer(
          context,
          imagePath: imageSource,
          title: customer.name,
          subtitle: customer.contact ?? '',
          heroTag: 'customer_card_image_${customer.id}',
        ),
        child: Hero(
          tag: 'customer_card_image_${customer.id}',
          child: SafeImage(
            source: imageSource,
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(10),
            fallbackIcon: Icons.person_outline,
          ),
        ),
      );
    }

    final initial = customer.name.isNotEmpty
        ? customer.name.characters.first.toUpperCase()
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
