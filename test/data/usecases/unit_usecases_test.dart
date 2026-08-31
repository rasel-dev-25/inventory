import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/daos/unit_dao.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/unit_usecases.dart';

void main() {
  late AppDatabase db;
  late UnitUseCases useCases;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = UnitUseCases(db);

    final now = DateTime.utc(2026, 1, 1);
    await db.unitDao.seedDefaultUnits(defaultShopId, now);
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds default units properly', () async {
    final units = await useCases.getAll(defaultShopId);
    expect(units.length, UnitDao.defaultUnitNames.length);
    expect(units.map((u) => u.name), containsAll(['pcs', 'kg', 'box', 'litre']));
  });

  test('creates a new custom unit and enqueues sync outbox entry', () async {
    final now = DateTime.utc(2026, 1, 2);
    final created = await useCases.create(
      shopId: defaultShopId,
      name: 'bosta',
      now: now,
    );

    expect(created.name, 'bosta');

    final allUnits = await useCases.getAll(defaultShopId);
    expect(allUnits.map((u) => u.name), contains('bosta'));

    final outboxEntries = await db.select(db.syncOutboxEntries).get();
    expect(
      outboxEntries.any((e) => e.eventType == 'unit_created'),
      isTrue,
    );
  });

  test('renames an existing unit', () async {
    final now = DateTime.utc(2026, 1, 2);
    final created = await useCases.create(
      shopId: defaultShopId,
      name: 'pkt',
      now: now,
    );

    await useCases.rename(
      id: created.id,
      shopId: defaultShopId,
      name: 'packet',
      now: now.add(const Duration(hours: 1)),
    );

    final allUnits = await useCases.getAll(defaultShopId);
    expect(allUnits.map((u) => u.name), contains('packet'));
    expect(allUnits.map((u) => u.name), isNot(contains('pkt')));
  });

  test('soft-deletes a unit', () async {
    final now = DateTime.utc(2026, 1, 2);
    final created = await useCases.create(
      shopId: defaultShopId,
      name: 'roll-custom',
      now: now,
    );

    await useCases.delete(
      id: created.id,
      shopId: defaultShopId,
      now: now.add(const Duration(hours: 1)),
    );

    final allUnits = await useCases.getAll(defaultShopId);
    expect(allUnits.map((u) => u.name), isNot(contains('roll-custom')));

    final outboxEntries = await db.select(db.syncOutboxEntries).get();
    expect(
      outboxEntries.any((e) => e.eventType == 'unit_deleted'),
      isTrue,
    );
  });
}
