import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/view/auth_gate.dart';
import '../../features/shell/controller/shell_controller.dart';
import '../../data/local/app_database.dart' show AppDatabase;
import '../../data/remote/supabase_storage_upload_transport.dart';
import '../../features/catalog/view/catalog_screen.dart';
import '../../features/catalog/controller/catalog_controller.dart';
import '../../features/purchase_entry/view/purchase_entry_screen.dart';
import '../../features/purchase_entry/controller/purchase_entry_controller.dart';
import '../../features/settings/view/account_settings_screen.dart';
// Controllers only — these 5 have no route/GetPage of their own, they're
// bound eagerly in the shell's own binding below since ShellScreen
// embeds them directly (see that class's own doc comment).
import '../../features/daily_sales_v2/controller/daily_sales_controller.dart';
import '../../features/dues_v2/controller/dues_controller.dart';
import '../../features/customers_v2/controller/customers_controller.dart';
import '../../features/stock_v2/controller/stock_controller.dart';
import '../../features/dashboard_v2/controller/dashboard_controller.dart';
import '../../features/investor_v2/controller/investor_controller.dart';
import '../../features/investor_v2/view/investor_screen.dart';
import '../../features/expense_v2/controller/expense_controller.dart';
import '../../features/expense_v2/view/expense_screen.dart';
import '../../features/rent_v2/controller/rent_controller.dart';
import '../../features/rent_v2/view/rent_screen.dart';
import '../../features/order_v2/controller/order_controller.dart';
import '../../features/order_v2/view/order_screen.dart';
import '../../features/fixed_asset_v2/controller/fixed_asset_controller.dart';
import '../../features/fixed_asset_v2/view/fixed_asset_screen.dart';
import '../../features/quick_capture_v2/controller/quick_capture_controller.dart';
import '../../features/quick_capture_v2/view/quick_capture_screen.dart';
import '../../features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import '../../features/pricing_settings_v2/view/pricing_settings_screen.dart';
import '../../features/reports_v2/controller/reports_controller.dart';
import '../../features/reports_v2/view/reports_screen.dart';
// No binding needed — ReminderController is registered permanently in
// main.dart (it needs to keep computing/notifying even when the
// Reminders screen itself is never opened), so
// GetView<ReminderController> just finds the existing instance.
import '../../features/reminders_v2/view/reminders_screen.dart';
import '../../features/audit_log_v2/controller/audit_log_controller.dart';
import '../../features/audit_log_v2/view/audit_log_screen.dart';
import '../../features/recycle_bin_v2/controller/recycle_bin_controller.dart';
import '../../features/recycle_bin_v2/view/recycle_bin_screen.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.shell,
      // AuthGate decides between sign-in / onboarding / the real shell —
      // see lib/features/auth/view/auth_gate.dart. ShellController and
      // the 5 screen-level controllers ShellScreen embeds directly are
      // bound eagerly here so AuthGate's ShellScreen branch has them
      // ready the instant it renders — see ShellScreen's own doc comment
      // for which 5 these are and why.
      page: () => const AuthGate(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ShellController());
        Get.lazyPut(() => DashboardController(Get.find<AppDatabase>()));
        Get.lazyPut(() => DailySalesController(Get.find<AppDatabase>()));
        Get.lazyPut(
          () => StockController(
            Get.find<AppDatabase>(),
            pricingSettings: Get.find<PricingSettingsController>(),
            imageStorage: Get.find<SupabaseStorageUploadTransport>(),
          ),
        );
        Get.lazyPut(() => DuesController(Get.find<AppDatabase>()));
        Get.lazyPut(() => PurchaseEntryController(Get.find<AppDatabase>()));
        Get.lazyPut(
          () => CustomersController(
            Get.find<AppDatabase>(),
            imageStorage: Get.find<SupabaseStorageUploadTransport>(),
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.catalogV2,
      page: () => const CatalogScreen(),
      binding: BindingsBuilder(() {
        // PricingSettingsController is registered permanently in
        // main.dart (not lazily here) — CatalogController just looks it
        // up, same as it does AppDatabase, so ProductFormSheet's
        // suggestion works even if the owner never opened the Pricing
        // Settings screen this session.
        Get.lazyPut(
          () => CatalogController(
            Get.find<AppDatabase>(),
            Get.find<PricingSettingsController>(),
            imageStorage: Get.find<SupabaseStorageUploadTransport>(),
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.purchaseEntryV2,
      page: () => const PurchaseEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PurchaseEntryController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.accountSettings,
      page: () => const AccountSettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.investorV2,
      page: () => const InvestorScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InvestorController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.expenseV2,
      page: () => const ExpenseScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ExpenseController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.rentV2,
      page: () => const RentScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RentController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.orderV2,
      page: () => const OrderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.fixedAssetV2,
      page: () => const FixedAssetScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => FixedAssetController(
            Get.find<AppDatabase>(),
            imageStorage: Get.find<SupabaseStorageUploadTransport>(),
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.quickCaptureV2,
      page: () => const QuickCaptureScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QuickCaptureController(Get.find<AppDatabase>()));
      }),
    ),
    // No binding needed — PricingSettingsController is registered
    // permanently in main.dart (see its own doc comment for why), so
    // GetView<PricingSettingsController> just finds the existing instance.
    GetPage(
      name: AppRoutes.pricingSettingsV2,
      page: () => const PricingSettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.reportsV2,
      page: () => const ReportsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReportsController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(name: AppRoutes.remindersV2, page: () => const RemindersScreen()),
    GetPage(
      name: AppRoutes.auditLogV2,
      page: () => const AuditLogScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuditLogController(Get.find<AppDatabase>()));
      }),
    ),
    GetPage(
      name: AppRoutes.recycleBinV2,
      page: () => const RecycleBinScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RecycleBinController(Get.find<AppDatabase>()));
      }),
    ),
  ];
}
