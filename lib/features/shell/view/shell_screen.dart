import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/shell_controller.dart';
import 'widgets/app_drawer.dart';
import 'widgets/bottom_nav_bar.dart';

import '../../dashboard/view/dashboard_screen.dart';
import '../../daily_sales/view/daily_sales_screen.dart';
import '../../inventory/view/inventory_screen.dart';
import '../../dues/view/dues_screen.dart';
import '../../finance/view/finance_screen.dart';
import '../../investor/view/investor_screen.dart';
import '../../customers/view/customers_screen.dart';

class ShellScreen extends GetView<ShellController> {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await controller.onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Obx(
        () => Scaffold(
          key: controller.scaffoldKey,
          drawer: const AppDrawer(),
          body: IndexedStack(
            index: controller.currentIndex.value,
            children: [
              DashboardScreen(onMenuTap: controller.openDrawer),
              DailySalesScreen(onMenuTap: controller.openDrawer),
              InventoryScreen(onMenuTap: controller.openDrawer),
              DuesScreen(onMenuTap: controller.openDrawer),
              FinanceScreen(onMenuTap: controller.openDrawer),
              InvestorScreen(onMenuTap: controller.openDrawer),
              CustomersScreen(onMenuTap: controller.openDrawer),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(),
        ),
      ),
    );
  }
}
