import 'package:test/test.dart';
import 'package:inventory/core/settings/key_value_store.dart';
import 'package:inventory/core/settings/settings_registry.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    test('read returns null for an unwritten key', () {
      final store = InMemoryKeyValueStore();
      expect(store.read('missing'), isNull);
    });

    test('write then read round-trips the value', () {
      final store = InMemoryKeyValueStore();
      store.write('k', 'v');
      expect(store.read('k'), 'v');
    });

    test('delete removes the value', () {
      final store = InMemoryKeyValueStore();
      store.write('k', 'v');
      store.delete('k');
      expect(store.read('k'), isNull);
    });

    test('changes emits the key on write and on delete', () async {
      final store = InMemoryKeyValueStore();
      final emitted = <String>[];
      final sub = store.changes.listen(emitted.add);
      store.write('a', '1');
      store.delete('a');
      await Future<void>.delayed(Duration.zero);
      expect(emitted, ['a', 'a']);
      await sub.cancel();
      store.dispose();
    });
  });

  group('SettingsRegistry', () {
    test('returns the declared default when nothing is stored', () {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final flag = SettingKey.boolean('flag.x', defaultValue: true);
      expect(registry.get(flag), isTrue);
    });

    test('set then get round-trips a bool', () {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final flag = SettingKey.boolean('flag.x', defaultValue: false);
      registry.set(flag, true);
      expect(registry.get(flag), isTrue);
    });

    test('set then get round-trips a string', () {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final locale = SettingKey.string('locale', defaultValue: 'en');
      registry.set(locale, 'bn');
      expect(registry.get(locale), 'bn');
    });

    test('set then get round-trips a number', () {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final rate = SettingKey.number('rent.extraDayRate', defaultValue: 2.0);
      registry.set(rate, 5.5);
      expect(registry.get(rate), 5.5);
    });

    test('reset clears back to the declared default', () {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final flag = SettingKey.boolean('flag.x', defaultValue: false);
      registry.set(flag, true);
      registry.reset(flag);
      expect(registry.get(flag), isFalse);
    });

    test(
      'a corrupt stored value falls back to the default instead of throwing',
      () {
        final store = InMemoryKeyValueStore();
        final registry = SettingsRegistry(store);
        final rate = SettingKey.number('rate', defaultValue: 1.0);
        // number's decode uses tryParse with a fallback, so it can't actually
        // throw — but boolean/string are literal parses, so exercise the
        // exception-swallowing path with a hand-crafted decode that throws.
        final strict = SettingKey<int>(
          'strict',
          defaultValue: 42,
          decode: (raw) => int.parse(raw), // throws on non-numeric input
          encode: (v) => v.toString(),
        );
        store.write('strict', 'not-a-number');
        expect(registry.get(strict), 42);
        expect(registry.get(rate), 1.0);
      },
    );

    test('watch only emits for the key it is watching', () async {
      final registry = SettingsRegistry(InMemoryKeyValueStore());
      final a = SettingKey.boolean('a', defaultValue: false);
      final b = SettingKey.boolean('b', defaultValue: false);
      final events = <void>[];
      final sub = registry.watch(a).listen(events.add);
      registry.set(b, true);
      registry.set(a, true);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      await sub.cancel();
    });
  });
}
