import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controller/inventory_controller.dart';

class FilterBar extends GetView<InventoryController> {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('filterByCategory'.tr, Iconsax.filter),
        const SizedBox(height: 8),
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('all'.tr, controller.filterCategory.value == null, () => controller.filterCategory.value = null),
              ...controller.categories.map((cat) => _chip(cat, controller.filterCategory.value == cat, () => controller.filterCategory.value = cat)),
              _addChip(),
            ],
          ),
        )),
        const SizedBox(height: 10),
        _sectionHeader('filterByInvestor'.tr, Iconsax.profile),
        const SizedBox(height: 8),
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('all'.tr, controller.filterInvestor.value == null, () => controller.filterInvestor.value = null),
              ...controller.investors.map((inv) => _chip(inv, controller.filterInvestor.value == inv, () => controller.filterInvestor.value = inv)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: kTeal, width: 3))),
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kTeal),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTeal)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: kTeal,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _addChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        avatar: const Icon(Iconsax.add, size: 16, color: kTeal),
        label: Text('add'.tr, style: const TextStyle(fontSize: 13, color: kTeal)),
        onPressed: controller.showAddCategoryDialog,
        backgroundColor: kTeal.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
