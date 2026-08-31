import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shared.dart';

part 'app_settings_dao.g.dart';

/// Data access for [AppSettings] — the backing store `DriftKeyValueStore`
/// (`lib/data/local/drift_key_value_store.dart`) wraps to give
/// `SettingsRegistry` real, restart-surviving persistence.
///
/// Deliberately shop-agnostic (no `shopId` column, unlike every business
/// table) — this local Drift table mirrors the *shape* of Supabase's
/// `app_settings` table but not its `(shop_id, key)` composite key, since
/// exactly one shop exists per local install (see `tables/shared.dart`'s
/// `Shops` doc comment). This table also does **not** sync — see
/// `apply_jsonb_upsert`'s hardcoded allowlist in
/// `supabase/migrations/0008_outbox_sync_rpc.sql`, which explicitly
/// excludes `app_settings` (composite key, needs its own RPC that
/// doesn't exist yet) — a deliberate, flagged gap: two devices on the
/// same shop do not currently share pricing-engine settings.
@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<List<AppSettingRow>> getAll() => select(appSettings).get();

  Future<String?> get(String key) async {
    final row = await (select(appSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> upsert(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  /// Named `remove`, not `delete` — a bare `delete` method on this class
  /// would shadow `DatabaseAccessor.delete<T>(TableInfo)`, the very method
  /// this needs to call internally.
  Future<void> remove(String key) async {
    await (delete(appSettings)..where((s) => s.key.equals(key))).go();
  }
}
