import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/due_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/services/due_lifecycle.dart';
import '../controller/dues_controller.dart';

/// The Customer-Centric Dues screen — aggregates outstanding balances by customer
/// so each debtor has one unified card with detailed breakdown, batch/individual paydown,
/// and complete payment collection history.
class DuesScreen extends GetView<DuesController> {
  final VoidCallback? onMenuTap;

  const DuesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = controller.customerDueGroups;
      final payments = controller.duePayments;

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: ShopAppBarTitle(pageTitle: 'dues'.tr),
            leading: onMenuTap == null
                ? null
                : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(42),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Text('${'activeDuesTab'.tr} (${groups.length})'),
                    ),
                    Tab(
                      child: Text('${'paymentHistoryTab'.tr} (${payments.length})'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              // ── Tab 1: Active Dues ─────────────────────────────────────────
              RefreshIndicator(
                onRefresh: () async => controller.update(),
                child: groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 56,
                              color: Colors.green,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'noDuesYet'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DuesSummaryMetrics(controller: controller),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'totalDueCustomers'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${groups.length} ${'customers'.tr}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final group in groups)
                              _CustomerDueCard(group: group),
                          ],
                        ),
                      ),
              ),

              // ── Tab 2: Payment History ─────────────────────────────────────
              _PaymentHistoryView(controller: controller),
            ],
          ),
        ),
      );
    });
  }
}

/// Metrics at the top of the Dues screen showing total outstanding, total collected & customer count.
class _DuesSummaryMetrics extends StatelessWidget {
  final DuesController controller;

