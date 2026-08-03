// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchasesTable get purchases => attachedDatabase.purchases;
  $PurchaseItemsTable get purchaseItems => attachedDatabase.purchaseItems;
  $TransportCostsTable get transportCosts => attachedDatabase.transportCosts;
  $OtherCostsTable get otherCosts => attachedDatabase.otherCosts;
  PurchaseDaoManager get managers => PurchaseDaoManager(this);
}

class PurchaseDaoManager {
  final _$PurchaseDaoMixin _db;
  PurchaseDaoManager(this._db);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db.attachedDatabase, _db.purchases);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db.attachedDatabase, _db.purchaseItems);
  $$TransportCostsTableTableManager get transportCosts =>
      $$TransportCostsTableTableManager(
        _db.attachedDatabase,
        _db.transportCosts,
      );
  $$OtherCostsTableTableManager get otherCosts =>
      $$OtherCostsTableTableManager(_db.attachedDatabase, _db.otherCosts);
}
