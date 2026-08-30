import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/shell_controller.dart';
import 'widgets/app_drawer.dart';
import 'widgets/bottom_nav_bar.dart';

import '../../dashboard_v2/view/dashboard_screen.dart';
import '../../daily_sales_v2/view/daily_sales_screen.dart';
import '../../stock_v2/view/stock_screen.dart';
import '../../dues_v2/view/dues_screen.dart';
import '../../customers_v2/view/customers_screen.dart';
import '../../purchase_entry/view/purchase_entry_screen.dart';

/// The app's real home — one `IndexedStack` of the 6 screens a shop
/// owner opens most often day to day (Dashboard, Daily Sales, Stock,
/// Dues, Customers, Purchase Entry), matching v1's exact original shape (a bottom nav +
/// drawer shell) now that v1 itself is gone (see `main.dart`'s legacy
/// database cleanup).
///
/// **Which 6, and why these specifically — a judgment call, flagged for
/// reconsideration, not asserted as the only right answer:** v1's own
/// bottom nav had 7 slots (it also included Finance and Investor); v2 has
/// far more screens overall (~18) than v1 ever did, too many for any
/// bottom nav. These 5 are picked as the highest-frequency actions per
/// `notes/business_logic.md` (check the day's numbers, log a sale, check
/// what's on the shelf, chase a balance, look up a customer) — everything
/// else (Catalog, Purchase Entry, Investor, Expense, Rent, Orders, Fixed
/// Assets, Quick Capture, Pricing Settings, Reports, Reminders, Audit
/// Log, Recycle Bin, Account) lives in [AppDrawer] instead. If daily
/// usage says a different 5 belong here, swapping one is a small,
/// localized change — this screen and [AppBottomNav] are otherwise fully
/// generic/index-based, no screen-specific code baked in beyond this
/// list.
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
              StockScreen(onMenuTap: controller.openDrawer),
              DuesScreen(onMenuTap: controller.openDrawer),
              CustomersScreen(onMenuTap: controller.openDrawer),
              PurchaseEntryScreen(onMenuTap: controller.openDrawer),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(),
        ),
      ),
    );
  }
}
