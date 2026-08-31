import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products.dart';

part 'product_image_dao.g.dart';

@DriftAccessor(tables: [ProductImages, Products])
class ProductImageDao extends DatabaseAccessor<AppDatabase>
    with _$ProductImageDaoMixin {
  ProductImageDao(super.db);

  Stream<List<ProductImageRow>> watchForProduct(String productId) {
    final query = select(productImages)
      ..where((image) => image.productId.equals(productId))
      ..orderBy([
        (image) => OrderingTerm.asc(image.sortOrder),
        (image) => OrderingTerm.asc(image.createdAt),
      ]);
    return query.watch();
  }

  Stream<List<ProductImageRow>> watchForShop(String shopId) {
    final query =
        select(productImages).join([
            innerJoin(products, products.id.equalsExp(productImages.productId)),
          ])
          ..where(products.shopId.equals(shopId) & products.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(productImages.sortOrder),
            OrderingTerm.asc(productImages.createdAt),
          ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(productImages)).toList(),
    );
  }

  Future<ProductImageRow?> getById(String id) {
    return (select(
      productImages,
    )..where((image) => image.id.equals(id))).getSingleOrNull();
  }

  Future<void> create(ProductImagesCompanion image) {
    return into(productImages).insert(image);
  }

  Future<void> markUploaded({
    required String id,
    required String remoteUrl,
    required DateTime syncedAt,
  }) {
    return (update(productImages)..where((image) => image.id.equals(id))).write(
      ProductImagesCompanion(
        remoteUrl: Value(remoteUrl),
        syncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> deleteImage(String id) {
    return (delete(productImages)..where((image) => image.id.equals(id))).go();
  }
}
