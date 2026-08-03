import 'dart:async';

/// A minimal persistent key-value abstraction that [SettingsRegistry] is
/// built on. Kept as an interface (rather than depending on Drift directly)
/// so the pure-Dart registry logic can be unit tested against
/// [InMemoryKeyValueStore] without spinning up a database, and so the real
/// backing store can be swapped to the Drift `AppSettings` table in M1
/// without touching any call site.
abstract class KeyValueStore {
  String? read(String key);
  void write(String key, String value);
  void delete(String key);

  /// Emits the key that changed, once per write/delete. Consumers (e.g. a
  /// GetX controller bridging into `Rx` state) listen to this instead of
  /// polling.
  Stream<String> get changes;
}

/// A process-memory-only store. Used by default until the Drift-backed
/// implementation lands in M1, and in tests, where persistence across runs
/// is neither needed nor wanted.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};
  final _changesController = StreamController<String>.broadcast();

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) {
    _values[key] = value;
    _changesController.add(key);
  }

  @override
  void delete(String key) {
    _values.remove(key);
    _changesController.add(key);
  }

  @override
  Stream<String> get changes => _changesController.stream;

  void dispose() => _changesController.close();
}
