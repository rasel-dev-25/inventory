import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';
import '../controller/order_controller.dart';

/// The Order screen — customer pre-orders with clean, modern, and
/// professional UI, customer photo preview, date picker, and bottom sheet.
class OrderScreen extends GetView<OrderController> {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'orders'.tr),
      ),
      body: Column(
        children: [
          // ── Status Filter Chips Bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Obx(() {
              final all = controller.allCount;
              final pending = controller.pendingCount;
              final fulfilled = controller.fulfilledCount;
              final cancelled = controller.cancelledCount;
              final current = controller.selectedStatus.value;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: current == null,
                      label: Text('${'all'.tr} ($all)'),
                      showCheckmark: false,
                      onSelected: (_) => controller.selectedStatus.value = null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      selected: current == OrderStatus.pending,
                      avatar: Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: current == OrderStatus.pending
                            ? theme.colorScheme.onSecondaryContainer
                            : Colors.orange.shade800,
                      ),
                      label: Text('${'pending'.tr} ($pending)'),
                      showCheckmark: false,
                      onSelected: (v) => controller.selectedStatus.value =
                          v ? OrderStatus.pending : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      selected: current == OrderStatus.fulfilled,
                      avatar: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: current == OrderStatus.fulfilled
                            ? theme.colorScheme.onSecondaryContainer
                            : Colors.green.shade700,
                      ),
                      label: Text('${'fulfilled'.tr} ($fulfilled)'),
                      showCheckmark: false,
                      onSelected: (v) => controller.selectedStatus.value =
                          v ? OrderStatus.fulfilled : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      selected: current == OrderStatus.cancelled,
                      avatar: Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: current == OrderStatus.cancelled
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.error,
                      ),
                      label: Text('${'cancelled'.tr} ($cancelled)'),
                      showCheckmark: false,
                      onSelected: (v) => controller.selectedStatus.value =
                          v ? OrderStatus.cancelled : null,
                    ),
                  ],
                ),
              );
            }),
          ),
          const Divider(height: 1),

          // ── Orders List ────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final items = controller.visibleOrders;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'noOrdersYet'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text('addNewOrder'.tr),
                          onPressed: () => _openAddSheet(context),
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
                itemBuilder: (context, index) => _OrderCard(
                  order: items[index],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'order_fab',
        icon: const Icon(Icons.add),
        label: Text('addNewOrder'.tr),
        onPressed: () => _openAddSheet(context),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OrderFormSheet(),
    );
  }
}

/// Bottom Sheet for creating a new Order with Calendar Date Picker.
class _OrderFormSheet extends StatefulWidget {
  const _OrderFormSheet();

  @override
  State<_OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<_OrderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCustomerId;
  DateTime? _neededByDate;
  bool _isSaving = false;

