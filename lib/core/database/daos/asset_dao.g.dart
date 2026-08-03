// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $FixedAssetsTable get fixedAssets => attachedDatabase.fixedAssets;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$FixedAssetsTableTableManager get fixedAssets =>
      $$FixedAssetsTableTableManager(_db.attachedDatabase, _db.fixedAssets);
}
