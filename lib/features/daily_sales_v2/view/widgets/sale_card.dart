import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/money/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/sale.dart';

/// Transaction card with crystal-clear Cash vs Due breakdown badges.
class SaleCard extends StatelessWidget {
  final Sale sale;
  final String productName;
  final String? customerName;
  final Money cashReceived;
  final Money dueAmount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SaleCard({
    required this.sale,
    required this.productName,
    required this.cashReceived,
    required this.dueAmount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.customerName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final total = sale.actualSellPrice * sale.qty;
    final profit = (sale.actualSellPrice - sale.costPriceAtSale) * sale.qty;
    final isCash = sale.paymentStatus == PaymentStatus.fullCash;
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
              : (isPartial
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3)),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (customerName != null && customerName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  customerName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${sale.qty.toStringAsFixed(sale.qty == sale.qty.roundToDouble() ? 0 : 2)} ${'unitPcs'.tr} × ${sale.actualSellPrice.format()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey,
                    ),
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
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'delete'.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (isPartial) ...[
                      Icon(
                        Icons.payments_outlined,
                        size: 12,
                        color: badgeText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${'cashReceived'.tr}: ${cashReceived.format()}  •  ${'dueLabel'.tr}: ${dueAmount.format()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: badgeText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${'fullDue'.tr}: ${dueAmount.format()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                        ),
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
