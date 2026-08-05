import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shared.dart';

part 'category_dao.g.dart';

/// Data access for [Categories] — a simple named-tag list (Book/Date/
/// Attar/Topi/Miswak/Other by default), not a proper foreign key target:
/// `Products.category` is a plain text column, matched by name, not an
/// id reference (see `tables/products.dart`) — the spec treats categories
/// as an editable picklist for organizing products, not a rigid taxonomy.
///
/// No delete method: [Categories] has no `deletedAt` column (unlike every
/// business table with a lifecycle), and the sync engine's
/// `apply_jsonb_upsert` only supports insert/update, not delete — hard
/// deletes are not yet syncable. Renaming/reordering covers the realistic
/// admin need (the default six rarely need removing); a real delete flow
/// is a deliberate gap, not an oversight, tracked for whenever soft-delete
/// support is added to this table.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryRow>> watchAll(String shopId) {
    final query = select(categories)
      ..where((c) => c.shopId.equals(shopId))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch();
  }

  Future<void> create({
    required String id,
    required String shopId,
    required String name,
    required int sortOrder,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        id: id,
        shopId: shopId,
        name: name,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<void> rename(String id, String name) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(name: Value(name)),
    );
  }

  Future<void> reorder(String id, int sortOrder) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(sortOrder: Value(sortOrder)),
    );
  }
}
