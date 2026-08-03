import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/daily_sales_controller.dart';

class DailySalesScreen extends GetView<DailySalesController> {
  final VoidCallback? onMenuTap;
  const DailySalesScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.menu_1, color: Colors.white),
            onPressed:
                onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
          ),
          backgroundColor: kTeal,
          title: shopLogo(size: 20, color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.calendar, color: Colors.white),
              onPressed: controller.pickDate,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'sales'.tr),
              Tab(text: 'rent'.tr),
            ],
          ),
        ),
        body: TabBarView(children: [_buildSalesTab(), _buildRentTab()]),
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

  // --- Sales Tab ---
  Widget _buildSalesTab() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller.salesSearchCtrl,
                onChanged: (v) => controller.salesSearchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'searchSales'.tr,
                  prefixIcon: const Icon(Iconsax.search_normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = controller.filteredSales;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'noMatchingSales'.tr,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final s = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: s.type == 'cash'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            s.type == 'cash' ? Iconsax.money : Iconsax.card,
                            color: s.type == 'cash'
                                ? Colors.green
                                : Colors.orange,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          s.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          s.date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${s.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kTeal,
                              ),
                            ),
                            Text(
                              '+৳${s.profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        onLongPress: () => controller.deleteSale(s.id),
                      ),
                    );
                  },
                );
              }),
            ),
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
              constraints: BoxConstraints(maxHeight: Get.height * 0.6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _buildSaleForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'sell'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTeal,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller.productSearchCtrl,
              onChanged: controller.searchProducts,
              decoration: InputDecoration(
                hintText: 'searchProduct'.tr,
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
                            title: Text(
                              p.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '৳${p.sellPrice.toStringAsFixed(2)}/${p.sellUnit}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () => controller.selectProduct(p),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Selected product info
            Obx(
              () => controller.selectedProduct.value != null
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            color: kTeal,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${controller.selectedProduct.value!.name}  •  ৳${controller.selectedProduct.value!.sellPrice.toStringAsFixed(2)}/${controller.selectedProduct.value!.sellUnit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: kTeal,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Iconsax.close_circle,
                              size: 18,
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
            // Cash / Credit toggle
            Obx(
              () => Row(
                children: [
                  ChoiceChip(
                    label: Text('cash'.tr),
                    selected: !controller.isCredit.value,
                    onSelected: (_) => controller.isCredit.value = false,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: !controller.isCredit.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text('credit'.tr),
                    selected: controller.isCredit.value,
                    onSelected: (_) => controller.isCredit.value = true,
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: controller.isCredit.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Buyer dropdown for credit
            Obx(
              () =>
                  controller.isCredit.value &&
                      controller.buyerCustomers.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: DropdownButtonFormField<String>(
                        initialValue: controller.selectedBuyer.value,
                        decoration: InputDecoration(
                          labelText: 'buyerOptional'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(
                              'none'.tr,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...controller.buyerCustomers.map(
                            (c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => controller.selectedBuyer.value =
                            v?.isNotEmpty == true ? v : null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.quickSaleCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'quantity'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final qty =
                      double.tryParse(controller.quickSaleCtrl.text) ?? 0;
                  controller.addQuickSale(qty);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'completeSale'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Rent Tab ---
  Widget _buildRentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add book form
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'addBookToRent'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.bookNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'bookName'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.pageCountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'pages'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller.copiesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'copies'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.addRentBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('add'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rent out form
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'rentOutBook'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedRentBook.value,
                      decoration: InputDecoration(
                        labelText: 'selectBook'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: controller.rentBooks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.name,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => controller.selectedRentBook.value = v,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.rentCustomerCtrl,
                    decoration: InputDecoration(
                      labelText: 'customerName'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.rentDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'days'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.rentOutBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('rent'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'activeRentals'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTeal,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final active = controller.activeRentals;
            if (active.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'noActiveRentals'.tr,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              );
            }
            return Column(
              children: active
                  .map(
                    (r) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.book,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          r.bookName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${r.customerName} • ${'costLabel'.tr}৳${r.cost.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                r.isPaid ? Iconsax.tick_circle : Iconsax.money,
                                color: r.isPaid ? Colors.green : Colors.orange,
                                size: 18,
                              ),
                              onPressed: () => controller.toggleRentPaid(r.id),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.logout,
                                color: kTeal,
                                size: 18,
                              ),
                              onPressed: () => controller.returnBook(r.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
