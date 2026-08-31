import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/product_unit.dart';
import '../app_database.dart';
import '../tables/products.dart';
import '../tables/shared.dart';

part 'unit_dao.g.dart';

extension _UnitRowMapping on UnitRow {
  ProductUnit toDomain() {
    return ProductUnit(
      id: id,
      name: name,
      sortOrder: sortOrder,
    );
  }
}

/// Data access for [Units] — the picklist of units (pcs, kg, gm, box, litre, etc.)
/// available for products in a shop.
@DriftAccessor(tables: [Units, Shops])
class UnitDao extends DatabaseAccessor<AppDatabase> with _$UnitDaoMixin {
  UnitDao(super.db);

  static const _uuid = Uuid();

  static const defaultUnitNames = [
    'pcs',
    'kg',
    'gm',
    'box',
    'pack',
    'litre',
    'ml',
    'pair',
    'set',
    'roll',
    'dozen',
  ];

  Stream<List<ProductUnit>> watchAll(String shopId) {
    final query = select(units)
      ..where((u) => u.shopId.equals(shopId) & u.deletedAt.isNull())
      ..orderBy([(u) => OrderingTerm.asc(u.sortOrder), (u) => OrderingTerm.asc(u.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<List<ProductUnit>> getAll(String shopId) async {
    final rows = await (select(units)
          ..where((u) => u.shopId.equals(shopId) & u.deletedAt.isNull())
          ..orderBy([(u) => OrderingTerm.asc(u.sortOrder), (u) => OrderingTerm.asc(u.name)]))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<void> create({
    required String id,
    required String shopId,
    required String name,
    required int sortOrder,
    required DateTime now,
  }) {
    return into(units).insert(
      UnitsCompanion.insert(
        id: id,
        shopId: shopId,
        name: name,
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> rename({
    required String id,
    required String name,
    required DateTime now,
  }) {
    return (update(units)..where((u) => u.id.equals(id))).write(
      UnitsCompanion(
        name: Value(name),
        updatedAt: Value(now),
      ),
    );
  }

  Future<UnitRow?> getByName(String shopId, String name) {
    return (select(units)
          ..where((u) => u.shopId.equals(shopId) & u.name.equals(name)))
        .getSingleOrNull();
  }

  Future<void> restore({
    required String id,
    required DateTime now,
  }) {
    return (update(units)..where((u) => u.id.equals(id))).write(
      UnitsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> softDelete({
    required String id,
    required DateTime now,
  }) {
    return (update(units)..where((u) => u.id.equals(id))).write(
      UnitsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Seeds default standard units if no units exist yet for [shopId].
  Future<void> seedDefaultUnits(String shopId, DateTime now) async {
    final existing = await (select(units)
          ..where((u) => u.shopId.equals(shopId))
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return;

    for (int i = 0; i < defaultUnitNames.length; i++) {
      await into(units).insert(
        UnitsCompanion.insert(
          id: _uuid.v7(),
          shopId: shopId,
          name: defaultUnitNames[i],
          sortOrder: Value(i + 1),
          createdAt: now,
          updatedAt: now,
          syncedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}
