import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controller/inventory_controller.dart';
import '../../../../../core/database/app_database.dart';

class ProductCard extends GetView<InventoryController> {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final dq = controller.displayQty(product);
    final isOut = dq <= 0;
    final isLow = !isOut && dq < InventoryController.lowStockThreshold;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isOut ? Colors.red.shade50 : isLow ? Colors.yellow.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isOut ? Colors.red.shade100 : isLow ? Colors.yellow.shade100 : kTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imagePath.isNotEmpty && File(product.imagePath).existsSync()
                  ? Image.file(File(product.imagePath), fit: BoxFit.cover)
                  : Icon(isOut ? Iconsax.box : isLow ? Iconsax.warning_2 : Iconsax.bag,
                      color: isOut ? Colors.red.shade400 : isLow ? Colors.yellow.shade700 : kTeal, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                    color: isOut ? Colors.red.shade800 : isLow ? Colors.yellow.shade900 : Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${'buyLabel'.tr}৳${product.buyPrice.toStringAsFixed(2)}/${product.buyUnit}  •  ${'sellPriceLabel'.tr}৳${product.sellPrice.toStringAsFixed(2)}/${product.sellUnit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text('${'stockLabel2'.tr}${dq.toStringAsFixed(2)} ${product.sellUnit}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: isOut ? Colors.red : Colors.green.shade700)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Iconsax.money, color: Colors.green), onPressed: () => controller.processSale(product, false),
                  tooltip: 'sell'.tr, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                IconButton(icon: const Icon(Iconsax.edit, color: kTeal), onPressed: () => _showEditDialog(context),
                  tooltip: 'edit'.tr, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                IconButton(icon: const Icon(Iconsax.trash, color: Colors.red), onPressed: () => _confirmDelete(context),
                  tooltip: 'delete'.tr, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Iconsax.trash, color: Colors.red.shade400, size: 22),
          const SizedBox(width: 10),
          Text('deleteProduct'.tr),
        ]),
        content: Text('${'delete'.tr} "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { controller.deleteProduct(product.id); Get.back(); },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: product.name);
    final buyPriceCtrl = TextEditingController(text: product.buyPrice.toString());
    final sellPriceCtrl = TextEditingController(text: product.sellPrice.toString());
    final stockCtrl = TextEditingController(text: controller.displayQty(product).toStringAsFixed(1));

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Iconsax.edit, color: kTeal, size: 22),
          const SizedBox(width: 10),
          Text('editProduct'.tr),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'productName'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: buyPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'buyPrice'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'sellPrice'.tr, border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${'stock'.tr} (${product.sellUnit})', border: const OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
            onPressed: () {
              controller.updateProduct(product,
                name: nameCtrl.text,
                category: product.category,
                investor: product.investor,
                buyQty: product.buyQty,
                buyUnit: product.buyUnit,
                buyPrice: double.tryParse(buyPriceCtrl.text) ?? product.buyPrice,
                sellUnit: product.sellUnit,
                sellPrice: double.tryParse(sellPriceCtrl.text) ?? product.sellPrice,
                stockQty: double.tryParse(stockCtrl.text) ?? controller.displayQty(product),
              );
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
