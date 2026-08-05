// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_asset_dao.dart';

// ignore_for_file: type=lint
mixin _$FixedAssetDaoMixin on DatabaseAccessor<AppDatabaseV2> {
  $ShopsTable get shops => attachedDatabase.shops;
  $ProductsTable get products => attachedDatabase.products;
  $FixedAssetsTable get fixedAssets => attachedDatabase.fixedAssets;
  FixedAssetDaoManager get managers => FixedAssetDaoManager(this);
}

class FixedAssetDaoManager {
  final _$FixedAssetDaoMixin _db;
  FixedAssetDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$FixedAssetsTableTableManager get fixedAssets =>
      $$FixedAssetsTableTableManager(_db.attachedDatabase, _db.fixedAssets);
}
