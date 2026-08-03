import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? lastBackPress;

  void switchTab(int index) {
    currentIndex.value = index;
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Get.back();
    }
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  Future<bool> onWillPop() async {
    if (currentIndex.value != 0) {
      currentIndex.value = 0;
      return false;
    }
    final now = DateTime.now();
    if (lastBackPress == null ||
        now.difference(lastBackPress!) > const Duration(seconds: 2)) {
      lastBackPress = now;
      Get.snackbar(
        '',
        'exitPressAgain'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return false;
    }
    return true;
  }
}
