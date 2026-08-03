import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/database/app_database.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/finance_controller.dart';

class FinanceScreen extends GetView<FinanceController> {
  final VoidCallback? onMenuTap;
  const FinanceScreen({super.key, this.onMenuTap});

  static const _expenseCategories = [
    'Shop',
    'Rent',
    'Bill',
    'Utilities',
    'Groceries',
    'Transport',
    'Office Supplies',
    'Marketing',
    'Staff Salary',
    'Maintenance',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.menu_1, color: Colors.white),
            onPressed:
                onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
          ),
          backgroundColor: kTeal,
          title: shopLogo(size: 20, color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'expenses'.tr),
              Tab(text: 'purchases'.tr),
              Tab(text: 'overview'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExpensesTab(),
            _buildPurchasesTab(),
            _buildSummaryTab(),
          ],
        ),
        floatingActionButton: Obx(
          () => FloatingActionButton(
            backgroundColor: kTeal,
            foregroundColor: Colors.white,
            onPressed: () => controller.showForm.toggle(),
            child: Icon(
              controller.showForm.value ? Iconsax.close_circle : Iconsax.add,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== EXPENSES TAB ====================
  Widget _buildExpensesTab() {
    return Stack(
      children: [
        Obx(
          () => controller.expenses.isEmpty
              ? Center(
                  child: Text(
                    'noLabel'.tr,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = controller.expenses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e.isPaid
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            e.isPaid ? Iconsax.tick_circle : Iconsax.warning_2,
                            color: e.isPaid ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          e.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${e.vendor.isNotEmpty ? "${e.vendor} • " : ""}${e.type} • ${e.date}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${e.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kTeal,
                              ),
                            ),
                            if (!e.isPaid)
                              GestureDetector(
                                onTap: () => controller.markExpensePaid(e.id),
                                child: Text(
                                  'markAsPaid'.tr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onLongPress: () => _expenseActions(e),
                      ),
                    );
                  },
                ),
        ),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: controller.showForm.value ? 0 : -800,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: Get.height * 0.8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _buildExpenseForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'newExpense'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTeal,
              ),
            ),
            const SizedBox(height: 14),
            // Category dropdown
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.expCategory.value,
                decoration: InputDecoration(
                  labelText: 'category'.tr,
                  border: const OutlineInputBorder(),
                ),
                items: _expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.expCategory.value = v;
                },
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.expVendor,
              decoration: InputDecoration(
                labelText: 'vendorPayee'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.expAmount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'amount'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.expNote,
              decoration: InputDecoration(
                labelText: 'descriptionNote'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // Payment method + Recurring
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.expPaymentMethod.value,
                      decoration: InputDecoration(
                        labelText: 'paymentMethod'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      items: ['Cash', 'Bank', 'BKash', 'Card']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.expPaymentMethod.value = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.expRecurring.value,
                      decoration: InputDecoration(
                        labelText: 'recurring'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      items: ['none', 'daily', 'monthly']
                          .map(
                            (r) =>
                                DropdownMenuItem(value: r, child: Text(r.tr)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.expRecurring.value = v;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Is Paid toggle
            Obx(
              () => SwitchListTile(
                title: Text(
                  'markAsPaid'.tr,
                  style: const TextStyle(fontSize: 14),
                ),
                value: controller.expIsPaid.value,
                activeThumbColor: Colors.green,
                onChanged: (v) => controller.expIsPaid.value = v,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Bill image
            const SizedBox(height: 6),
            GetBuilder<FinanceController>(
              builder: (c) => Row(
                children: [
                  GestureDetector(
                    onTap: c.pickBillImage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                      ),
                      child: c.billFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(c.billFile!, fit: BoxFit.cover),
                            )
                          : Icon(
                              Iconsax.camera,
                              color: kTeal.withValues(alpha: 0.6),
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.billFile != null ? 'photoTaken'.tr : 'addPhoto'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.billFile != null
                          ? Colors.green
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.addExpense('misc'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text('save'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _expenseActions(Expense e) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.edit, color: kTeal),
                title: Text('edit'.tr),
                onTap: () {
                  Get.back();
                  _editExpense(e);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: Text(
                  'delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  controller.deleteExpense(e.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editExpense(Expense e) {
    final titleCtrl = TextEditingController(text: e.title);
    final amountCtrl = TextEditingController(text: e.amount.toString());
    final vendorCtrl = TextEditingController(text: e.vendor);
    final noteCtrl = TextEditingController(text: e.note);
    Get.dialog(
      AlertDialog(
        title: Text('editExpense'.tr, style: const TextStyle(color: kTeal)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'category'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vendorCtrl,
                decoration: InputDecoration(
                  labelText: 'vendor'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'descriptionNote'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.updateExpense(
                e.id,
                title: titleCtrl.text,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                vendor: vendorCtrl.text,
                note: noteCtrl.text,
              );
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  // ==================== PURCHASES TAB ====================
  Widget _buildPurchasesTab() {
    return Stack(
      children: [
        Obx(
          () => controller.purchases.isEmpty
              ? Center(
                  child: Text(
                    'noLabel'.tr,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.purchases.length,
                  itemBuilder: (ctx, i) {
                    final p = controller.purchases[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.shopping_cart,
                            color: kTeal,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.date,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${p.source != 'cash' ? "Investor • " : ""}${'cashTaken'.tr}: ৳${p.cashTaken.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          '৳${(p.cashTaken - p.returnedCash).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kTeal,
                          ),
                        ),
                        onLongPress: () => controller.deletePurchase(p.id),
                      ),
                    );
                  },
                ),
        ),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: controller.showForm.value ? 0 : -1200,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: Get.height * 0.85),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _buildPurchaseForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'newPurchase'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTeal,
              ),
            ),
            const SizedBox(height: 14),
            // Source dropdown
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.purSource.value,
                decoration: InputDecoration(
                  labelText: 'cashFrom'.tr,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text('cash'.tr)),
                  ...controller.investorNames.map(
                    (name) => DropdownMenuItem(
                      value: 'investor:$name',
                      child: Text('${'investor'.tr}: $name'),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) controller.purSource.value = v;
                },
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.purCashTaken,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'cashTaken'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            // --- Items section ---
            _sectionLabel('items'.tr),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.purItemShop,
                    decoration: InputDecoration(
                      labelText: 'shop'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.purItemName,
                    decoration: InputDecoration(
                      labelText: 'item'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.purItemQty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'qty'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.purItemPrice,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'price'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, color: kTeal, size: 28),
                  onPressed: controller.addTempItem,
                ),
              ],
            ),
            Obx(
              () => Column(
                children: controller.tempItems
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${entry.value.shopName} - ${entry.value.itemName}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '৳${(entry.value.quantity * entry.value.unitPrice).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  controller.removeTempItem(entry.key),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            // --- Transport costs section ---
            _sectionLabel('transportCosts'.tr),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.purVehicle,
                    decoration: InputDecoration(
                      labelText: 'vehicle'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.purCost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'cost'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, color: kTeal, size: 28),
                  onPressed: controller.addTempTransport,
                ),
              ],
            ),
            Obx(
              () => Column(
                children: controller.tempTransport
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value.vehicle,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '৳${entry.value.cost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  controller.removeTempTransport(entry.key),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            // --- Other costs section ---
            _sectionLabel('otherCosts'.tr),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.purOtherDesc,
                    decoration: InputDecoration(
                      labelText: 'description'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.purOtherCost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'cost'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, color: kTeal, size: 28),
                  onPressed: controller.addTempOtherCost,
                ),
              ],
            ),
            Obx(
              () => Column(
                children: controller.tempOtherCosts
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '৳${entry.value.cost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  controller.removeTempOtherCost(entry.key),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Returned cash
            TextField(
              controller: controller.purReturnedCash,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'returnedCash'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // Memo photo
            GetBuilder<FinanceController>(
              builder: (c) => Row(
                children: [
                  GestureDetector(
                    onTap: c.pickPurMemo,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                      ),
                      child: c.purMemoFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(
                                c.purMemoFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Iconsax.camera,
                              color: kTeal.withValues(alpha: 0.6),
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.purMemoFile != null
                        ? 'cashMemoAttached'.tr
                        : 'addPhoto'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.purMemoFile != null
                          ? Colors.green
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.purNotes,
              decoration: InputDecoration(
                labelText: 'notes'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            // --- Totals breakdown ---
            Obx(
              () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kTeal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _totalRow('itemsTotal'.tr, controller.itemsTotal),
                    const SizedBox(height: 4),
                    _totalRow('transportTotal'.tr, controller.transportTotal),
                    const SizedBox(height: 4),
                    _totalRow('otherCostsTotal'.tr, controller.otherTotal),
                    const Divider(height: 12),
                    _totalRow(
                      'grandTotal'.tr,
                      controller.grandTotal,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.savePurchase,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'savePurchase'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kTeal, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: kTeal,
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 14 : 12,
          ),
        ),
        Text(
          '৳${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 16 : 13,
            color: bold ? kTeal : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ==================== SUMMARY TAB ====================
  Widget _buildSummaryTab() {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(
              'expenses'.tr,
              controller.totalExpenses,
              Iconsax.receipt,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _summaryCard(
              'purchases'.tr,
              controller.totalPurchases,
              Iconsax.shopping_cart,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _summaryCard(
              'grandTotal'.tr,
              controller.totalExpenses + controller.totalPurchases,
              Iconsax.chart,
              kTeal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '৳${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
