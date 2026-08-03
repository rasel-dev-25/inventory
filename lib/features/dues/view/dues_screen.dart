import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/database/app_database.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/dues_controller.dart';

class DuesScreen extends GetView<DuesController> {
  final VoidCallback? onMenuTap;
  const DuesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1, color: Colors.white),
          onPressed:
              onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
        ),
        foregroundColor: Colors.white,
        title: shopLogo(size: 18, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: controller.pickDate,
          ),
          Obx(
            () => controller.selectedDate.value != null
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.white),
                    onPressed: controller.clearDateFilter,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSummaryBar(),
              _buildCustomerHeader(),
              Expanded(child: Obx(() => _buildCustomerList())),
            ],
          ),
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              bottom: controller.showForm.value ? 0 : -600,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  child: _buildAddForm(),
                ),
              ),
            ),
          ),
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
    );
  }

  Widget _buildSummaryBar() {
    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: kTealDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _summaryItem('todayDue'.tr, controller.todayDue.value),
            _summaryItem('monthlyDue'.tr, controller.monthlyDue.value),
            _summaryItem(
              controller.selectedDate.value != null
                  ? 'filteredDue'.tr
                  : 'totalDue'.tr,
              controller.totalDue.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          '৳${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kTeal, width: 3)),
      ),
      child: Obx(
        () => Row(
          children: [
            Icon(Iconsax.people, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              '${'customers'.tr} (${controller.filteredCustomers.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    final list = controller.filteredCustomers;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.people, size: 40, color: kTeal),
            ),
            const SizedBox(height: 16),
            Text(
              'noCustomers'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _CustomerCard(customer: list[i]),
    );
  }

  Widget _buildAddForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 2,
        shadowColor: kTeal.withAlpha(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  GetBuilder<DuesController>(
                    builder: (c) => GestureDetector(
                      onTap: c.pickCustomerImage,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: kTeal.withValues(alpha: 0.12),
                        backgroundImage: c.customerImage != null
                            ? FileImage(c.customerImage!)
                            : null,
                        child: c.customerImage == null
                            ? const Icon(Iconsax.camera, color: kTeal)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: controller.nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'customerName'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'mobile'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.productSearchCtrl,
                onChanged: controller.searchProducts,
                decoration: InputDecoration(
                  hintText: 'searchProductAdd'.tr,
                  prefixIcon: const Icon(Iconsax.search_normal),
                  border: const OutlineInputBorder(),
                ),
              ),
              Obx(
                () => controller.filteredProducts.isNotEmpty
                    ? Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: controller.filteredProducts.length,
                          itemBuilder: (ctx, i) {
                            final p = controller.filteredProducts[i];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Iconsax.box,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                '${'sell'.tr}: ৳${p.sellPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => controller.selectProduct(p),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Selected product chip
              Obx(
                () => controller.selectedProduct.value != null
                    ? Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.tick_circle,
                              size: 16,
                              color: kTeal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${'selected'.tr}${controller.selectedProduct.value!.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: kTeal,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                controller.selectedProduct.value = null;
                                controller.productSearchCtrl.clear();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'dueAmount'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.noteCtrl,
                decoration: InputDecoration(
                  labelText: 'noteOptional'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.addDueCustomer,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: kTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'addToDues'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends GetView<DuesController> {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: controller.getOutstanding(customer.id),
      builder: (ctx, snap) {
        final outstanding = snap.data ?? 0.0;
        final color = outstanding <= 0
            ? Colors.green
            : outstanding < 500
            ? Colors.orange
            : outstanding < 1000
            ? Colors.deepOrange
            : Colors.red;
        final bgColor = outstanding <= 0
            ? Colors.green.shade50
            : outstanding < 500
            ? Colors.orange.shade50
            : outstanding < 1000
            ? Colors.deepOrange.shade50
            : Colors.red.shade50;
        final hasImage =
            customer.imagePath.isNotEmpty &&
            File(customer.imagePath).existsSync();

        return Card(
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetail(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: bgColor,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(File(customer.imagePath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : const Icon(
                            Iconsax.profile,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Iconsax.call,
                              size: 11,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: outstanding <= 0
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            outstanding <= 0 ? 'settled'.tr : 'due'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: outstanding <= 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${outstanding.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Iconsax.edit,
                              size: 16,
                              color: kTeal,
                            ),
                            onPressed: () => _showEditDialog(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Iconsax.eye,
                              size: 16,
                              color: kTeal,
                            ),
                            onPressed: _showDetail,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
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
      },
    );
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    Get.dialog(
      AlertDialog(
        title: Text(
          'editCustomer'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'customerName'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'mobile'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.editCustomer(
                customer,
                nameCtrl.text,
                phoneCtrl.text,
                null,
              );
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _showDetail() {
    Get.dialog(_CustomerDetailDialog(customer: customer));
  }
}

class _CustomerDetailDialog extends GetView<DuesController> {
  final Customer customer;
  const _CustomerDetailDialog({required this.customer});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LedgerEntry>>(
      future: controller.getLedger(customer.id),
      builder: (ctx, snap) {
        final ledger = snap.data ?? [];
        double totalDue = 0, totalPaid = 0;
        for (final e in ledger) {
          if (e.type == 'due')
            totalDue += e.amount;
          else
            totalPaid += e.amount;
        }
        final balance = totalDue - totalPaid;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: kTeal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Iconsax.call, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    customer.phone,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: balance <= 0
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: balance <= 0
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      balance <= 0 ? Iconsax.tick_circle : Iconsax.warning_2,
                      size: 16,
                      color: balance <= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      balance <= 0
                          ? 'allSettled'.tr
                          : '${'outstanding'.tr}৳${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: balance <= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: kTeal, width: 3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.receipt, size: 16, color: kTeal),
                      const SizedBox(width: 6),
                      Text(
                        'ledgerEntries'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (ledger.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'noLedgerEntries'.tr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...ledger.map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: entry.type == 'due'
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: entry.type == 'due'
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: entry.type == 'due'
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              entry.type == 'due'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: entry.type == 'due'
                                  ? Colors.red
                                  : Colors.green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (entry.itemName.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      entry.itemName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '৳${entry.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: entry.type == 'due'
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Monthly payback
                FutureBuilder<double>(
                  future: controller.getMonthlyPayback(customer.id),
                  builder: (ctx, snap) {
                    final mp = snap.data ?? 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${'monthlyPayback'.tr}:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          Text(
                            '৳${mp.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.paymentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'paymentAmount'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Iconsax.money, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
            ElevatedButton.icon(
              onPressed: () {
                final amt = double.tryParse(controller.paymentCtrl.text) ?? 0;
                if (amt > 0) {
                  controller.receivePayment(customer, amt);
                  Get.back();
                }
              },
              icon: const Icon(Iconsax.card, size: 18),
              label: Text('receivePayment'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