  const _DuesSummaryMetrics({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalAmount = controller.totalDuesAmount;
      final totalCollected = controller.totalCollectedAmount;
      final customerCount = controller.totalDueCustomersCount;
      final overdueCount = controller.totalOverdueCount;

      return Column(
        children: [
          Row(
            children: [
              // Card 1: Total Outstanding Due
              Expanded(
                child: Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.red.shade300.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'totalDueAmount'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalAmount.format(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Card 2: Total Collected
              Expanded(
                child: Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.green.shade300.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'totalCollected'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalCollected.format(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Card 3: Due Customers Count & Overdue Badge
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.orange.shade300.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 18,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'totalDueCustomers'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$customerCount ${'customers'.tr}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      if (overdueCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$overdueCount ${'overdue'.tr}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Unified Customer Card aggregating all dues for that specific customer.
class _CustomerDueCard extends GetView<DuesController> {
  final CustomerDueGroup group;

  const _CustomerDueCard({required this.group});

  void _callCustomer(String? contact) {
    if (contact == null || contact.trim().isEmpty) return;
    launchUrl(Uri.parse('tel:$contact'));
  }

  void _showCustomerDueDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CustomerDueDetailsSheet(group: group),
    );
  }

  void _showPayModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PayCustomerDueSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = group.hasOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? theme.colorScheme.error.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCustomerDueDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isOverdue
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    child: Text(
                      group.customerName.isNotEmpty ? group.customerName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                group.customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'overdue'.tr,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (group.customerContact != null && group.customerContact!.isNotEmpty)
                          Text(
                            group.customerContact!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.dueCount} ${'dueEntriesCount'.tr}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        group.totalRemainingAmount.format(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isOverdue ? theme.colorScheme.error : Colors.red.shade700,
                        ),
                      ),
                      if (group.totalOriginalAmount != group.totalRemainingAmount)
                        Text(
                          '${'total'.tr}: ${group.totalOriginalAmount.format()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ],
              ),
              if (group.latestPromisedDate != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${'enterDueDay'.tr}: ${DateFormat.yMMMd().format(group.latestPromisedDate!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              const Divider(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (group.customerContact != null && group.customerContact!.isNotEmpty)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _callCustomer(group.customerContact),
                      icon: const Icon(Icons.phone_outlined, size: 15),
                      label: Text('callCustomer'.tr, style: const TextStyle(fontSize: 12)),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _showCustomerDueDetails(context),
                        icon: const Icon(Icons.list_alt, size: 15),
                        label: Text('customerDueDetails'.tr, style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _showPayModal(context),
                        icon: const Icon(Icons.payments_outlined, size: 15),
                        label: Text('payNow'.tr, style: const TextStyle(fontSize: 12)),
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
}

/// Detailed breakdown sheet showing every individual credit transaction for a customer.
class _CustomerDueDetailsSheet extends StatelessWidget {
  final CustomerDueGroup group;

  const _CustomerDueDetailsSheet({required this.group});

  DuesController get controller => Get.find<DuesController>();

  void _paySingleDue(BuildContext context, Due due) {
    Navigator.of(context).pop();
    final remaining = controller.remainingOf(due);
    _showSingleDuePayDialog(context, due, remaining);
  }

  void _showSingleDuePayDialog(BuildContext context, Due due, Money remaining) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SingleDuePaySheet(due: due, remaining: remaining),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerPayments = controller.paymentsForCustomer(group.customerId);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
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
                      group.customerName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${'totalDueAmount'.tr}: ${group.totalRemainingAmount.format()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
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
            const Divider(height: AppSpacing.lg),
            Text(
              '${'customerDueDetails'.tr} (${group.dues.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < group.dues.length; i++) ...[
              _dueItemRow(context, group.dues[i], i + 1),
              if (i < group.dues.length - 1) const Divider(height: AppSpacing.md),
            ],

            // ── Customer's Full Payments Received History ──────────────────
            if (customerPayments.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text(
                    '${'paymentsReceived'.tr} (${customerPayments.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final p in customerPayments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 13, color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('d MMM yyyy, h:mm a').format(p.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.paymentMethod.name.tr,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
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

            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => _PayCustomerDueSheet(group: group),
                );
              },
              icon: const Icon(Icons.payments_outlined),
              label: Text('${'payCustomerDue'.tr} (${group.totalRemainingAmount.format()})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dueItemRow(BuildContext context, Due due, int index) {
    final remaining = controller.remainingOf(due);
    final overdue = controller.dueIsOverdue(due);
    final promised = promisedByDate(due);
    final payments = controller.paymentsForDue(due.id);
    final isPaid = remaining <= Money.zero();

    final double progress = due.originalAmount.minorUnits > 0
        ? (due.paidAmount.minorUnits / due.originalAmount.minorUnits).clamp(0.0, 1.0)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat.yMMMd().format(due.createdAt)} (${due.sourceType.name.tr})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.shade50
                                : (due.paidAmount.isPositive ? Colors.orange.shade50 : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPaid ? Colors.green.shade200 : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            due.status.name.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? Colors.green.shade800
                                  : (due.paidAmount.isPositive ? Colors.orange.shade900 : Colors.red.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'dueAmount'.tr}: ${remaining.format()} / ${'total'.tr}: ${due.originalAmount.format()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPaid ? Colors.green.shade700 : Colors.grey.shade700,
                        fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (promised != null)
                      Text(
                        '${'enterDueDay'.tr}: ${DateFormat.yMMMd().format(promised)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: overdue ? Colors.red.shade700 : Colors.grey.shade600,
                          fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaid) ...[
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _paySingleDue(context, due),
                  child: Text('payNow'.tr, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),

          // Receipts list under this due if payments exist
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  for (final p in payments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '↳ ${DateFormat('d MMM, h:mm a').format(p.date)} (${p.paymentMethod.name.tr})',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                          Text(
                            '+ ${p.amount.format()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal Sheet to collect payment against a customer's total due balance (cascading payoff).
class _PayCustomerDueSheet extends StatefulWidget {
  final CustomerDueGroup group;

  const _PayCustomerDueSheet({required this.group});

  @override
  State<_PayCustomerDueSheet> createState() => _PayCustomerDueSheetState();
}

class _PayCustomerDueSheetState extends State<_PayCustomerDueSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.group.totalRemainingAmount.format(showSymbol: false),
  );
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isKeypadActive = true;

  DuesController get controller => Get.find<DuesController>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    finalizeCalculatorController(_amountController);
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseMoneyOrNull(_amountController.text);
    if (amount == null) return;

    final ok = await controller.payCustomerBalance(
      customerId: widget.group.customerId,
      paymentAmount: amount,
      paymentMethod: _paymentMethod,
    );

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('paymentSaved'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final formContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: _isKeypadActive ? AppSpacing.sm : AppSpacing.lg,
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
                      'payCustomerDue'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.group.customerName} • ${'totalDueAmount'.tr}: ${widget.group.totalRemainingAmount.format()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
            CalculatorFieldCard(
              label: 'cashAmount'.tr,
              value: _amountController.text,
              isSelected: _isKeypadActive,
              onTap: () => setState(() => _isKeypadActive = true),
              prefixText: '৳ ',
              helperText: 'Max: ${widget.group.totalRemainingAmount.format()}',
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<PaymentMethod>(
              segments: [
                ButtonSegment(value: PaymentMethod.cash, label: Text('cash'.tr)),
                ButtonSegment(value: PaymentMethod.mobileBanking, label: Text('mobile'.tr)),
                ButtonSegment(value: PaymentMethod.bankTransfer, label: Text('bank'.tr)),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(() {
              final err = controller.errorMessage.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(err, style: const TextStyle(color: Colors.red, fontSize: 13)),
              );
            }),
            if (!_isKeypadActive)
              Obx(
                () => FilledButton(
                  onPressed: controller.isSaving.value ? null : _submit,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ),
          ],
        ),
      ),
    );

    final sheetDecoration = BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );

    if (_isKeypadActive) {
      return SizedBox(
        height: screenHeight * 0.92,
        child: Container(
          decoration: sheetDecoration,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isKeypadActive = false),
                    behavior: HitTestBehavior.translucent,
                    child: formContent,
                  ),
                ),
                InPlaceCalculatorBar(
                  label: 'cashAmount'.tr,
                  currentText: _amountController.text,
                  prefixText: '৳ ',
                  onDone: () => setState(() => _isKeypadActive = false),
                ),
                CalculatorKeypad(
                  onKeyPress: (key) {
                    setState(() {
                      applyCalculatorKeyToController(_amountController, key);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: sheetDecoration,
        child: SafeArea(top: false, child: formContent),
      ),
    );
  }
}

/// Bottom Sheet for paying a single specific Due item with calculator keypad.
class _SingleDuePaySheet extends StatefulWidget {
  final Due due;
  final Money remaining;
  const _SingleDuePaySheet({required this.due, required this.remaining});

  @override
  State<_SingleDuePaySheet> createState() => _SingleDuePaySheetState();
}

class _SingleDuePaySheetState extends State<_SingleDuePaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isKeypadActive = true;

  DuesController get controller => Get.find<DuesController>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.remaining.format(showSymbol: false),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    finalizeCalculatorController(_amountController);
    if (!_formKey.currentState!.validate()) return;
    final amt = _parseMoneyOrNull(_amountController.text);
    if (amt == null || amt <= Money.zero()) return;
    final ok = await controller.payDue(
      dueId: widget.due.id,
      paymentAmount: amt,
      paymentMethod: _paymentMethod,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('paymentSaved'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final formContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: _isKeypadActive ? AppSpacing.sm : AppSpacing.lg,
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
                Text(
                  'payNow'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CalculatorFieldCard(
              label: 'cashAmount'.tr,
              value: _amountController.text,
              isSelected: _isKeypadActive,
              onTap: () => setState(() => _isKeypadActive = true),
              prefixText: '৳ ',
              helperText: 'Max: ${widget.remaining.format()}',
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<PaymentMethod>(
              segments: [
                ButtonSegment(value: PaymentMethod.cash, label: Text('cash'.tr)),
                ButtonSegment(value: PaymentMethod.mobileBanking, label: Text('mobile'.tr)),
                ButtonSegment(value: PaymentMethod.bankTransfer, label: Text('bank'.tr)),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!_isKeypadActive)
              FilledButton(
                onPressed: _submit,
                child: Text('save'.tr),
              ),
          ],
        ),
      ),
    );

    final sheetDecoration = BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );

    if (_isKeypadActive) {
      return SizedBox(
        height: screenHeight * 0.92,
        child: Container(
          decoration: sheetDecoration,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isKeypadActive = false),
                    behavior: HitTestBehavior.translucent,
                    child: formContent,
                  ),
                ),
                InPlaceCalculatorBar(
                  label: 'cashAmount'.tr,
                  currentText: _amountController.text,
                  prefixText: '৳ ',
                  onDone: () => setState(() => _isKeypadActive = false),
                ),
                CalculatorKeypad(
                  onKeyPress: (key) {
                    setState(() {
                      applyCalculatorKeyToController(_amountController, key);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: sheetDecoration,
        child: SafeArea(top: false, child: formContent),
      ),
    );
  }
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}

/// Tab 2 View in DuesScreen: Chronological ledger of all payments received from due customers.
class _PaymentHistoryView extends StatefulWidget {
  final DuesController controller;

  const _PaymentHistoryView({required this.controller});

  @override
  State<_PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<_PaymentHistoryView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = widget.controller.duePayments;
      if (payments.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: AppSpacing.md),
              Text(
                'noPaymentsRecorded'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      // Filter payments by search query if any
      final filtered = payments.where((p) {
        if (_searchQuery.isEmpty) return true;
        final due = widget.controller.dues.firstWhereOrNull((d) => d.id == p.dueId);
        if (due == null) return false;
        final cust = widget.controller.customerById(due.customerId);
        final name = cust?.name.toLowerCase() ?? '';
        final contact = cust?.contact?.toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || contact.contains(q);
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return RefreshIndicator(
        onRefresh: () async => widget.controller.update(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Total Collected Summary Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade300.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.green.shade50,
                      child: Icon(
                        Icons.payments_outlined,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'totalCollected'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            widget.controller.totalCollectedAmount.format(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${payments.length} ${'dueEntriesCount'.tr}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Search Box
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '${'search'.tr}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: AppSpacing.md),

            // Feed / List of Receipts
            for (final p in filtered) _buildPaymentCard(context, p),
          ],
        ),
      );
    });
  }

  Widget _buildPaymentCard(BuildContext context, DuePayment payment) {
    final theme = Theme.of(context);
    final due = widget.controller.dues.firstWhereOrNull((d) => d.id == payment.dueId);
    final customer = due != null ? widget.controller.customerById(due.customerId) : null;
    final customerName = customer?.name ?? (due != null ? due.customerId : 'customer'.tr);
    final sourceTypeLabel = due?.sourceType.name.tr ?? 'due'.tr;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      elevation: 0.3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.shade50,
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        DateFormat('d MMM yyyy, h:mm a').format(payment.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
                          sourceTypeLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ${payment.amount.format()}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    payment.paymentMethod.name.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

