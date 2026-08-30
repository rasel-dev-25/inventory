// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_asset_image_dao.dart';

// ignore_for_file: type=lint
mixin _$FixedAssetImageDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $ProductsTable get products => attachedDatabase.products;
  $FixedAssetsTable get fixedAssets => attachedDatabase.fixedAssets;
  $FixedAssetImagesTable get fixedAssetImages =>
      attachedDatabase.fixedAssetImages;
  FixedAssetImageDaoManager get managers => FixedAssetImageDaoManager(this);
}

class FixedAssetImageDaoManager {
  final _$FixedAssetImageDaoMixin _db;
  FixedAssetImageDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$FixedAssetsTableTableManager get fixedAssets =>
      $$FixedAssetsTableTableManager(_db.attachedDatabase, _db.fixedAssets);
  $$FixedAssetImagesTableTableManager get fixedAssetImages =>
      $$FixedAssetImagesTableTableManager(
        _db.attachedDatabase,
        _db.fixedAssetImages,
      );
}
