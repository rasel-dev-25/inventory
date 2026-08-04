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
}
