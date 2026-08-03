import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/unit_conversion.dart';
import '../../controller/inventory_controller.dart';

class ProductForm extends GetView<InventoryController> {
  const ProductForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                const SizedBox(width: 10),
                Text(
                  'addNewProduct'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GetBuilder<InventoryController>(
                  builder: (c) => GestureDetector(
                    onTap: c.pickImage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kTeal.withValues(alpha: 0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: c.selectedImage != null
                            ? Image.file(c.selectedImage!, fit: BoxFit.cover)
                            : Icon(
                                Iconsax.camera,
                                color: kTeal.withValues(alpha: 0.6),
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.productNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'productName'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => IconButton(
                    icon: Icon(
                      controller.isListening.value
                          ? Iconsax.microphone
                          : Iconsax.microphone_slash,
                      color: controller.isListening.value
                          ? Colors.red
                          : Colors.grey.shade500,
                    ),
                    onPressed: controller.toggleVoice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'category'.tr,
                    controller.categories,
                    controller.selectedCategory,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    'investor'.tr,
                    controller.investors,
                    controller.selectedInvestor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.buyQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'buyQty'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    'buyUnit'.tr,
                    UnitConversion.units,
                    controller.selectedBuyUnit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.buyPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'buyPrice'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.sellPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'sellPrice'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dropdown(
              'sellUnit'.tr,
              UnitConversion.units,
              controller.selectedSellUnit,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'stock'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.noteCtrl,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'noteOptional'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.addProduct,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'saveProduct'.tr,
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
    );
  }

  Widget _dropdown(String hint, List<String> items, Rxn<String> selected) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected.value,
            isExpanded: true,
            hint: Text(hint),
            items: items
                .toSet()
                .toList()
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => selected.value = v,
          ),
        ),
      ),
    );
  }
}
