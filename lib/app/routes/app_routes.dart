/// Every route in the app is now what used to be called "v2" — there is
/// no more v1 to disambiguate against (see `main.dart`'s legacy database
/// cleanup and `ShellScreen`'s own doc comment for the removal this
/// followed). The `V2`-suffixed constant names themselves are left as-is
/// deliberately: renaming them would touch every screen/controller/test
/// that references one, a large, purely cosmetic diff for zero
/// functional benefit — a real cleanup worth doing on its own, not
/// bundled into this change.
abstract class AppRoutes {
  static const shell = '/';
  static const catalogV2 = '/v2/catalog';
  static const purchaseEntryV2 = '/v2/purchase-entry';
  static const accountSettings = '/v2/account';

  // Dashboard/Daily Sales/Stock/Dues/Customers have no route of their
  // own — ShellScreen embeds all 5 directly (an IndexedStack, switched
  // via ShellController.switchTab), matching v1's exact original
  // pattern for its own bottom-nav screens. See ShellScreen's own doc
  // comment for why these 5 specifically.
  static const investorV2 = '/v2/investor';
  static const expenseV2 = '/v2/expense';
  static const rentV2 = '/v2/rent';
  static const orderV2 = '/v2/order';
  static const fixedAssetV2 = '/v2/fixed-asset';
  static const quickCaptureV2 = '/v2/quick-capture';
  static const pricingSettingsV2 = '/v2/pricing-settings';
  static const reportsV2 = '/v2/reports';
  static const remindersV2 = '/v2/reminders';
  static const auditLogV2 = '/v2/audit-log';
  static const recycleBinV2 = '/v2/recycle-bin';
}
