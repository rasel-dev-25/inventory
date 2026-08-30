/// The single source of truth for which tables the outbox/puller sync
/// engine may touch, and which of them are append-only.
///
/// Deliberately hand-kept in sync with the allow-list inside
/// `apply_jsonb_upsert` in
/// `supabase/migrations/0008_outbox_sync_rpc.sql` — that server-side list
/// is the actual security boundary (this Dart list only decides what the
/// *client* attempts to sync; a bug here can under-sync but can never
/// over-permission, since the server independently re-checks every table
/// name and every row's RLS). If a table is added to one list without
/// the other, the mismatch fails loudly and immediately: the RPC raises
/// "table % is not sync-eligible" for a new local table, or a table only
/// known server-side is just never pushed/pulled locally.
abstract final class SyncTableRegistry {
  /// Every table the outbox pusher / cursor puller may read or write,
  /// mirroring `lib/data/local/tables/` minus `shops`/`shop_members`
  /// (their own dedicated RPCs in `0006_owner_onboarding_rpc.sql`) and
  /// `app_settings` (composite primary key, device-local by nature).
  static const syncableTables = <String>{
    'categories',
    'products',
    'product_images',
    'customers',
    'customer_images',
    'investors',
    'investor_repayments',
    'legacy_settlements',
    'purchase_trips',
    'purchase_items',
    'purchase_other_costs',
    'sales',
    'dues',
    'due_payments',
    'rent_pricing_tiers',
    'rent_transactions',
    'expenses',
    'orders',
    'fixed_assets',
    'fixed_asset_images',
    'quick_captures',
    'cash_ledger_entries',
    'stock_movements',
    'audit_log_entries',
  };

  /// A ledger fact, once written, is never edited or deleted — both here
  /// (client never attempts an update) and server-side
  /// (`forbid_update_or_delete()` in `0001_foundations.sql`, plus the
  /// `on conflict do nothing` branch in `apply_jsonb_upsert`). Kept as
  /// its own set rather than a per-table flag column so both this file
  /// and the migration read as "the append-only tables are exactly
  /// these five" at a glance.
  static const appendOnlyTables = <String>{
    'cash_ledger_entries',
    'stock_movements',
    'investor_repayments',
    'due_payments',
    'audit_log_entries',
  };

  static bool isSyncable(String table) => syncableTables.contains(table);

  static bool isAppendOnly(String table) => appendOnlyTables.contains(table);
}
