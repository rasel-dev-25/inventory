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
// Aliased: this feature's DailySalesController/DailySalesScreen share a
// name with the v1 classes imported above (both are literally named the
// same thing, matching v1 convention) — see CatalogScreen's doc comment
// for why this is a separate v2 screen/database, not a replacement.
import '../../features/daily_sales_v2/controller/daily_sales_controller.dart'
    as v2_sales;
import '../../features/daily_sales_v2/view/daily_sales_screen.dart' as v2_sales;
// Same aliasing reason as daily_sales_v2 above — v1's DuesController/
// DuesScreen (imported above) share these exact names.
import '../../features/dues_v2/controller/dues_controller.dart' as v2_dues;
import '../../features/dues_v2/view/dues_screen.dart' as v2_dues;
// Same aliasing reason again — v1's CustomersController/CustomersScreen
// (imported above) share these exact names.
import '../../features/customers_v2/controller/customers_controller.dart'
    as v2_customers;
import '../../features/customers_v2/view/customers_screen.dart' as v2_customers;
// No aliasing needed — v1 has no "stock" feature (its equivalent tab is
// InventoryController/InventoryScreen, a different name entirely).
import '../../features/stock_v2/controller/stock_controller.dart';
import '../../features/stock_v2/view/stock_screen.dart';
// Same aliasing reason as daily_sales_v2/dues_v2/customers_v2 above —
// v1's DashboardController/DashboardScreen (imported above) share these
// exact names.
import '../../features/dashboard_v2/controller/dashboard_controller.dart'
    as v2_dashboard;
import '../../features/dashboard_v2/view/dashboard_screen.dart' as v2_dashboard;
// Same aliasing reason again — v1's InvestorController/InvestorScreen
// (imported above) share these exact names.
import '../../features/investor_v2/controller/investor_controller.dart'
    as v2_investor;
import '../../features/investor_v2/view/investor_screen.dart' as v2_investor;
// No aliasing needed — v1 has no "Expense" feature by this name (its
// equivalent tab is FinanceController/FinanceScreen, a different name).
import '../../features/expense_v2/controller/expense_controller.dart';
import '../../features/expense_v2/view/expense_screen.dart';
// No aliasing needed — v1 has no rent feature at all.
import '../../features/rent_v2/controller/rent_controller.dart';
import '../../features/rent_v2/view/rent_screen.dart';
// No aliasing needed — v1 models order-givers as a tab inside
// CustomersController/CustomersScreen, not as classes of this name.
import '../../features/order_v2/controller/order_controller.dart';
import '../../features/order_v2/view/order_screen.dart';
// No aliasing needed — v1's equivalent is AssetsController/AssetsScreen
// (plural), a different name from this screen's singular
// FixedAssetController/FixedAssetScreen.
import '../../features/fixed_asset_v2/controller/fixed_asset_controller.dart';
import '../../features/fixed_asset_v2/view/fixed_asset_screen.dart';
// Same aliasing reason as daily_sales_v2/dues_v2/etc. above — v1's
// QuickCaptureController/QuickCaptureScreen (imported above) share
// these exact names.
import '../../features/quick_capture_v2/controller/quick_capture_controller.dart'
    as v2_quick_capture;
import '../../features/quick_capture_v2/view/quick_capture_screen.dart'
    as v2_quick_capture;
// No aliasing needed — v1 has no pricing-settings feature at all.
import '../../features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import '../../features/pricing_settings_v2/view/pricing_settings_screen.dart';

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
        // PricingSettingsController is registered permanently in
        // main.dart (not lazily here) — CatalogController just looks it
        // up, same as it does AppDatabaseV2, so ProductFormSheet's
        // suggestion works even if the owner never opened the Pricing
        // Settings screen this session.
        Get.lazyPut(
          () => CatalogController(
            Get.find<AppDatabaseV2>(),
            Get.find<PricingSettingsController>(),
          ),
        );
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
    GetPage(
      name: AppRoutes.dailySalesV2,
      page: () => const v2_sales.DailySalesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => v2_sales.DailySalesController(Get.find<AppDatabaseV2>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.duesV2,
      page: () => const v2_dues.DuesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => v2_dues.DuesController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.customersV2,
      page: () => const v2_customers.CustomersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => v2_customers.CustomersController(Get.find<AppDatabaseV2>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.stockV2,
      page: () => const StockScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StockController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.dashboardV2,
      page: () => const v2_dashboard.DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => v2_dashboard.DashboardController(Get.find<AppDatabaseV2>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.investorV2,
      page: () => const v2_investor.InvestorScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => v2_investor.InvestorController(Get.find<AppDatabaseV2>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.expenseV2,
      page: () => const ExpenseScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ExpenseController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.rentV2,
      page: () => const RentScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RentController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.orderV2,
      page: () => const OrderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.fixedAssetV2,
      page: () => const FixedAssetScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FixedAssetController(Get.find<AppDatabaseV2>()));
      }),
    ),
    GetPage(
      name: AppRoutes.quickCaptureV2,
      page: () => const v2_quick_capture.QuickCaptureScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => v2_quick_capture.QuickCaptureController(
            Get.find<AppDatabaseV2>(),
          ),
        );
      }),
    ),
    // No binding needed — PricingSettingsController is registered
    // permanently in main.dart (see its own doc comment for why), so
    // GetView<PricingSettingsController> just finds the existing instance.
    GetPage(
      name: AppRoutes.pricingSettingsV2,
      page: () => const PricingSettingsScreen(),
    ),
  ];
}
