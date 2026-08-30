import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/assets.dart';

part 'fixed_asset_image_dao.g.dart';

@DriftAccessor(tables: [FixedAssetImages, FixedAssets])
class FixedAssetImageDao extends DatabaseAccessor<AppDatabase>
    with _$FixedAssetImageDaoMixin {
  FixedAssetImageDao(super.db);

  Stream<List<FixedAssetImageRow>> watchForShop(String shopId) {
    final query =
        select(fixedAssetImages).join([
            innerJoin(
              fixedAssets,
              fixedAssets.id.equalsExp(fixedAssetImages.assetId),
            ),
          ])
          ..where(
            fixedAssets.shopId.equals(shopId) & fixedAssets.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.desc(fixedAssetImages.createdAt),
            OrderingTerm.asc(fixedAssetImages.sortOrder),
          ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(fixedAssetImages)).toList(),
    );
  }

  Future<FixedAssetImageRow?> getById(String id) {
    return (select(
      fixedAssetImages,
    )..where((image) => image.id.equals(id))).getSingleOrNull();
  }

  Future<void> create(FixedAssetImagesCompanion image) {
    return into(fixedAssetImages).insert(image);
  }

  Future<void> markUploaded({
    required String id,
    required String remoteUrl,
    required DateTime syncedAt,
  }) {
    return (update(
      fixedAssetImages,
    )..where((image) => image.id.equals(id))).write(
      FixedAssetImagesCompanion(
        remoteUrl: Value(remoteUrl),
        syncedAt: Value(syncedAt),
      ),
    );
  }
}
