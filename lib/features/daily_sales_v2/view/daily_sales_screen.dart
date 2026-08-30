import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/platform/capabilities.dart';
import '../../../core/widgets/barcode_scanner_view.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/barcode_lookup.dart';
import '../controller/daily_sales_controller.dart';

/// Backs the Daily Sales screen — clean date-navigated daily sales history,
/// cash vs. due breakdown for every transaction, daily performance metrics,
/// and a modal bottom-sheet sale entry flow.
class DailySalesScreen extends GetView<DailySalesController> {
  final VoidCallback? onMenuTap;

  const DailySalesScreen({super.key, this.onMenuTap});

  void _showAddSaleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SaleFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'dailySales'.tr),
        leading: onMenuTap == null
            ? null
            : IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        actions: [
          IconButton(
            tooltip: 'addSale'.tr,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddSaleSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSaleSheet(context),
        icon: const Icon(Icons.add),
        label: Text('addSale'.tr),
      ),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                const SizedBox(height: AppSpacing.md),
                Text('noProductsYet'.tr, style: const TextStyle(fontSize: 16)),
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
              80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateNavigator(controller: controller),
                const SizedBox(height: AppSpacing.sm),
                _DailySummaryMetrics(controller: controller),
                const SizedBox(height: AppSpacing.md),
                _DailySalesList(
                  controller: controller,
                  onAddSale: () => _showAddSaleSheet(context),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Date picker and day navigation bar (Previous, Date Picker, Next, Today).
class _DateNavigator extends StatelessWidget {
  final DailySalesController controller;

  const _DateNavigator({required this.controller});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final selected = controller.selectedDate.value;
      final isToday = controller.isToday;
      final dateStr = DateFormat.yMMMd().format(selected);

      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Day',
                onPressed: controller.previousDay,
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pickDate(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isToday ? '$dateStr (${'today'.tr})' : dateStr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Day',
                onPressed: controller.nextDay,
              ),
              if (!isToday)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: controller.goToToday,
                  child: Text('today'.tr, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Metric summary cards for total sales, cash received, due sales, and net profit for the selected date.
class _DailySummaryMetrics extends StatelessWidget {
  final DailySalesController controller;

  const _DailySummaryMetrics({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalSales = controller.totalSalesAmount;
      final totalCash = controller.totalCashAmount;
      final totalDue = controller.totalDueAmount;
      final totalProfit = controller.totalProfitAmount;
      final totalUnits = controller.totalUnitsSold;
      final txCount = controller.totalTransactionsCount;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  title: 'totalSales'.tr,
                  value: totalSales.format(),
                  subtitle: '$txCount (${totalUnits.toStringAsFixed(totalUnits == totalUnits.roundToDouble() ? 0 : 1)} ${'unitPcs'.tr})',
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricCard(
                  context,
                  title: 'totalProfit'.tr,
                  value: totalProfit.format(),
                  subtitle: totalProfit.isNegative ? 'Loss' : 'Net Profit',
                  icon: Icons.trending_up,
                  color: totalProfit.isNegative ? Colors.red : Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  title: 'cashReceived'.tr,
                  value: totalCash.format(),
                  subtitle: 'Cash collected',
                  icon: Icons.payments_outlined,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricCard(
                  context,
                  title: 'dueSales'.tr,
                  value: totalDue.format(),
                  subtitle: 'Uncollected debt',
                  icon: Icons.credit_card_outlined,
                  color: totalDue.isPositive ? Colors.orange.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of sales recorded on the selected date.
class _DailySalesList extends StatelessWidget {
  final DailySalesController controller;
  final VoidCallback onAddSale;

  const _DailySalesList({required this.controller, required this.onAddSale});

  void _showSaleDetails(BuildContext context, Sale sale) {
    final product = controller.productById(sale.productId);
    final customer = controller.customerById(sale.customerId);
    final saleTotal = sale.actualSellPrice * sale.qty;
    final totalCost = sale.costPriceAtSale * sale.qty;
    final profit = saleTotal - totalCost;
    final cashReceived = controller.cashReceivedForSale(sale);
    final dueAmount = controller.dueAmountForSale(sale);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? sale.productId,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            _receiptRow('quantity'.tr, '${sale.qty.toStringAsFixed(sale.qty == sale.qty.roundToDouble() ? 0 : 2)} ${'unitPcs'.tr}'),
            _receiptRow('sellPriceLabel'.tr, sale.actualSellPrice.format()),
            _receiptRow('costLabel'.tr, sale.costPriceAtSale.format()),
            const Divider(),
            _receiptRow('total'.tr, saleTotal.format(), isBold: true),
            _receiptRow('cashReceived'.tr, cashReceived.format(), color: Colors.green.shade700, isBold: true),
            if (dueAmount.isPositive)
              _receiptRow('dueLabel'.tr, dueAmount.format(), color: Colors.red.shade700, isBold: true),
            _receiptRow(
              'profit'.tr,
              '+ ${profit.format()}',
              color: profit.isNegative ? Colors.red : Colors.teal.shade700,
              isBold: true,
            ),
            _receiptRow('paymentStatus'.tr, sale.paymentStatus.name.tr),
            _receiptRow('paymentMethod'.tr, sale.paymentMethod.name.tr),
            if (customer != null) _receiptRow('customer'.tr, customer.name),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteSale(context, sale);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showEditSaleSheet(context, sale);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text('editSale'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSale(BuildContext context, Sale sale) async {
    final product = controller.productById(sale.productId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${'delete'.tr} ${product?.name ?? 'sale'.tr}?'),
        content: Text('deleteSaleConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await controller.deleteSale(sale.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'saleDeleted'.tr
                  : (controller.errorMessage.value ?? 'Operation failed'),
            ),
          ),
        );
      }
    }
  }

  void _showEditSaleSheet(BuildContext context, Sale sale) {
    final product = controller.productById(sale.productId);
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController(
      text: sale.qty.toStringAsFixed(sale.qty == sale.qty.roundToDouble() ? 0 : 2),
    );
    final priceController = TextEditingController(
      text: sale.actualSellPrice.format(showSymbol: false),
    );
    final receivedController = TextEditingController(
      text: controller.cashReceivedForSale(sale).format(showSymbol: false),
    );
    final promisedDaysController = TextEditingController();
    String? selectedCustomerId = sale.customerId;
    PaymentMethod paymentMethod = sale.paymentMethod;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setState) {
          final qty = double.tryParse(qtyController.text) ?? sale.qty;
          final price = _parseMoneyOrNull(priceController.text) ?? sale.actualSellPrice;
          final total = price * qty;
          final received = _parseMoneyOrNull(receivedController.text) ?? total;
          final due = total - received;

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'editSale'.tr,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product?.name ?? sale.productId,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'quantity'.tr,
                              suffixText: 'unitPcs'.tr,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final p = double.tryParse(v ?? '');
                              if (p == null || p <= 0) return 'invalidQty'.tr;
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'sellPriceLabel'.tr,
                              prefixText: '৳ ',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'nameRequired'.tr;
                              try {
                                Money.parse(v);
                                return null;
                              } catch (_) {
                                return 'invalidQty'.tr;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: receivedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'amountReceived'.tr,
                        prefixText: '৳ ',
                        helperText: due.isPositive
                            ? '${'due'.tr}: ${due.format()}'
                            : 'fullCash'.tr,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (due.isPositive) ...[
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomerId,
                        decoration: InputDecoration(labelText: 'customerName'.tr),
                        items: [
                          for (final c in controller.customers)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => selectedCustomerId = v),
                        validator: (v) => v == null ? 'nameRequired'.tr : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: promisedDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'enterDueDay'.tr),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: paymentMethod,
                      decoration: InputDecoration(labelText: 'paymentMethod'.tr),
                      items: [
                        for (final method in PaymentMethod.values)
                          DropdownMenuItem(
                            value: method,
                            child: Text(method.name.tr),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => paymentMethod = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await controller.editSale(
                          saleId: sale.id,
                          qty: double.parse(qtyController.text),
                          actualSellPrice: Money.parse(priceController.text),
                          amountReceivedNow: _parseMoneyOrNull(receivedController.text) ?? total,
                          paymentMethod: paymentMethod,
                          customerId: selectedCustomerId,
                          promisedDays: int.tryParse(promisedDaysController.text),
                        );
                        if (ok && context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('saleUpdated'.tr)),
                          );
                        }
                      },
                      child: Text('save'.tr),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sales = controller.salesForSelectedDate;
      if (sales.isEmpty) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.point_of_sale_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'noSalesOnDate'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onAddSale,
                  icon: const Icon(Icons.add),
                  label: Text('addSale'.tr),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'sales'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${sales.length} ${'itemsSold'.tr}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final sale in sales)
            _SaleCard(
              sale: sale,
              productName: controller.productById(sale.productId)?.name ?? sale.productId,
              customerName: controller.customerById(sale.customerId)?.name,
              cashReceived: controller.cashReceivedForSale(sale),
              dueAmount: controller.dueAmountForSale(sale),
              onTap: () => _showSaleDetails(context, sale),
              onEdit: () => _showEditSaleSheet(context, sale),
              onDelete: () => _confirmDeleteSale(context, sale),
            ),
        ],
      );
    });
  }
}

/// Transaction card with crystal-clear Cash vs Due breakdown badges.
class _SaleCard extends StatelessWidget {
  final Sale sale;
  final String productName;
  final String? customerName;
  final Money cashReceived;
  final Money dueAmount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SaleCard({
    required this.sale,
    required this.productName,
    this.customerName,
    required this.cashReceived,
    required this.dueAmount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = sale.actualSellPrice * sale.qty;
    final profit = (sale.actualSellPrice - sale.costPriceAtSale) * sale.qty;
    final isCash = sale.paymentStatus == PaymentStatus.fullCash;
    final isDue = sale.paymentStatus == PaymentStatus.fullDue;
    final isPartial = sale.paymentStatus == PaymentStatus.partial;

    final Color badgeBg;
    final Color badgeText;
    final IconData statusIcon;

    if (isCash) {
      badgeBg = Colors.green.withValues(alpha: 0.12);
      badgeText = Colors.green.shade800;
      statusIcon = Icons.check_circle_outline;
    } else if (isPartial) {
      badgeBg = Colors.orange.withValues(alpha: 0.14);
      badgeText = Colors.orange.shade900;
      statusIcon = Icons.timelapse_outlined;
    } else {
      badgeBg = Colors.red.withValues(alpha: 0.12);
      badgeText = Colors.red.shade800;
      statusIcon = Icons.pending_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCash
              ? Colors.grey.withValues(alpha: 0.15)
              : (isPartial ? Colors.orange.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: badgeText, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (customerName != null && customerName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 12, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  customerName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${sale.qty.toStringAsFixed(sale.qty == sale.qty.roundToDouble() ? 0 : 2)} ${'unitPcs'.tr} × ${sale.actualSellPrice.format()}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        total.format(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '+ ${profit.format()}',
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'details') onTap();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 18),
                            const SizedBox(width: 8),
                            Text('viewReceipt'.tr),
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
                            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Payment breakdown pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCash) ...[
                      Icon(Icons.check, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        '${'fullCash'.tr}: ${cashReceived.format()}',
                        style: TextStyle(fontSize: 11, color: badgeText, fontWeight: FontWeight.bold),
                      ),
                    ] else if (isPartial) ...[
                      Icon(Icons.payments_outlined, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        '${'cashReceived'.tr}: ${cashReceived.format()}  •  ${'dueLabel'.tr}: ${dueAmount.format()}',
                        style: TextStyle(fontSize: 11, color: badgeText, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Icon(Icons.warning_amber_rounded, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        '${'fullDue'.tr}: ${dueAmount.format()}',
                        style: TextStyle(fontSize: 11, color: badgeText, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet for creating a new Sale.
class _SaleFormSheet extends StatefulWidget {
  const _SaleFormSheet();

  @override
  State<_SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<_SaleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _selectedCategory;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _receivedController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _selectedCustomerId;
  final _promisedDaysController = TextEditingController();

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  DailySalesController get controller => Get.find<DailySalesController>();

  double get _qty => double.tryParse(_qtyController.text) ?? 1;
  Money? get _price => _parseMoneyOrNull(_priceController.text);
  Money? get _received => _parseMoneyOrNull(_receivedController.text);

  Money get _saleTotal => (_price ?? Money.zero()) * _qty;
  Money get _remaining => _saleTotal - (_received ?? _saleTotal);
  Money? get _grossProfitPreview {
    if (_selectedProduct == null || _price == null) return null;
    return (_price! - _selectedProduct!.costPrice) * _qty;
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final code = await showBarcodeScanner(context);
    if (code == null || !context.mounted) return;

    final product = findProductByBarcode(controller.products, code);
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('noProductForBarcode'.tr)));
      return;
    }

    setState(() {
      _selectedProduct = product;
      _selectedCategory = product.category;
      _searchController.text = product.name;
      _priceController.text = product.suggestedSellPrice.format(showSymbol: false);
      _receivedController.text = (product.suggestedSellPrice * _qty).format(showSymbol: false);
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _receivedController.dispose();
    _promisedDaysController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final total = (_price ?? Money.zero()) * _qty;
    final ok = await controller.logSale(
      productId: _selectedProduct!.id,
      qty: _qty,
      actualSellPrice: _price!,
      amountReceivedNow: _parseMoneyOrNull(_receivedController.text) ?? total,
      paymentMethod: _paymentMethod,
      customerId: _selectedCustomerId,
      promisedDays: int.tryParse(_promisedDaysController.text),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
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
                    'addSale'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(labelText: 'category'.tr),
                items: {
                  for (final product in controller.products) product.category,
                }.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedProduct = null;
                    _searchController.clear();
                  });
                },
                validator: (_) => _selectedCategory == null ? 'category'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Autocomplete<Product>(
                      textEditingController: _searchController,
                      focusNode: _searchFocusNode,
                      displayStringForOption: (p) => p.name,
                      optionsBuilder: (textValue) {
                        if (_selectedCategory == null) return const [];
                        final categoryProducts = controller.products.where(
                          (p) => p.category == _selectedCategory,
                        );
                        if (textValue.text.isEmpty) return categoryProducts;
                        final query = textValue.text.toLowerCase();
                        return categoryProducts.where(
                          (p) => p.name.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (product) {
                        setState(() {
                          _selectedProduct = product;
                          _priceController.text = product.suggestedSellPrice.format(showSymbol: false);
                          _receivedController.text = (product.suggestedSellPrice * _qty).format(showSymbol: false);
                        });
                      },
                      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
                        return TextFormField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'searchProductAdd'.tr,
                          ),
                          validator: (_) => _selectedProduct == null ? 'selectProduct'.tr : null,
                        );
                      },
                    ),
                  ),
                  if (PlatformCapabilities.detect().hasCamera)
                    IconButton(
                      tooltip: 'scanBarcodeTitle'.tr,
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _scanBarcode(context),
                    ),
                ],
              ),
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${'stockLabel'.tr}${_selectedProduct!.qty}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'quantity'.tr,
                        suffixText: 'unitPcs'.tr,
                      ),
                      onChanged: (_) {
                        setState(() {
                          if (_price != null) {
                            _receivedController.text = (_price! * _qty).format(showSymbol: false);
                          }
                        });
                      },
                      validator: (v) => (_qty <= 0) ? 'invalidQty'.tr : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'sellPriceLabel'.tr,
                        prefixText: '৳ ',
                      ),
                      onChanged: (_) {
                        setState(() {
                          if (_price != null) {
                            _receivedController.text = (_price! * _qty).format(showSymbol: false);
                          }
                        });
                      },
                      validator: (v) => (_price == null) ? 'invalidQty'.tr : null,
                    ),
                  ),
                ],
              ),
              if (_grossProfitPreview != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '${'profit'.tr}: ${_grossProfitPreview!.format()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _grossProfitPreview!.isNegative ? theme.colorScheme.error : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<PaymentMethod>(
                segments: [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('cash'.tr),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.mobileBanking,
                    label: Text('mobile'.tr),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.bankTransfer,
                    label: Text('bank'.tr),
                  ),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _receivedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'cashAmount'.tr,
                  prefixText: '৳ ',
                  helperText: _remaining.isPositive ? '${'dueAmount'.tr}: ${_remaining.format()}' : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_remaining.isPositive) ...[
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: InputDecoration(labelText: 'customerName'.tr),
                    items: [
                      for (final c in controller.customers) DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
                    validator: (v) => (_remaining.isPositive && v == null) ? 'nameRequired'.tr : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _promisedDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'enterDueDay'.tr),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Obx(() => errorMessageText(controller.errorMessage.value)),
              const SizedBox(height: AppSpacing.sm),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSaving.value ? null : _submit,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('completeSale'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget errorMessageText(String? message) {
  return SizedBox(
    height: 20,
    child: message == null
        ? null
        : Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
  );
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
