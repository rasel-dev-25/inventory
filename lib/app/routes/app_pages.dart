import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/view/auth_gate.dart';
import '../../features/shell/controller/shell_controller.dart';
import '../../features/quick_capture/view/quick_capture_screen.dart';
import '../../features/quick_capture/controller/quick_capture_controller.dart';
import '../../features/assets/view/assets_screen.dart';
import '../../features/assets/controller/assets_controller.dart';
import '../../features/inventory/view/inventory_screen.dart';
import '../../features/inventory/controller/inventory_controller.dart';
import '../../features/dues/view/dues_screen.dart';
import '../../features/dues/controller/dues_controller.dart';
import '../../features/customers/view/customers_screen.dart';
import '../../features/customers/controller/customers_controller.dart';
import '../../features/finance/view/finance_screen.dart';
import '../../features/finance/controller/finance_controller.dart';
import '../../features/investor/view/investor_screen.dart';
import '../../features/investor/controller/investor_controller.dart';
import '../../features/daily_sales/view/daily_sales_screen.dart';
import '../../features/daily_sales/controller/daily_sales_controller.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/dashboard/controller/dashboard_controller.dart';
import '../../data/local/app_database.dart' show AppDatabaseV2;
import '../../features/catalog/view/catalog_screen.dart';
import '../../features/catalog/controller/catalog_controller.dart';
import '../../features/purchase_entry/view/purchase_entry_screen.dart';
import '../../features/purchase_entry/controller/purchase_entry_controller.dart';
import '../../features/settings/view/account_settings_screen.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.shell,
      // AuthGate decides between sign-in / onboarding / the real shell —
      // see lib/features/auth/view/auth_gate.dart. ShellController and
      // its screen-level controllers are still bound eagerly here so
      // AuthGate's ShellScreen branch has them ready the instant it
      // renders, exactly as before this change.
      page: () => const AuthGate(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ShellController());
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => DailySalesController());
        Get.lazyPut(() => InventoryController());
        Get.lazyPut(() => DuesController());
        Get.lazyPut(() => FinanceController());
        Get.lazyPut(() => InvestorController());
        Get.lazyPut(() => CustomersController());
      }),
    ),
    GetPage(
      name: AppRoutes.quickCapture,
      page: () => const QuickCaptureScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QuickCaptureController());
      }),
    ),
    GetPage(
      name: AppRoutes.assets,
      page: () => const AssetsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AssetsController());
      }),
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InventoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.dues,
      page: () => const DuesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DuesController());
      }),
    ),
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CustomersController());
      }),
    ),
    GetPage(
      name: AppRoutes.finance,
      page: () => const FinanceScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceController());
      }),
    ),
    GetPage(
      name: AppRoutes.investor,
      page: () => const InvestorScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InvestorController());
      }),
    ),
    GetPage(
      name: AppRoutes.dailySales,
      page: () => const DailySalesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DailySalesController());
      }),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
      }),
    ),
    // ── M1 v2 screens — see CatalogScreen's doc comment for why these
    // are separate routes rather than folding into the shell above ────
    GetPage(
      name: AppRoutes.catalogV2,
      page: () => const CatalogScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CatalogController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.purchaseEntryV2,
      page: () => const PurchaseEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PurchaseEntryController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.accountSettings,
      page: () => const AccountSettingsScreen(),
    ),
  ];
}
