import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design/tokens.dart';
import '../../../../domain/entities/sale.dart';
import '../../controller/daily_sales_controller.dart';
import 'edit_sale_sheet.dart';
import 'sale_card.dart';

/// List of sales recorded on the selected date.
class DailySalesList extends StatelessWidget {
  final DailySalesController controller;
  final VoidCallback onAddSale;

  const DailySalesList({
    required this.controller,
    required this.onAddSale,
    super.key,
  });

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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditSaleSheet(sale: sale),
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
            SaleCard(
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