  OrderController get controller => Get.find<OrderController>();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _neededByDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _neededByDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('selectCustomer'.tr),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final ok = await controller.createOrder(
      customerId: _selectedCustomerId!,
      itemDescription: _descriptionController.text.trim(),
      requestedDate: DateTime.now(),
      neededByDate: _neededByDate,
    );
    setState(() => _isSaving = false);

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('orderSaved'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final formattedDate = _neededByDate != null
        ? DateFormat('d MMM yyyy').format(_neededByDate!)
        : 'selectDeliveryDate'.tr;
    final daysRemaining = _neededByDate?.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'addNewOrder'.tr,
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

                  // ── Customer Dropdown ──────────────────────────────────
                  Obx(() {
                    final customerList = controller.customers;
                    final isMatched = customerList.any(
                      (c) => c.id == _selectedCustomerId,
                    );
                    final safeValue = isMatched ? _selectedCustomerId : null;

                    return DropdownButtonFormField<String>(
                      initialValue: safeValue,
                      decoration: InputDecoration(
                        labelText: 'customerName'.tr,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      items: [
                        for (final c in customerList)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.contact != null && c.contact!.isNotEmpty
                                  ? '${c.name} (${c.contact})'
                                  : c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedCustomerId = v),
                      validator: (v) => v == null ? 'nameRequired'.tr : null,
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),

                  // ── Item Description ───────────────────────────────────
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: 'itemOrServiceDescription'.tr,
                      hintText: 'itemDescriptionHint'.tr,
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.assignment_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'nameRequired'.tr
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Needed By Date (Date Picker Card) ───────────────────
                  InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _neededByDate != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : theme.colorScheme.outline.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: _neededByDate != null
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'expectedDeliveryDate'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _neededByDate != null
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (daysRemaining != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                daysRemaining > 0
                                    ? '$daysRemaining ${'daysLater'.tr}'
                                    : (daysRemaining == 0
                                        ? 'today'.tr
                                        : 'overdue'.tr),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          if (_neededByDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              tooltip: 'clear'.tr,
                              onPressed: () =>
                                  setState(() => _neededByDate = null),
                            )
                          else
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Error Message
                  Obx(
                    () => controller.errorMessage.value == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              controller.errorMessage.value!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                  ),

                  // ── Save Button ────────────────────────────────────────
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'save'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

/// Clean and professional Order Card with customer avatar, details, and action buttons.
class _OrderCard extends GetView<OrderController> {
  final Order order;
  const _OrderCard({required this.order});

  Future<void> _makeCall(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = controller.customerFor(order.customerId);
    final customerName = customer?.name ?? controller.customerName(order.customerId);
    final contact = customer?.contact;

    return Dismissible(
      key: ValueKey(order.id),
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
      onDismissed: (_) => controller.deleteOrder(order.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Customer Avatar, Name, Phone & Status Badge ─────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _customerAvatar(context, customer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contact != null && contact.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => _makeCall(contact),
                            borderRadius: BorderRadius.circular(4),
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
                                  contact,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _statusBadge(context),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // ── Item Description ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.itemDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Date Info (Requested & Needed By) ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM yyyy').format(order.requestedDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (order.neededByDate != null) _neededByBadge(context),
                ],
              ),

              // ── Action Buttons for Pending Orders ─────────────────────────
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text('markCancelled'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () async {
                          final ok = await controller.markCancelled(order.id);
                          if (ok) {
                            Get.snackbar(
                              'orderCancelled'.tr,
                              order.itemDescription,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('markFulfilled'.tr),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () async {
                          final ok = await controller.markFulfilled(order.id);
                          if (ok) {
                            Get.snackbar(
                              'orderFulfilled'.tr,
                              order.itemDescription,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
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

  Widget _customerAvatar(BuildContext context, Customer? customer) {
    final theme = Theme.of(context);
    final image = customer == null ? null : controller.primaryImageFor(customer.id);
    final source = image == null ? null : controller.imageSourceFor(image);

    final initial = customer?.name.trim().isEmpty ?? true
        ? '?'
        : customer!.name.trim().characters.first.toUpperCase();
    final fallbackAvatar = CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
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
        title: customer?.name ?? '',
        subtitle: customer?.contact,
        heroTag: 'order_avatar_${order.id}',
      ),
      child: Hero(
        tag: 'order_avatar_${order.id}',
        child: SafeImage(
          source: source,
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          fallbackWidget: fallbackAvatar,
        ),
      ),
    );
  }

  Widget _neededByBadge(BuildContext context) {
    final theme = Theme.of(context);
    final neededDate = order.neededByDate!;
    final now = DateTime.now();
    final isPending = order.status == OrderStatus.pending;
    final isOverdue = isPending && now.isAfter(neededDate);
    final daysDiff = neededDate.difference(now).inDays;

    final formatted = DateFormat('d MMM yyyy').format(neededDate);

    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 13,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              '$formatted · ${'orderOverdueLabel'.tr}',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_outlined,
            size: 13,
            color: isPending
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            isPending && daysDiff > 0
                ? '$formatted ($daysDiff ${'daysRemaining'.tr})'
                : formatted,
            style: TextStyle(
              color: isPending
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, onColor) = switch (order.status) {
      OrderStatus.pending => (
        'pending'.tr,
        Colors.orange.shade50,
        Colors.orange.shade900,
      ),
      OrderStatus.fulfilled => (
        'fulfilled'.tr,
        Colors.green.shade50,
        Colors.green.shade900,
      ),
      OrderStatus.cancelled => (
        'cancelled'.tr,
        scheme.errorContainer.withValues(alpha: 0.6),
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onColor,
          fontSize: 12,
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
        content: Text('deleteOrderConfirm'.tr),
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
