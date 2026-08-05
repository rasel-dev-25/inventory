import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/drift_key_value_store.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late DriftKeyValueStore store;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    store = DriftKeyValueStore(db.appSettingsDao);
  });

  tearDown(() async {
    store.dispose();
    await db.close();
  });

  test('read returns null for a key nothing has written', () async {
    await store.hydrate();
    expect(store.read('missing'), isNull);
  });

  test('write is immediately visible to read, before Drift confirms it', () {
    // No await on the underlying Drift write — this is the whole point of
    // the cache: `read` must never have to wait on the database.
    store.write('k', 'v');
    expect(store.read('k'), 'v');
  });

  test(
    'a write persists across a fresh store instance once hydrated',
    () async {
      store.write('k', 'v');
      // Give the fire-and-forget Drift write a chance to actually land.
      await Future<void>.delayed(Duration.zero);

      final secondStore = DriftKeyValueStore(db.appSettingsDao);
      await secondStore.hydrate();
      expect(secondStore.read('k'), 'v');
      secondStore.dispose();
    },
  );

  test(
    'delete removes the value from the cache and, eventually, storage',
    () async {
      store.write('k', 'v');
      await Future<void>.delayed(Duration.zero);
      store.delete('k');
      expect(store.read('k'), isNull);
      await Future<void>.delayed(Duration.zero);

      final secondStore = DriftKeyValueStore(db.appSettingsDao);
      await secondStore.hydrate();
      expect(secondStore.read('k'), isNull);
      secondStore.dispose();
    },
  );

  test('changes emits the key on write and on delete', () async {
    final emitted = <String>[];
    final sub = store.changes.listen(emitted.add);
    store.write('a', '1');
    store.delete('a');
    await Future<void>.delayed(Duration.zero);
    expect(emitted, ['a', 'a']);
    await sub.cancel();
  });

  test(
    'hydrate loads every previously-written key, not just the last one',
    () async {
      store.write('a', '1');
      store.write('b', '2');
      await Future<void>.delayed(Duration.zero);

      final secondStore = DriftKeyValueStore(db.appSettingsDao);
      await secondStore.hydrate();
      expect(secondStore.read('a'), '1');
      expect(secondStore.read('b'), '2');
      secondStore.dispose();
    },
  );
}
