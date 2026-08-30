import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../controller/shell_controller.dart';

/// One item per screen `ShellScreen`'s `IndexedStack` embeds, in the same
/// order — see that class's own doc comment for which 6 and why.
class AppBottomNav extends GetView<ShellController> {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.switchTab,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.home),
            label: 'overview'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.money_send),
            label: 'dailySales'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.box),
            label: 'stock'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.book),
            label: 'dues'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.people),
            label: 'customers'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.truck),
            label: 'purchase'.tr,
          ),
        ],
      ),
    );
  }
}
