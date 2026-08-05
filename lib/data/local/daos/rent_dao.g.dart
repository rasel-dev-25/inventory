// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rent_dao.dart';

// ignore_for_file: type=lint
mixin _$RentDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $RentPricingTiersTable get rentPricingTiers =>
      attachedDatabase.rentPricingTiers;
  $ProductsTable get products => attachedDatabase.products;
  $CustomersTable get customers => attachedDatabase.customers;
  $RentTransactionsTable get rentTransactions =>
      attachedDatabase.rentTransactions;
  RentDaoManager get managers => RentDaoManager(this);
}

class RentDaoManager {
  final _$RentDaoMixin _db;
  RentDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$RentPricingTiersTableTableManager get rentPricingTiers =>
      $$RentPricingTiersTableTableManager(
        _db.attachedDatabase,
        _db.rentPricingTiers,
      );
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$RentTransactionsTableTableManager get rentTransactions =>
      $$RentTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.rentTransactions,
      );
}
