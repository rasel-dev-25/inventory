import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/due_lifecycle.dart';
import '../controller/customers_controller.dart';

/// The Customer Detail sheet — complete profile, contact actions, financial metrics,
/// and tabbed history for Rentals, Purchases, Dues, and Pre-Orders.
class CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final CustomersController? controllerOverride;

  const CustomerDetailSheet({
    required this.customer,
    required this.onEdit,
    super.key,
    this.controllerOverride,
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
    final controller = controllerOverride ?? Get.find<CustomersController>();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Obx(() {
          final sales = controller.salesFor(customer.id);
          final dues = controller.duesFor(customer.id);
          final rentals = controller.rentalsFor(customer.id);
          final orders = controller.ordersFor(customer.id);

          final totalSales = sales.fold(
            0,
            (sum, sale) => sum + (sale.actualSellPrice * sale.qty).minorUnits,
          );
          final outstandingDue = dues.fold(
            0,
            (sum, due) =>
                sum + due.originalAmount.minorUnits - due.paidAmount.minorUnits,
          );
          final activeRentals = rentals
              .where((r) =>
                  r.status == RentStatus.active || r.status == RentStatus.overdue)
              .length;

          return DefaultTabController(
            length: 4,
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Column(
                children: [
                  // ── Header Handle & Profile Bar ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        _customerAvatar(context, controller),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      customer.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (customer.contact != null &&
                                  customer.contact!.trim().isNotEmpty)
                                InkWell(
                                  onTap: () => _makeCall(customer.contact!),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          customer.contact!,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (customer.address != null &&
                                  customer.address!.trim().isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        customer.address!,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 12,
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
                        IconButton(
                          tooltip: 'edit'.tr,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          tooltip: 'delete'.tr,
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmDelete(context, controller),
                        ),
                        IconButton(
                          tooltip: 'close'.tr,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── KPI Summary Cards Grid ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'customerRentCount'.tr,
                            value: activeRentals > 0
                                ? '$activeRentals ${'active'.tr}'
                                : '${rentals.length} ${'total'.tr}',
                            icon: Icons.menu_book_outlined,
                            iconColor: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _KpiCard(
                            label: 'customerTotalPurchases'.tr,
                            value: _money(totalSales),
                            icon: Icons.shopping_bag_outlined,
                            iconColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _KpiCard(
                            label: 'customerOutstandingDue'.tr,
                            value: _money(outstandingDue),
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: outstandingDue > 0
                                ? theme.colorScheme.error
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _KpiCard(
                            label: 'customerOrderCount'.tr,
                            value: '${orders.length}',
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Tab Bar ─────────────────────────────────────────────
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      isScrollable: false,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(
                          text: '${'customerRentCount'.tr} (${rentals.length})',
                        ),
                        Tab(
                          text: '${'customerTotalPurchases'.tr} (${sales.length})',
                        ),
                        Tab(
                          text: '${'customerOutstandingDue'.tr} (${dues.length})',
                        ),
                        Tab(
                          text: '${'customerOrderCount'.tr} (${orders.length})',
                        ),
                      ],
                    ),
                  ),

                  // ── Tab Bar Views ───────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Rentals History
                        _buildRentalsTab(context, controller, rentals),

                        // Tab 2: Purchases History
                        _buildPurchasesTab(context, controller, sales),

                        // Tab 3: Dues History
                        _buildDuesTab(context, controller, dues),

                        // Tab 4: Orders History
                        _buildOrdersTab(context, orders),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab 1: Rentals ──────────────────────────────────────────────────────
  Widget _buildRentalsTab(
    BuildContext context,
    CustomersController controller,
    List<RentTransaction> rentals,
  ) {
    final theme = Theme.of(context);
    if (rentals.isEmpty) {
      return _emptyTabState(
        icon: Icons.menu_book_outlined,
        message: 'noCustomerRentals'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rent = rentals[index];
        final product = controller.productFor(rent.bookProductId);
        final bookTitle = product?.name ?? rent.bookProductId;
        final isReturned = rent.status == RentStatus.returned;
        final isOverdue = rent.status == RentStatus.overdue;
        final isStolen = rent.status == RentStatus.treatedAsStolen;

        Color statusBg;
        Color statusFg;
        String statusLabel;

        if (isReturned) {
          statusBg = Colors.green.shade50;
          statusFg = Colors.green.shade800;
          statusLabel = 'returned'.tr;
        } else if (isOverdue) {
          statusBg = theme.colorScheme.errorContainer;
          statusFg = theme.colorScheme.onErrorContainer;
          statusLabel = 'overdue'.tr;
        } else if (isStolen) {
          statusBg = Colors.red.shade900;
          statusFg = Colors.white;
          statusLabel = 'markStolen'.tr;
        } else {
          statusBg = theme.colorScheme.primaryContainer;
          statusFg = theme.colorScheme.onPrimaryContainer;
          statusLabel = 'active'.tr;
        }

        final durationDays = rent.dueDate.difference(rent.startDate).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: isOverdue
                  ? theme.colorScheme.error.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Book Name & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_date(rent.startDate)} ➔ ${_date(rent.dueDate)} ($durationDays days)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),

                // Financials & Charges Row
                Row(
                  children: [
                    Expanded(
                      child: _infoBlock(
                        label: 'rentPriceLabel'.tr,
                        value: rent.rentPrice.format(),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    Expanded(
                      child: _infoBlock(
                        label: 'depositLabel'.tr,
                        value: rent.deposit.format(),
                        icon: Icons.shield_outlined,
                      ),
                    ),
                    if (rent.extraDayCharge != null &&
                        rent.extraDayCharge!.minorUnits > 0)
                      Expanded(
                        child: _infoBlock(
                          label: 'extraDayCharge'.tr,
                          value: rent.extraDayCharge!.format(),
                          icon: Icons.access_time_outlined,
                          isHighlight: true,
                        ),
                      ),
                    if (rent.damageCharge != null &&
                        rent.damageCharge!.minorUnits > 0)
                      Expanded(
                        child: _infoBlock(
                          label: 'damageCharge'.tr,
                          value: rent.damageCharge!.format(),
                          icon: Icons.warning_amber_rounded,
                          isHighlight: true,
                        ),
                      ),
                  ],
                ),

                // Return details or Overdue indicator
                if (isReturned && rent.returnedDate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${'returnBook'.tr}: ${_date(rent.returnedDate!)}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ] else if (isOverdue) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        '${'orderOverdueLabel'.tr} (${DateTime.now().difference(rent.dueDate).inDays} days)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: Purchases ────────────────────────────────────────────────────
  Widget _buildPurchasesTab(
    BuildContext context,
    CustomersController controller,
    List<Sale> sales,
  ) {
    final theme = Theme.of(context);
    if (sales.isEmpty) {
      return _emptyTabState(
        icon: Icons.shopping_bag_outlined,
        message: 'noCustomerPurchases'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final product = controller.productFor(sale.productId);
        final total = (sale.actualSellPrice * sale.qty).format();

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 18,
              child: Icon(Icons.shopping_bag_outlined, size: 18),
            ),
            title: Text(
              product?.name ?? sale.productId,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${_date(sale.date)} · Qty: ${sale.qty}'),
            trailing: Text(
              total,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Dues & Payment Tracking ───────────────────────────────────────
  Widget _buildDuesTab(
    BuildContext context,
    CustomersController controller,
    List<Due> dues,
  ) {
    final theme = Theme.of(context);
    if (dues.isEmpty) {
      return _emptyTabState(
        icon: Icons.account_balance_wallet_outlined,
        message: 'noCustomerDues'.tr,
      );
    }

    final totalBilled = dues.fold(Money.zero(), (acc, d) => acc + d.originalAmount);
    final totalPaid = dues.fold(Money.zero(), (acc, d) => acc + d.paidAmount);
    final totalRemaining = dues.fold(
      Money.zero(),
      (acc, d) => acc + (d.originalAmount - d.paidAmount),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Summary KPI & Collect Payment Action Card ───────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: totalRemaining.isPositive
                  ? Colors.red.shade300.withValues(alpha: 0.5)
                  : Colors.green.shade300.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _duesKpiItem(
                      context: context,
                      label: 'totalBilledDue'.tr,
                      amount: totalBilled,
                      color: theme.colorScheme.onSurface,
                    ),
                    Container(width: 1, height: 36, color: theme.dividerColor),
                    _duesKpiItem(
                      context: context,
                      label: 'totalPaidSoFar'.tr,
                      amount: totalPaid,
                      color: Colors.green.shade700,
                    ),
                    Container(width: 1, height: 36, color: theme.dividerColor),
                    _duesKpiItem(
                      context: context,
                      label: 'remainingDue'.tr,
                      amount: totalRemaining,
                      color: totalRemaining.isPositive
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      isBold: true,
                    ),
                  ],
                ),
                if (totalRemaining.isPositive) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => _showCollectPaymentSheet(
                      context: context,
                      controller: controller,
                      customer: customer,
                      totalRemaining: totalRemaining,
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(
                      '${'collectPayment'.tr} (${totalRemaining.format()})',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Dues Breakdown with Embedded Payment Receipts ────────────────
        Text(
          '${'customerDueDetails'.tr} (${dues.length})',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),

        for (final due in dues)
          _buildDueCard(context, controller, due),
      ],
    );
  }

  Widget _duesKpiItem({
    required BuildContext context,
    required String label,
    required Money amount,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          amount.format(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDueCard(
    BuildContext context,
    CustomersController controller,
    Due due,
  ) {
    final theme = Theme.of(context);
    final remaining = due.originalAmount - due.paidAmount;
    final isPaid = remaining <= Money.zero();
    final overdue = isOverdue(due, DateTime.now());
    final promised = promisedByDate(due);
    final payments = controller.paymentsForDue(due.id);

    final double progress = due.originalAmount.minorUnits > 0
        ? (due.paidAmount.minorUnits / due.originalAmount.minorUnits).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isPaid
              ? Colors.green.shade200
              : (overdue
                  ? Colors.red.shade300
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Source & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      due.sourceType == DueSourceType.sale
                          ? Icons.shopping_bag_outlined
                          : Icons.menu_book_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      due.sourceType.name.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade50
                        : (due.paidAmount.isPositive
                            ? Colors.orange.shade50
                            : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPaid
                          ? Colors.green.shade200
                          : (due.paidAmount.isPositive
                              ? Colors.orange.shade200
                              : Colors.red.shade200),
                    ),
                  ),
                  child: Text(
                    due.status.name.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? Colors.green.shade800
                          : (due.paidAmount.isPositive
                              ? Colors.orange.shade900
                              : Colors.red.shade800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Row 2: Amounts & Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'total'.tr}: ${due.originalAmount.format()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  '${'remainingDue'.tr}: ${remaining.format()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _date(due.createdAt) +
                      (promised != null ? ' · ${'enterDueDay'.tr}: ${_date(promised)}' : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: overdue ? Colors.red.shade700 : Colors.grey.shade600,
                    fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% ${'paid'.tr}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),

            // ── Payment Receipts History for this Due ────────────────────
            if (payments.isNotEmpty) ...[
              const Divider(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${'paymentsReceived'.tr} (${payments.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final p in payments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy, h:mm a').format(p.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.paymentMethod.name.tr,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '+ ${p.amount.format()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Pay Single Due Button if unpaid
            if (!isPaid) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _showCollectPaymentSheet(
                    context: context,
                    controller: controller,
                    customer: customer,
                    dueId: due.id,
                    totalRemaining: remaining,
                  ),
                  icon: const Icon(Icons.payment, size: 14),
                  label: Text('payNow'.tr, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCollectPaymentSheet({
    required BuildContext context,
    required CustomersController controller,
    required Customer customer,
    String? dueId,
    required Money totalRemaining,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CustomerCollectDueSheet(
        customer: customer,
        controller: controller,
        dueId: dueId,
        totalRemaining: totalRemaining,
      ),
    );
  }

  // ── Tab 4: Pre-Orders ───────────────────────────────────────────────────
  Widget _buildOrdersTab(BuildContext context, List<Order> orders) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return _emptyTabState(
        icon: Icons.assignment_outlined,
        message: 'noCustomerOrders'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 18,
              child: Icon(Icons.assignment_outlined, size: 18),
            ),
            title: Text(
              order.itemDescription,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${'dueDate'.tr}: ${_date(order.requestedDate)}'),
            trailing: Chip(
              label: Text(
                order.status.name.tr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      },
    );
  }

  Widget _infoBlock({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }

  Widget _emptyTabState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _customerAvatar(BuildContext context, CustomersController controller) {
    final theme = Theme.of(context);
    final image = controller.primaryImageFor(customer.id);
    final source = image == null ? null : controller.imageSourceFor(image);

    final initial = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim().characters.first.toUpperCase();
    final fallbackAvatar = CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 18,
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
        heroTag: 'detail_sheet_avatar_${customer.id}',
      ),
      child: Hero(
        tag: 'detail_sheet_avatar_${customer.id}',
        child: SafeImage(
          source: source,
          width: 48,
          height: 48,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          fallbackWidget: fallbackAvatar,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomersController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${'delete'.tr} ${customer.name}?'),
        content: Text('deleteCustomerConfirm'.tr),
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
    if (confirmed == true) {
      final ok = await controller.deleteCustomer(customer.id);
      if (ok && context.mounted) {
        Navigator.of(context).pop();
        Get.snackbar(
          'customerDeleted'.tr,
          customer.name,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  static String _date(DateTime date) =>
      DateFormat('d MMM y').format(date.toLocal());

  static String _money(int minorUnits) => Money.fromMinor(minorUnits).format();
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Sheet to record payment received from a due customer directly inside Customer Detail.
class _CustomerCollectDueSheet extends StatefulWidget {
  final Customer customer;
  final CustomersController controller;
  final String? dueId;
  final Money totalRemaining;

  const _CustomerCollectDueSheet({
    required this.customer,
    required this.controller,
    this.dueId,
    required this.totalRemaining,
  });

  @override
  State<_CustomerCollectDueSheet> createState() =>
      _CustomerCollectDueSheetState();
}

class _CustomerCollectDueSheetState extends State<_CustomerCollectDueSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.totalRemaining.format(showSymbol: false),
  );
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Money? _parseMoney(String text) {
    final cleaned = text.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return null;
    return Money.fromMinor((parsed * 100).round());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseMoney(_amountController.text);
    if (amount == null) return;

    if (amount > widget.totalRemaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'dueOverpayNotAllowed'.tr} (${widget.totalRemaining.format()})',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final bool ok;
    if (widget.dueId != null) {
      ok = await widget.controller.payCustomerDue(
        dueId: widget.dueId!,
        paymentAmount: amount,
        paymentMethod: _paymentMethod,
      );
    } else {
      ok = await widget.controller.payCustomerBalance(
        customerId: widget.customer.id,
        paymentAmount: amount,
        paymentMethod: _paymentMethod,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('paymentRecorded'.tr),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage.value ?? 'paymentFailed'.tr,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'collectPayment'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.customer.name} • ${'remainingDue'.tr}: ${widget.totalRemaining.format()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'cashAmount'.tr,
                prefixText: '৳ ',
                helperText:
                    '${'remainingDue'.tr}: ${widget.totalRemaining.format()}',
              ),
              validator: (v) {
                final money = _parseMoney(v ?? '');
                if (money == null) return 'amountRequired'.tr;
                if (money > widget.totalRemaining) {
                  return '${'dueOverpayNotAllowed'.tr} (${widget.totalRemaining.format()})';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(labelText: 'paymentMethod'.tr),
              items: [
                for (final method in PaymentMethod.values)
                  DropdownMenuItem(
                    value: method,
                    child: Text(method.name.tr),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('confirmAmount'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
