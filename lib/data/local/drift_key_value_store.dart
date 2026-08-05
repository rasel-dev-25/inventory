import 'dart:async';

import '../../core/settings/key_value_store.dart';
import 'daos/app_settings_dao.dart';

/// The real, restart-surviving [KeyValueStore] — backed by the
/// [AppDatabaseV2]'s `AppSettings` table via [AppSettingsDao]. Until this
/// class, `SettingsRegistry` only ever ran against
/// [InMemoryKeyValueStore] (see that class's own doc comment: "until the
/// Drift-backed implementation lands in M1" — it landed in M2 instead,
/// with the pricing-engine settings as its first real user).
///
/// [KeyValueStore.read] is synchronous, but every real Drift query is
/// async — so this keeps an in-memory cache that every [read] answers
/// from directly, and pushes the one unavoidable async step to [hydrate],
/// which a caller awaits exactly once (in `main.dart`, before this store
/// is registered for anyone to read from). [write]/[delete] update the
/// cache immediately (so a read immediately after a write is never
/// stale) and persist to Drift in the background — a crash between the
/// two would only lose the most recent setting edit, not corrupt
/// anything, since every setting is independently keyed.
class DriftKeyValueStore implements KeyValueStore {
  final AppSettingsDao _dao;
  final Map<String, String> _cache = {};
  final _changesController = StreamController<String>.broadcast();

  DriftKeyValueStore(this._dao);

  /// Must be awaited once before this store is read from — see the class
  /// doc comment.
  Future<void> hydrate() async {
    final rows = await _dao.getAll();
    _cache
      ..clear()
      ..addEntries(rows.map((r) => MapEntry(r.key, r.value)));
  }

  @override
  String? read(String key) => _cache[key];

  @override
  void write(String key, String value) {
    _cache[key] = value;
    _changesController.add(key);
    unawaited(_dao.upsert(key, value));
  }

  @override
  void delete(String key) {
    _cache.remove(key);
    _changesController.add(key);
    unawaited(_dao.remove(key));
  }

  @override
  Stream<String> get changes => _changesController.stream;

  void dispose() => _changesController.close();
}
