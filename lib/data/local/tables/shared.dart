import 'package:drift/drift.dart';

/// The shop this device is bound to. Normally exactly one row per
/// installation — kept as a real table (not a setting) because it is the
/// anchor every other table's `shopId` column points at, and because it is
/// the row Supabase's `shop_members`/RLS policies key off of once this
/// device syncs.
class Shops extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock categories (Book/Date/Attar/Topi/...). Kept as a real table
/// (matching v1) since the set is user-editable, not a fixed enum.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Backing store for `SettingsRegistry` (see
/// `lib/core/settings/settings_registry.dart`) — typed scalar config for a
/// single shop (overhead settings, extra-day rent rate, pricing-engine
/// bootstrap flag, module feature flags). Deliberately generic
/// key/value rather than one column per setting, same shape as v1's
/// `AppSettings` — most of what an external review proposed as five
/// separate settings tables belongs here instead; see ARCHITECTURE.md.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
