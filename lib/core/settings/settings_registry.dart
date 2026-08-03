import 'key_value_store.dart';

/// A typed, declared-default setting. Defining settings as `SettingKey`
/// constants (rather than raw string keys scattered through the codebase)
/// is what replaces the five speculative tables an external review
/// proposed (`AppSettings`/`BusinessSettings`/`TaxSettings`/`RentSettings`/
/// `InvoiceSettings`) — most of that is genuinely just typed key-value
/// configuration for a single shop, not relational data. Real tables are
/// reserved for things that are actually rows, like `rent_pricing_tiers`.
class SettingKey<T> {
  final String id;
  final T defaultValue;
  final T Function(String raw) decode;
  final String Function(T value) encode;

  const SettingKey(
    this.id, {
    required this.defaultValue,
    required this.decode,
    required this.encode,
  });

  static SettingKey<bool> boolean(String id, {required bool defaultValue}) {
    return SettingKey<bool>(
      id,
      defaultValue: defaultValue,
      decode: (raw) => raw == 'true',
      encode: (value) => value.toString(),
    );
  }

  static SettingKey<String> string(String id, {required String defaultValue}) {
    return SettingKey<String>(
      id,
      defaultValue: defaultValue,
      decode: (raw) => raw,
      encode: (value) => value,
    );
  }

  static SettingKey<double> number(String id, {required double defaultValue}) {
    return SettingKey<double>(
      id,
      defaultValue: defaultValue,
      decode: (raw) => double.tryParse(raw) ?? defaultValue,
      encode: (value) => value.toString(),
    );
  }
}

/// Reads and writes [SettingKey]s through a [KeyValueStore]. This is the
/// only sanctioned way to read app configuration — no constants, no magic
/// numbers buried in a controller. Business-relevant keys (rent tiers,
/// overhead settings, extra-day charge rate) are declared alongside the
/// domain module that owns them once those modules land in M1/M2; this
/// class only provides the read/write/validate mechanism.
class SettingsRegistry {
  final KeyValueStore _store;
  const SettingsRegistry(this._store);

  T get<T>(SettingKey<T> key) {
    final raw = _store.read(key.id);
    if (raw == null) return key.defaultValue;
    try {
      return key.decode(raw);
    } on Object {
      // A corrupt/unexpected stored value must never crash a settings read
      // — fall back to the declared default and let the caller re-save a
      // valid value.
      return key.defaultValue;
    }
  }

  void set<T>(SettingKey<T> key, T value) {
    _store.write(key.id, key.encode(value));
  }

  void reset<T>(SettingKey<T> key) {
    _store.delete(key.id);
  }

  /// Emits `true` whenever the given key's stored value changes, so a
  /// controller can rebuild reactively without polling.
  Stream<void> watch(SettingKey<dynamic> key) {
    return _store.changes.where((changedKey) => changedKey == key.id);
  }
}
