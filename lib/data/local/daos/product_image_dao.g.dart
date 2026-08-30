// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_image_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductImageDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $ProductsTable get products => attachedDatabase.products;
  $ProductImagesTable get productImages => attachedDatabase.productImages;
  ProductImageDaoManager get managers => ProductImageDaoManager(this);
}

class ProductImageDaoManager {
  final _$ProductImageDaoMixin _db;
  ProductImageDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ProductImagesTableTableManager get productImages =>
      $$ProductImagesTableTableManager(_db.attachedDatabase, _db.productImages);
}
