import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/database/app_database.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/customers_controller.dart';

class CustomersScreen extends GetView<CustomersController> {
  final VoidCallback? onMenuTap;
  const CustomersScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1, color: Colors.white),
          onPressed:
              onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
        ),
        backgroundColor: kTeal,
        title: shopLogo(size: 20, color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTypeSelector(),
              Expanded(child: Obx(() => _buildList())),
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
                  padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  child: _buildQuickForm(),
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

  Widget _buildTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...controller.customerTypes.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      controller.labelFor(t.id),
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.selectedType.value == t.id
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: controller.selectedType.value == t.id
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: controller.selectedType.value == t.id,
                    selectedColor: kTeal,
                    backgroundColor: Colors.grey.shade100,
                    avatar: Icon(
                      controller.iconFor(t.id),
                      size: 16,
                      color: controller.selectedType.value == t.id
                          ? Colors.white
                          : kTeal,
                    ),
                    onSelected: (_) => controller.selectedType.value = t.id,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _showAddTypeDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Iconsax.add, size: 16, color: kTeal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final list = controller.filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kTeal50, shape: BoxShape.circle),
              child: Icon(
                controller.iconFor(controller.selectedType.value),
                size: 40,
                color: kTeal.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${'noLabel'.tr} ${controller.labelFor(controller.selectedType.value)} ${'yet'.tr}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Iconsax.add, size: 16),
              label: Text('addOne'.tr),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _CustomerCard(customer: list[i]),
    );
  }

  Widget _buildQuickForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'addCustomer'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTeal,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.formNameCtrl,
              decoration: InputDecoration(
                labelText: 'customerName'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.formPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'phone'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.formType.value,
                decoration: InputDecoration(
                  labelText: 'customerType'.tr,
                  border: const OutlineInputBorder(),
                ),
                isExpanded: true,
                items: controller.customerTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(controller.labelFor(t.id)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.formType.value = v;
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.formNoteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'note'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.saveFromForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text('save'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTypeDialog() {
    final nameCtrl = TextEditingController();
    int selectedIcon = 0;
    const icons = [
      Iconsax.folder,
      Iconsax.people,
      Iconsax.shop,
      Iconsax.book,
      Iconsax.bag,
      Iconsax.task,
      Iconsax.card,
      Iconsax.profile_add,
      Iconsax.buildings,
      Iconsax.teacher,
      Iconsax.home,
      Iconsax.briefcase,
    ];

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            'addCustomerSection'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'sectionName'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('pickIcon'.tr, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: icons.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setDlgState(() => selectedIcon = i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == selectedIcon
                            ? kTeal.withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: i == selectedIcon
                            ? Border.all(color: kTeal, width: 2)
                            : null,
                      ),
                      child: Icon(
                        icons[i],
                        color: i == selectedIcon ? kTeal : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
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
                controller.addType(nameCtrl.text, selectedIcon);
                Get.back();
              },
              child: Text('addSection'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final waCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    File? image;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            '${'addCustomer'.tr} ${controller.labelFor(controller.selectedType.value)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final file = await controller.pickImage();
                    if (file != null) setDlgState(() => image = file);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: kTeal50,
                    backgroundImage: image != null ? FileImage(image!) : null,
                    child: image == null
                        ? const Icon(Iconsax.camera, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'whatsappNo'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'address'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'notes'.tr,
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
                controller.addCustomer(
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  whatsapp: waCtrl.text,
                  note: noteCtrl.text,
                  address: addressCtrl.text,
                  type: controller.selectedType.value,
                  image: image,
                );
                Get.back();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends GetView<CustomersController> {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        customer.imagePath.isNotEmpty && File(customer.imagePath).existsSync();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kTeal50,
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
                      : Icon(
                          controller.iconFor(customer.type),
                          color: kTeal,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              controller.labelFor(customer.type),
                              style: const TextStyle(
                                fontSize: 9,
                                color: kTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (customer.phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Iconsax.call,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      if (customer.whatsapp.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Iconsax.message,
                              size: 12,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.whatsapp,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      if (customer.address.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Iconsax.location,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (customer.note.isNotEmpty)
                        Text(
                          customer.note,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showEditDialog(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.edit,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => controller.confirmDelete(customer),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.trash,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (customer.type == 'buyer') _buildPurchases(),
            if (customer.type == 'order_giver') _buildOrders(),
            if (customer.type == 'due_taker') _buildDues(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchases() {
    return FutureBuilder<List<CustomerPurchase>>(
      future: controller.getPurchases(customer.id),
      builder: (ctx, snap) {
        final purchases = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 12),
            Row(
              children: [
                Text(
                  'purchases'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddPurchase(),
                  icon: const Icon(Iconsax.add, size: 14),
                  label: Text('add'.tr, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: kTeal),
                ),
              ],
            ),
            if (purchases.isEmpty)
              Text(
                'noPurchases'.tr,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              )
            else
              ...purchases.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.productName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '৳${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOrders() {
    return FutureBuilder<List<CustomerOrder>>(
      future: controller.getOrders(customer.id),
      builder: (ctx, snap) {
        final orders = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 12),
            Row(
              children: [
                Text(
                  'orders'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddOrder(),
                  icon: const Icon(Iconsax.add, size: 14),
                  label: Text('add'.tr, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: kTeal),
                ),
              ],
            ),
            if (orders.isEmpty)
              Text(
                'noOrders'.tr,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              )
            else
              ...orders.map((o) {
                final color = o.status == 'fulfilled'
                    ? Colors.green
                    : o.status == 'cancelled'
                    ? Colors.red
                    : Colors.blue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          o.status.tr,
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          o.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (o.status == 'pending') ...[
                        IconButton(
                          icon: const Icon(
                            Iconsax.tick_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          onPressed: () => controller.markOrderFulfilled(o.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Iconsax.close_circle,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.markOrderCancelled(o.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showAddOrder() {
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toString().substring(0, 10),
    );
    Get.dialog(
      AlertDialog(
        title: Text(
          'addOrder'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'orderDescription'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dateCtrl,
              decoration: InputDecoration(
                labelText: 'dateNeeded'.tr,
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
              controller.addOrder(customer, descCtrl.text, dateCtrl.text);
              Get.back();
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildDues() {
    return FutureBuilder<double>(
      future: controller.getOutstanding(customer.id),
      builder: (ctx, snap) {
        final outstanding = snap.data ?? 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 12),
            Row(
              children: [
                Text(
                  'due'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '৳${outstanding.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: outstanding <= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddPurchase() {
    final prodCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(
          'addPurchase'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prodCtrl,
              decoration: InputDecoration(
                labelText: 'productName'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'priceTaka'.tr,
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
              controller.addPurchase(
                customer,
                prodCtrl.text,
                double.tryParse(priceCtrl.text) ?? 0,
                DateTime.now().toString().substring(0, 10),
              );
              Get.back();
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final waCtrl = TextEditingController(text: customer.whatsapp);
    final addressCtrl = TextEditingController(text: customer.address);
    final noteCtrl = TextEditingController(text: customer.note);
    File? image = customer.imagePath.isNotEmpty
        ? File(customer.imagePath)
        : null;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            '${'edit'.tr} ${customer.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final file = await controller.pickImage();
                    if (file != null) setDlgState(() => image = file);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: kTeal50,
                    backgroundImage: image != null ? FileImage(image!) : null,
                    child: image == null
                        ? const Icon(Iconsax.camera, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'whatsappNo'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'address'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'notes'.tr,
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
                controller.updateCustomer(
                  customer,
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  whatsapp: waCtrl.text,
                  address: addressCtrl.text,
                  note: noteCtrl.text,
                  image: image,
                );
                Get.back();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
