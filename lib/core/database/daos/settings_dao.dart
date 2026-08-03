import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) {
    return into(appSettings).insert(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
      onConflict: DoUpdate((_) => AppSettingsCompanion(value: Value(value))),
    );
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await getValue(key);
    if (v == null) return defaultValue;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value) => setValue(key, '$value');
}
