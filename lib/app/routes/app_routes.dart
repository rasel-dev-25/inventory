abstract class AppRoutes {
  static const shell = '/';
  static const dashboard = '/dashboard';
  static const dailySales = '/daily-sales';
  static const inventory = '/inventory';
  static const dues = '/dues';
  static const finance = '/finance';
  static const investor = '/investor';
  static const customers = '/customers';
  static const assets = '/assets';
  static const quickCapture = '/quick-capture';

  // ── M1 v2 screens (read/write AppDatabaseV2, not v1's AppDatabase —
  // see CatalogScreen's doc comment for why these are separate routes
  // rather than replacing an existing v1 tab) ──────────────────────────
  static const catalogV2 = '/v2/catalog';
  static const purchaseEntryV2 = '/v2/purchase-entry';
  static const accountSettings = '/v2/account';
  static const dailySalesV2 = '/v2/daily-sales';
  static const duesV2 = '/v2/dues';
  static const customersV2 = '/v2/customers';
  static const stockV2 = '/v2/stock';
  static const dashboardV2 = '/v2/dashboard';
  static const investorV2 = '/v2/investor';
  static const expenseV2 = '/v2/expense';
  static const rentV2 = '/v2/rent';
  static const orderV2 = '/v2/order';
  static const fixedAssetV2 = '/v2/fixed-asset';
  static const quickCaptureV2 = '/v2/quick-capture';
  static const pricingSettingsV2 = '/v2/pricing-settings';
}
