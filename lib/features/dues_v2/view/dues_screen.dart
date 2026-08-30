import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/services/due_lifecycle.dart';
import '../controller/dues_controller.dart';

/// The Customer-Centric Dues screen — aggregates outstanding balances by customer
/// so each debtor has one unified card with detailed breakdown and batch/individual paydown.
class DuesScreen extends GetView<DuesController> {
  final VoidCallback? onMenuTap;

  const DuesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'dues'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
      ),
      body: Obx(() {
        final groups = controller.customerDueGroups;
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'noDuesYet'.tr,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.update(),
          child: SingleChildScrollView(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${groups.length} ${'customers'.tr}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final group in groups)
                  _CustomerDueCard(group: group),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Metrics at the top of the Dues screen showing total outstanding amount & customer count.
class _DuesSummaryMetrics extends StatelessWidget {
  final DuesController controller;

  const _DuesSummaryMetrics({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalAmount = controller.totalDuesAmount;
      final customerCount = controller.totalDueCustomersCount;
      final overdueCount = controller.totalOverdueCount;

      return Row(
        children: [
          Expanded(
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade300.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'totalDueAmount'.tr,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalAmount.format(),
                      style: TextStyle(
                        fontSize: 17,
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
          Expanded(
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.orange.shade300.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'totalDueCustomers'.tr,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$customerCount ${'customers'.tr}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        if (overdueCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$overdueCount ${'overdue'.tr}',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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
    final amountController = TextEditingController(text: remaining.format(showSymbol: false));
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'cashAmount'.tr, prefixText: '৳ '),
                      validator: (v) => _parseMoneyOrNull(v ?? '') == null ? 'invalidQty'.tr : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<PaymentMethod>(
                      segments: [
                        ButtonSegment(value: PaymentMethod.cash, label: Text('cash'.tr)),
                        ButtonSegment(value: PaymentMethod.mobileBanking, label: Text('mobile'.tr)),
                        ButtonSegment(value: PaymentMethod.bankTransfer, label: Text('bank'.tr)),
                      ],
                      selected: {method},
                      onSelectionChanged: (s) => setState(() => method = s.first),
                    ),
                  ],
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
                    final amt = _parseMoneyOrNull(amountController.text);
                    if (amt == null) return;
                    final ok = await controller.payDue(
                      dueId: due.id,
                      paymentAmount: amt,
                      paymentMethod: method,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('paymentSaved'.tr)),
                      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat.yMMMd().format(due.createdAt)} (${due.sourceType.name.tr})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${'dueAmount'.tr}: ${remaining.format()} / ${'total'.tr}: ${due.originalAmount.format()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            onPressed: () => _paySingleDue(context, due),
            child: Text('payNow'.tr, style: const TextStyle(fontSize: 11)),
          ),
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

  DuesController get controller => Get.find<DuesController>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
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
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'cashAmount'.tr,
                prefixText: '৳ ',
                helperText: 'Max: ${widget.group.totalRemainingAmount.format()}',
              ),
              validator: (v) {
                final amt = _parseMoneyOrNull(v ?? '');
                if (amt == null || amt <= Money.zero()) return 'invalidQty'.tr;
                if (amt > widget.group.totalRemainingAmount) return 'Amount exceeds total due';
                return null;
              },
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
