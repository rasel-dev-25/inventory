import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';

class CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final CustomersController? controllerOverride;

  const CustomerDetailSheet({
    super.key,
    required this.customer,
    required this.onEdit,
    this.controllerOverride,
  });

  @override
  Widget build(BuildContext context) {
    final controller = controllerOverride ?? Get.find<CustomersController>();
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (context, scrollController) => Obx(() {
          final sales = controller.salesFor(customer.id);
          final dues = controller.duesFor(customer.id);
          final rentals = controller.rentalsFor(customer.id);
          final orders = controller.ordersFor(customer.id);
          final totalSales = sales.fold(
            0,
            (sum, sale) => sum + (sale.actualSellPrice * sale.qty).minorUnits,
          );
          final outstanding = dues.fold(
            0,
            (sum, due) =>
                sum + due.originalAmount.minorUnits - due.paidAmount.minorUnits,
          );

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'edit'.tr,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              if (customer.contact != null || customer.address != null)
                Text(
                  [
                    if (customer.contact != null) customer.contact!,
                    if (customer.address != null) customer.address!,
                  ].join(' - '),
                ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _SummaryCard(
                    label: 'customerTotalPurchases'.tr,
                    value: _money(totalSales),
                  ),
                  _SummaryCard(
                    label: 'customerOutstandingDue'.tr,
                    value: _money(outstanding),
                  ),
                  _SummaryCard(
                    label: 'customerRentCount'.tr,
                    value: '${rentals.length}',
                  ),
                  _SummaryCard(
                    label: 'customerOrderCount'.tr,
                    value: '${orders.length}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _HistorySection(
                title: 'customerPurchaseHistory'.tr,
                emptyText: 'noCustomerPurchases'.tr,
                children: sales.map((sale) {
                  final product = controller.productFor(sale.productId);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(product?.name ?? sale.productId),
                    subtitle: Text('${_date(sale.date)} - ${sale.qty}'),
                    trailing: Text(
                      _money((sale.actualSellPrice * sale.qty).minorUnits),
                    ),
                  );
                }).toList(),
              ),
              _HistorySection(
                title: 'customerDueHistory'.tr,
                emptyText: 'noCustomerDues'.tr,
                children: dues.map((due) {
                  final remaining =
                      due.originalAmount.minorUnits - due.paidAmount.minorUnits;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(
                      '${due.sourceType.name.tr} - ${due.status.name.tr}',
                    ),
                    subtitle: Text(_date(due.createdAt)),
                    trailing: Text(_money(remaining)),
                  );
                }).toList(),
              ),
              _HistorySection(
                title: 'customerRentHistory'.tr,
                emptyText: 'noCustomerRentals'.tr,
                children: rentals.map((rent) {
                  final product = controller.productFor(rent.bookProductId);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(product?.name ?? rent.bookProductId),
                    subtitle: Text(
                      '${_date(rent.startDate)} - ${rent.status.name.tr}',
                    ),
                    trailing: Text(_money(rent.rentPrice.minorUnits)),
                  );
                }).toList(),
              ),
              _HistorySection(
                title: 'customerOrderHistory'.tr,
                emptyText: 'noCustomerOrders'.tr,
                children: orders.map((order) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(order.itemDescription),
                    subtitle: Text(
                      '${_date(order.requestedDate)} - ${order.status.name.tr}',
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ),
    );
  }

  static String _date(DateTime date) =>
      DateFormat('d MMM y').format(date.toLocal());

  static String _money(int minorUnits) => Money.fromMinor(minorUnits).format();
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Widget> children;

  const _HistorySection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(emptyText),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}
