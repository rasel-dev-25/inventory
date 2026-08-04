/// Every column across the 22 syncable tables declared with Drift's
/// `textEnum<T>()` (see `lib/data/local/tables/*.dart`) — the explicit
/// allow-list [EnumCaseBridge] uses to know exactly which values need
/// case conversion at the sync boundary, and only those.
///
/// Why this needs to exist at all: Drift's `textEnum<T>()` stores a Dart
/// enum's `.name` verbatim (`EnumNameConverter` — e.g. `PaymentMethod
/// .mobileBanking` → the literal string `"mobileBanking"`), while every
/// matching Postgres enum type in `0001_foundations.sql` was declared
/// with the snake_case spelling of the same identifier (`create type
/// payment_method as enum ('cash', 'mobile_banking', 'bank_transfer')`).
/// A raw pass-through sync of an enum column's value would silently
/// write a string neither side actually accepts: `mobileBanking` is not
/// a valid `payment_method` value in Postgres, and `mobile_banking`
/// pulled back into local SQLite would fail `EnumNameConverter`'s own
/// `.byName()` lookup the next time Drift tries to decode that column as
/// a `PaymentMethod`. This was caught before it ever reached a real
/// device by reasoning through `textEnum`'s generated converter
/// (`EnumNameConverter` in `app_database.g.dart`) against the enum
/// literals actually written into the migrations — not by a failure
/// observed in the field.
///
/// Deliberately an explicit column list, not a blind "convert every
/// string that looks like camelCase" heuristic — a product name or
/// customer name could coincidentally look like a single camelCase word
/// (`"AlAshab"`), and mangling free-text user data to "fix" a column
/// that was never an enum in the first place would be a worse bug than
/// the one this fixes.
abstract final class EnumColumnRegistry {
  static const Map<String, Set<String>> enumColumnsByTable = {
    'fixed_assets': {'source_type'},
    'dues': {'source_type', 'status'},
    'due_payments': {'payment_method'},
    'expenses': {'category', 'payment_method'},
    'investors': {'investment_type', 'profit_payout_cycle'},
    'investor_repayments': {'type', 'payment_method'},
    'legacy_settlements': {'status'},
    'cash_ledger_entries': {'payment_method'},
    'orders': {'status'},
    'products': {'fund_source_type'},
    'purchase_items': {'fund_source_type'},
    'quick_captures': {'type', 'status'},
    'rent_transactions': {'status'},
    'sales': {'payment_status', 'payment_method', 'fund_source_type'},
  };

  static Set<String> enumColumnsFor(String table) =>
      enumColumnsByTable[table] ?? const {};
}
