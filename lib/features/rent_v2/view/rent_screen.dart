import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/notification_bell_action.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/services/rent_lifecycle.dart';
import '../controller/rent_controller.dart';

/// The upgraded Book Rental (বই ভাড়া) screen — issue, return, track active &
/// overdue book rentals, manage security deposits, calculate late fines,
/// and view complete return history.
class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  String _activeTab = 'active'; // 'active', 'overdue', 'history'

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentController>();

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'rent'.tr),
        actions: const [
          NotificationBellAction(),
          SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final activeRentals = controller.activeRentals;
        final overdueRentals = controller.overdueRentals;
        final historyRentals = controller.history;

        final activeCount = controller.activeCount;
        final overdueCount = controller.overdueCount;
        final historyCount = controller.historyCount;
        final totalDeposits = controller.totalActiveDeposits;
        final totalRevenue = controller.totalRentRevenue;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Top Metrics Summary Grid ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'চলতি ভাড়া',
                    value: '$activeCountটি বই',
                    icon: Icons.menu_book_rounded,
                    color: Colors.blue.shade700,
                    bgColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'জামানত জমা',
                    value: totalDeposits.format(),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.teal.shade800,
                    bgColor: Colors.teal.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'মেয়াদ শেষ (ওভারডিউ)',
                    value: '$overdueCountটি বই',
                    icon: Icons.warning_amber_rounded,
                    color: overdueCount > 0 ? Colors.red.shade700 : Colors.grey.shade600,
                    bgColor: overdueCount > 0 ? Colors.red.shade50 : Colors.grey.shade100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'মোট ভাড়া আয়',
                    value: totalRevenue.format(),
                    icon: Icons.trending_up_rounded,
                    color: Colors.green.shade800,
                    bgColor: Colors.green.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 2. Segmented Pill Tabs ─────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.bookmark_outline_rounded, size: 16),
                    label: Text('চলতি ভাড়া ($activeCount)'),
                    selected: _activeTab == 'active',
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 'active');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: overdueCount > 0 ? Colors.red.shade700 : null,
                    ),
                    label: Text(
                      'মেয়াদোত্তীর্ণ ($overdueCount)',
                      style: TextStyle(
                        color: overdueCount > 0 && _activeTab != 'overdue'
                            ? Colors.red.shade700
                            : null,
                        fontWeight: overdueCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _activeTab == 'overdue',
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 'overdue');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: Text('ফেরতের ইতিহাস ($historyCount)'),
                    selected: _activeTab == 'history',
                    onSelected: (val) {
                      if (val) setState(() => _activeTab = 'history');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3. Tab Content ─────────────────────────────────────────────
            if (_activeTab == 'active') ...[
              if (activeRentals.isEmpty)
                _buildEmptyState(
                  context,
                  icon: Icons.menu_book_outlined,
                  message: 'বর্তমানে কোনো বই ভাড়া দেওয়া নেই',
                  buttonLabel: 'নতুন বই ভাড়া দিন',
                  onAction: () => _openIssueSheet(context),
                )
              else
                for (final rent in activeRentals)
                  _ActiveRentCard(
                    rent: rent,
                    onReturn: () => _openReturnSheet(context, rent),
                    onMarkStolen: () => _confirmMarkStolen(context, controller, rent),
                  ),
            ] else if (_activeTab == 'overdue') ...[
              if (overdueRentals.isEmpty)
                _buildEmptyState(
                  context,
                  icon: Icons.check_circle_outline_rounded,
                  message: 'কোনো মেয়াদোত্তীর্ণ বই নেই! সব ভাড়া সময়মতো আছে।',
                )
              else
                for (final rent in overdueRentals)
                  _ActiveRentCard(
                    rent: rent,
                    onReturn: () => _openReturnSheet(context, rent),
                    onMarkStolen: () => _confirmMarkStolen(context, controller, rent),
                  ),
            ] else ...[
              if (historyRentals.isEmpty)
                _buildEmptyState(
                  context,
                  icon: Icons.history_rounded,
                  message: 'এখনো কোনো বই ফেরতের ইতিহাস নেই',
                )
              else
                for (final rent in historyRentals)
                  _HistoryRentCard(rent: rent),
            ],
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'rent_fab',
        onPressed: () => _openIssueSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('বই ভাড়া দিন'),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? buttonLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openIssueSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _IssueRentSheet(),
    );
  }

  void _openReturnSheet(BuildContext context, RentTransaction rent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnRentSheet(rent: rent),
    );
  }

  Future<void> _confirmMarkStolen(
    BuildContext context,
    RentController controller,
    RentTransaction rent,
  ) async {
    final book = controller.productById(rent.bookProductId);
    final customer = controller.customerName(rent.customerId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('বই চুরি / হারানো চিহ্নিতকরণ'),
        content: Text(
          'আপনি কি "${book?.name ?? 'বই'}" ভাড়াটি হারানো/চুরি হিসেবে চিহ্নিত করতে চান?\n\n'
          'গ্রাহক: $customer\n'
          'জামানত (${rent.deposit.format()}) ক্ষতিপূরণ হিসেবে ক্যাশে যুক্ত হবে।',
        ),
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
            child: const Text('হারানো নিশ্চিত করুন'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await controller.markStolen(rent.id);
      if (success) {
        Get.snackbar(
          'বই হারানো চিহ্নিত',
          'বইটি হারানো হিসেবে রেকর্ড করা হয়েছে এবং জামানত সমন্বয় করা হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Rental Card ──────────────────────────────────────────────────────
class _ActiveRentCard extends StatelessWidget {
  final RentTransaction rent;
  final VoidCallback onReturn;
  final VoidCallback onMarkStolen;

  const _ActiveRentCard({
    required this.rent,
    required this.onReturn,
    required this.onMarkStolen,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentController>();
    final theme = Theme.of(context);
    final book = controller.productById(rent.bookProductId);
    final customer = controller.customerName(rent.customerId);
    final overdue = controller.rentIsOverdue(rent);

    final now = DateTime.now();
    final remainingDays = rent.dueDate.difference(now).inDays;
    final overdueDays = now.difference(rent.dueDate).inDays;

    final startFmt = DateFormat('dd MMM').format(rent.startDate);
    final dueFmt = DateFormat('dd MMM, yyyy').format(rent.dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: overdue
              ? Colors.red.shade300
              : Colors.teal.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Overdue Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: overdue
                        ? Colors.red.withValues(alpha: 0.12)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: overdue ? Colors.red.shade700 : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.name ?? 'বই আইডি: ${rent.bookProductId}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            customer,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'stolen') onMarkStolen();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'stolen',
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'বই হারিয়ে গেছে / চুরি',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date & Countdown Pills
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '📅 $startFmt - $dueFmt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (overdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⚠️ ${overdueDays > 0 ? '$overdueDays দিন' : ''} ওভারডিউ!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⏳ আর ${remainingDays >= 0 ? remainingDays : 0} দিন বাকি',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Financial Info & Return Button
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ভাড়া ফি: ${rent.rentPrice.format()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'জামানত: ${rent.deposit.format()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onReturn,
                  icon: const Icon(Icons.keyboard_return_rounded, size: 16),
                  label: const Text('বই ফেরত নিন'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Rental Card ─────────────────────────────────────────────────────
class _HistoryRentCard extends StatelessWidget {
  final RentTransaction rent;

  const _HistoryRentCard({required this.rent});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentController>();
    final theme = Theme.of(context);
    final book = controller.productById(rent.bookProductId);
    final customer = controller.customerName(rent.customerId);
    final isReturned = rent.status == RentStatus.returned;

    final startFmt = DateFormat('dd MMM, yyyy').format(rent.startDate);
    final returnFmt = rent.returnedDate != null
        ? DateFormat('dd MMM, yyyy').format(rent.returnedDate!)
        : 'অজ্ঞাত';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isReturned ? Colors.green.shade200 : Colors.red.shade200,
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
                  isReturned
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: isReturned ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    book?.name ?? rent.bookProductId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isReturned ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isReturned ? '✓ ফেরত সম্পন্ন' : '⚠️ বই হারিয়েছে',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isReturned ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'গ্রাহক: $customer · মেয়াদ: $startFmt ➔ $returnFmt',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                Text(
                  'ভাড়া ফি: ${rent.rentPrice.format()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (rent.extraDayCharge != null && rent.extraDayCharge! > Money.zeroBdt)
                  Text(
                    'বিলম্ব ফি: +${rent.extraDayCharge!.format()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                if (rent.damageCharge != null && rent.damageCharge! > Money.zeroBdt)
                  Text(
                    'ক্ষতিপূরণ: +${rent.damageCharge!.format()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
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

// ── Issue Rental Form Sheet ─────────────────────────────────────────────────
class _IssueRentSheet extends StatefulWidget {
  const _IssueRentSheet();

  @override
  State<_IssueRentSheet> createState() => _IssueRentSheetState();
}

class _IssueRentSheetState extends State<_IssueRentSheet> {
  final _formKey = GlobalKey<FormState>();
  RentController get controller => Get.find<RentController>();

  Product? _selectedBook;
  String? _selectedCustomerId;
  final _daysController = TextEditingController(text: '15');
  final _priceController = TextEditingController(text: '50');
  final _depositController = TextEditingController(text: '200');

  @override
  void dispose() {
    _daysController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _onBookSelected(Product book) {
    setState(() {
      _selectedBook = book;
      final suggestion = controller.suggestedTierFor(book);
      if (suggestion != null) {
        _daysController.text = suggestion.days.toString();
        _priceController.text = (suggestion.price.minorUnits / 100).toStringAsFixed(0);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBook == null || _selectedCustomerId == null) return;

    final deposit = _parseMoneyOrNull(_depositController.text) ?? Money.zeroBdt;
    final days = int.tryParse(_daysController.text.trim());
    final rentPrice = _parseMoneyOrNull(_priceController.text);

    final ok = await controller.issueRent(
      bookProductId: _selectedBook!.id,
      customerId: _selectedCustomerId!,
      deposit: deposit,
      days: days,
      rentPrice: rentPrice,
    );

    if (ok && mounted) {
      Navigator.of(context).pop();
      Get.snackbar(
        'ভাড়া ইস্যু সফল',
        '${_selectedBook!.name} বইটির ভাড়া সফলভাবে এন্ট্রি করা হয়েছে।',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'বই ভাড়া ইস্যু করুন',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── 1. Select Book ──
                  DropdownButtonFormField<Product>(
                    initialValue: _selectedBook,
                    decoration: InputDecoration(
                      labelText: 'বই নির্বাচন করুন *',
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      for (final p in controller.rentableProducts)
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (উপলব্ধ: ${controller.availableCopiesFor(p)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) _onBookSelected(v);
                    },
                    validator: (v) => v == null ? 'একটি বই নির্বাচন করুন' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── 2. Select Customer ──
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: InputDecoration(
                      labelText: 'গ্রাহক নির্বাচন করুন *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      for (final c in controller.customers)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontSize: 14)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
                    validator: (v) => v == null ? 'গ্রাহক নির্বাচন করুন' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── 3. Rental Days & Quick Chips ──
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'মেয়াদ (দিন) *',
                            hintText: '15',
                            suffixText: 'দিন',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'দিন লিখুন' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'ভাড়া ফি *',
                            prefixText: '৳ ',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'ফি লিখুন' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [7, 15, 30].map((d) {
                      return ActionChip(
                        label: Text('$d দিন'),
                        onPressed: () => setState(() => _daysController.text = '$d'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── 4. Security Deposit ──
                  TextFormField(
                    controller: _depositController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'জামানত / সিকিউরিটি ডিপোজিট (৳)',
                      hintText: '200',
                      prefixText: '৳ ',
                      helperText: 'বই ফেরত দেওয়ার সময় এই টাকা সমন্বয় বা ফেরত হবে',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Submit Button ──
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.isSaving.value ? null : _submit,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: controller.isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('বই ভাড়া ইস্যু করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Return Rental Form Sheet ────────────────────────────────────────────────
class _ReturnRentSheet extends StatefulWidget {
  final RentTransaction rent;

  const _ReturnRentSheet({required this.rent});

  @override
  State<_ReturnRentSheet> createState() => _ReturnRentSheetState();
}

class _ReturnRentSheetState extends State<_ReturnRentSheet> {
  final _formKey = GlobalKey<FormState>();
  RentController get controller => Get.find<RentController>();

  late final TextEditingController _extraDayController;
  final _damageController = TextEditingController(text: '0');
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    final suggestedExtra = controller.suggestedExtraDayChargeFor(widget.rent, DateTime.now());
    _extraDayController = TextEditingController(
      text: (suggestedExtra.minorUnits / 100).toStringAsFixed(
        suggestedExtra.minorUnits % 100 == 0 ? 0 : 2,
      ),
    );
  }

  @override
  void dispose() {
    _extraDayController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  Money get _extraDayCharge => _parseMoneyOrNull(_extraDayController.text) ?? Money.zeroBdt;
  Money get _damageCharge => _parseMoneyOrNull(_damageController.text) ?? Money.zeroBdt;

  ReturnSettlement get _settlement {
    return computeReturnSettlement(
      rentPrice: widget.rent.rentPrice,
      deposit: widget.rent.deposit,
      extraDayCharge: _extraDayCharge,
      damageCharge: _damageCharge,
    );
  }

  Future<void> _submit() async {
    final settlement = _settlement;
    final amountReceivedNow = settlement.customerOwes ? settlement.netAmount : Money.zeroBdt;

    final ok = await controller.returnRent(
      rentId: widget.rent.id,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: _paymentMethod,
      extraDayCharge: _extraDayCharge,
      damageCharge: _damageCharge,
    );

    if (ok && mounted) {
      Navigator.of(context).pop();
      Get.snackbar(
        'বই ফেরত সম্পন্ন',
        'বইটি সফলভাবে ফেরত নেওয়া হয়েছে এবং হিসাব সমন্বয় করা হয়েছে।',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = controller.productById(widget.rent.bookProductId);
    final customer = controller.customerName(widget.rent.customerId);
    final settlement = _settlement;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'বই ফেরত নিন',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Rental Info Banner ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book?.name ?? 'বই আইডি: ${widget.rent.bookProductId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('গ্রাহক: $customer', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('জামানত: ${widget.rent.deposit.format()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 14),
                            Text('ভাড়া ফি: ${widget.rent.rentPrice.format()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Extra Days / Damage Inputs ──
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _extraDayController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'বিলম্ব জরিমানা (৳)',
                            prefixText: '৳ ',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _damageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'বইয়ের ক্ষতিপূরণ (৳)',
                            prefixText: '৳ ',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Settlement Summary Card ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: settlement.refundOwed
                          ? Colors.green.shade50
                          : (settlement.customerOwes ? Colors.amber.shade50 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: settlement.refundOwed
                            ? Colors.green.shade300
                            : (settlement.customerOwes ? Colors.amber.shade400 : Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('জামানত জমা ছিল:', style: TextStyle(fontSize: 12)),
                            Text(widget.rent.deposit.format(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('মোট কাটা যাবে (ভাড়া+জরিমানা):', style: TextStyle(fontSize: 12)),
                            Text('- ${(widget.rent.rentPrice + _extraDayCharge + _damageCharge).format()}', style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              settlement.refundOwed
                                  ? 'গ্রাহককে ফেরত দিতে হবে:'
                                  : (settlement.customerOwes ? 'গ্রাহক থেকে নিতে হবে:' : 'হিসাব সম্পন্ন:'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: settlement.refundOwed
                                    ? Colors.green.shade900
                                    : (settlement.customerOwes ? Colors.amber.shade900 : Colors.black),
                              ),
                            ),
                            Text(
                              settlement.refundOwed
                                  ? settlement.refundAmount.format()
                                  : settlement.netAmount.format(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: settlement.refundOwed
                                    ? Colors.green.shade800
                                    : (settlement.customerOwes ? Colors.red.shade800 : Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Payment Method Toggle ──
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

                  // ── Submit Button ──
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.isSaving.value ? null : _submit,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('বই ফেরত সম্পন্ন করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
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
