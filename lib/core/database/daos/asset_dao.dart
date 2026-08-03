import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'asset_dao.g.dart';

@DriftAccessor(tables: [FixedAssets])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<FixedAsset>> getAll() => select(fixedAssets).get();

  Stream<List<FixedAsset>> watchAll() => select(fixedAssets).watch();

  Future<List<FixedAsset>> getByDate(String date) {
    return (select(
      fixedAssets,
    )..where((t) => t.purchaseDate.equals(date))).get();
  }

  Future<void> insertAsset(FixedAssetsCompanion entry) =>
      into(fixedAssets).insert(entry);

  Future<void> updateAsset(String id, FixedAssetsCompanion entry) {
    return (update(fixedAssets)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteAsset(String id) {
    return (delete(fixedAssets)..where((t) => t.id.equals(id))).go();
  }

  Future<double> totalValue() async {
    final result = await (selectOnly(
      fixedAssets,
    )..addColumns([fixedAssets.estimatedValue.sum()])).getSingle();
    return result.read(fixedAssets.estimatedValue.sum()) ?? 0.0;
  }
}
