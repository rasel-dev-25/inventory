import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/safe_image.dart';
import '../controller/recycle_bin_controller.dart';

/// The modern v2 Recycle Bin screen — supporting safe 2-step deletion:
/// viewing, searching, filtering, restoring, and permanently deleting records
/// and associated photos.
class RecycleBinScreen extends GetView<RecycleBinController> {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('recycleBinTitle'.tr),
        actions: [
          Obx(() {
            if (controller.totalDeletedCount == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'emptyRecycleBinNow'.tr,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmEmptyBin(context),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final totalCount = controller.totalDeletedCount;
        final selectedCat = controller.selectedCategory.value;

        final customers = controller.filteredCustomers;
        final orders = controller.filteredOrders;
        final expenses = controller.filteredExpenses;
        final products = controller.filteredProducts;
        final fixedAssets = controller.filteredFixedAssets;
        final purchaseTrips = controller.filteredPurchaseTrips;

        return Column(
          children: [
            // ── 1. Top Summary Banner & Empty Bin Action ────────────────────
            if (totalCount > 0)
              _buildTopSummaryBanner(context, totalCount),

            // ── 2. Live Search Bar ──────────────────────────────────────────
            if (totalCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                child: TextField(
                  onChanged: (val) => controller.searchQuery.value = val,
                  decoration: InputDecoration(
                    hintText: 'searchRecycleBinHint'.tr,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => controller.searchQuery.value = '',
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),

            // ── 3. Category Filter Tabs Carousel ────────────────────────────
            if (totalCount > 0)
              _buildCategoryFilterCarousel(context),

            // ── 4. Main Item List / Empty State ─────────────────────────────
            Expanded(
              child: totalCount == 0
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        // Customers
                        if ((selectedCat == 'all' || selectedCat == 'customers') &&
                            customers.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedCustomersSectionTitle'.tr,
                            count: customers.length,
                          ),
                          for (final customer in customers)
                            _ModernRecycleBinCard(
                              title: customer.name,
                              subtitle: _deletedOnLabel(customer.deletedAt),
                              detailText: customer.contact,
                              photoUrl: controller.customerThumbnails[customer.id],
                              defaultIcon: Icons.person_outline_rounded,
                              iconColor: Colors.teal.shade700,
                              onRestore: () => _handleRestoreCustomer(customer.id),
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: customer.name,
                                onDelete: () => controller.permanentDeleteCustomer(customer.id),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Products
                        if ((selectedCat == 'all' || selectedCat == 'products') &&
                            products.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedProductsSectionTitle'.tr,
                            count: products.length,
                          ),
                          for (final product in products)
                            _ModernRecycleBinCard(
                              title: product.name,
                              subtitle: _deletedOnLabel(product.deletedAt),
                              detailText: product.category.isNotEmpty ? '${'category'.tr}: ${product.category}' : null,
                              photoUrl: controller.productThumbnails[product.id],
                              defaultIcon: Icons.inventory_2_outlined,
                              iconColor: Colors.blue.shade700,
                              onRestore: () => _handleRestoreProduct(product.id),
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: product.name,
                                onDelete: () => controller.permanentDeleteProduct(product.id),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Orders
                        if ((selectedCat == 'all' || selectedCat == 'orders') &&
                            orders.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedOrdersSectionTitle'.tr,
                            count: orders.length,
                          ),
                          for (final order in orders)
                            _ModernRecycleBinCard(
                              title: order.itemDescription,
                              subtitle: _deletedOnLabel(order.deletedAt),
                              defaultIcon: Icons.assignment_outlined,
                              iconColor: Colors.purple.shade700,
                              onRestore: () => _handleRestoreOrder(order.id),
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: order.itemDescription,
                                onDelete: () => controller.permanentDeleteOrder(order.id),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Expenses
                        if ((selectedCat == 'all' || selectedCat == 'expenses') &&
                            expenses.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedExpensesSectionTitle'.tr,
                            count: expenses.length,
                          ),
                          for (final expense in expenses)
                            _ModernRecycleBinCard(
                              title: Money.fromMinor(expense.amountMinor).format(),
                              subtitle: _deletedOnLabel(expense.deletedAt),
                              detailText: expense.description,
                              defaultIcon: Icons.money_off_outlined,
                              iconColor: Colors.red.shade700,
                              trailingNote: 'cannotRestoreExpenseNote'.tr,
                              onRestore: null,
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: Money.fromMinor(expense.amountMinor).format(),
                                onDelete: () => controller.permanentDeleteExpense(expense.id),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Fixed Assets
                        if ((selectedCat == 'all' || selectedCat == 'fixed_assets') &&
                            fixedAssets.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedFixedAssetsSectionTitle'.tr,
                            count: fixedAssets.length,
                          ),
                          for (final asset in fixedAssets)
                            _ModernRecycleBinCard(
                              title: asset.name,
                              subtitle: _deletedOnLabel(asset.deletedAt),
                              detailText: '${'value'.tr}: ${Money.fromMinor(asset.valueMinor).format()}',
                              photoUrl: controller.assetThumbnails[asset.id],
                              defaultIcon: Icons.apartment_rounded,
                              iconColor: Colors.deepOrange.shade700,
                              trailingNote: 'cannotRestoreNote'.tr,
                              onRestore: null,
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: asset.name,
                                onDelete: () => controller.permanentDeleteFixedAsset(asset.id),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Purchase Trips
                        if ((selectedCat == 'all' || selectedCat == 'purchases') &&
                            purchaseTrips.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            title: 'deletedPurchaseTripsSectionTitle'.tr,
                            count: purchaseTrips.length,
                          ),
                          for (final trip in purchaseTrips)
                            _ModernRecycleBinCard(
                              title: DateFormat.yMMMd().format(trip.date.toLocal()),
                              subtitle: _deletedOnLabel(trip.deletedAt),
                              defaultIcon: Icons.local_shipping_outlined,
                              iconColor: Colors.blueGrey.shade700,
                              trailingNote: 'cannotRestoreNote'.tr,
                              onRestore: null,
                              onPermanentDelete: () => _confirmPermanentDelete(
                                context,
                                itemName: DateFormat.yMMMd().format(trip.date.toLocal()),
                                onDelete: () => controller.permanentDeletePurchaseTrip(trip.id),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      }),
    );
  }

  // ── Top Summary Banner ────────────────────────────────────────────────────
  Widget _buildTopSummaryBanner(BuildContext context, int totalCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.amber.shade200, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.amber.shade900),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount ${'itemsInRecycleBin'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'প্রয়োজনে রিস্টোর করুন অথবা চিরতরে মুছে ফেলুন',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.amber.shade300, width: 0.8),
              ),
            ),
            onPressed: () => _confirmEmptyBin(context),
            child: Text(
              'emptyRecycleBinNow'.tr,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Filter Tabs Carousel ─────────────────────────────────────────
  Widget _buildCategoryFilterCarousel(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip(context, id: 'all', label: 'allCategories'.tr, count: controller.totalDeletedCount),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'customers', label: 'customers'.tr, count: controller.deletedCustomers.length),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'products', label: 'stock'.tr, count: controller.deletedProducts.length),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'orders', label: 'orders'.tr, count: controller.deletedOrders.length),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'expenses', label: 'expenses'.tr, count: controller.deletedExpenses.length),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'fixed_assets', label: 'fixedAssets'.tr, count: controller.deletedFixedAssets.length),
          const SizedBox(width: 6),
          _buildFilterChip(context, id: 'purchases', label: 'purchaseEntry'.tr, count: controller.deletedPurchaseTrips.length),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String id,
    required String label,
    required int count,
  }) {
    final theme = Theme.of(context);
    final isSelected = controller.selectedCategory.value == id;

    return InkWell(
      onTap: () => controller.selectedCategory.value = id,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.25)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 0.8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 40,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'noDeletedItems'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'noDeletedItemsSubtitle'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _deletedOnLabel(DateTime? deletedAt) {
    if (deletedAt == null) return '';
    final d = deletedAt.toLocal();
    return '${'deletedOnLabel'.tr}${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ── Handlers & Confirmation Dialogs ───────────────────────────────────────
  Future<void> _handleRestoreCustomer(String id) async {
    final success = await controller.restoreCustomer(id);
    if (success) {
      Get.snackbar(
        'recycleBinTitle'.tr,
        'itemRestoredSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _handleRestoreProduct(String id) async {
    final success = await controller.restoreProduct(id);
    if (success) {
      Get.snackbar(
        'recycleBinTitle'.tr,
        'itemRestoredSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _handleRestoreOrder(String id) async {
    final success = await controller.restoreOrder(id);
    if (success) {
      Get.snackbar(
        'recycleBinTitle'.tr,
        'itemRestoredSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context, {
    required String itemName,
    required Future<bool> Function() onDelete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            Text('permanentDeleteConfirmTitle'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“$itemName”',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('permanentDeleteConfirmMessage'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('permanentDeleteAction'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await onDelete();
      if (ok) {
        Get.snackbar(
          'recycleBinTitle'.tr,
          'itemDeletedPermanently'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else if (controller.errorMessage.value != null) {
        Get.snackbar(
          'সতর্কতা',
          controller.errorMessage.value!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade100,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _confirmEmptyBin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text('emptyRecycleBinConfirmTitle'.tr),
          ],
        ),
        content: Text('emptyRecycleBinConfirmMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('emptyRecycleBinNow'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.pruneNow();
      Get.snackbar(
        'recycleBinTitle'.tr,
        'রিসাইকেল বিন খালি করা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

/// Modern clean recycle bin tile with photo preview and dual actions
class _ModernRecycleBinCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detailText;
  final String? photoUrl;
  final IconData defaultIcon;
  final Color iconColor;
  final String? trailingNote;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;

  const _ModernRecycleBinCard({
    required this.title,
    required this.subtitle,
    required this.defaultIcon,
    required this.iconColor,
    this.detailText,
    this.photoUrl,
    this.trailingNote,
    this.onRestore,
    this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // ── Photo Thumbnail or Icon Badge ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? SafeImage(
                        source: photoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        fallbackWidget: Container(
                          color: iconColor.withValues(alpha: 0.1),
                          child: Icon(defaultIcon, color: iconColor, size: 20),
                        ),
                      )
                    : Container(
                        color: iconColor.withValues(alpha: 0.1),
                        child: Icon(defaultIcon, color: iconColor, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Title & Subtitles ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (detailText != null && detailText!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detailText!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (trailingNote != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      trailingNote!,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),

            // ── Actions: Restore & Permanent Delete ─────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRestore != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: Colors.green.shade600, width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: Icon(Icons.restore_rounded, size: 14, color: Colors.green.shade800),
                    label: Text(
                      'restoreAction'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    onPressed: onRestore,
                  ),
                if (onPermanentDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'permanentDeleteAction'.tr,
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: onPermanentDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
