// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $PurchaseTripsTable get purchaseTrips => attachedDatabase.purchaseTrips;
  $ProductsTable get products => attachedDatabase.products;
  $PurchaseItemsTable get purchaseItems => attachedDatabase.purchaseItems;
  $PurchaseOtherCostsTable get purchaseOtherCosts =>
      attachedDatabase.purchaseOtherCosts;
  PurchaseDaoManager get managers => PurchaseDaoManager(this);
}

class PurchaseDaoManager {
  final _$PurchaseDaoMixin _db;
  PurchaseDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$PurchaseTripsTableTableManager get purchaseTrips =>
      $$PurchaseTripsTableTableManager(_db.attachedDatabase, _db.purchaseTrips);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db.attachedDatabase, _db.purchaseItems);
  $$PurchaseOtherCostsTableTableManager get purchaseOtherCosts =>
      $$PurchaseOtherCostsTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOtherCosts,
      );
}
