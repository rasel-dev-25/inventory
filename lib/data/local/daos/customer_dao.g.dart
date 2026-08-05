// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerDaoMixin on DatabaseAccessor<AppDatabaseV2> {
  $ShopsTable get shops => attachedDatabase.shops;
  $CustomersTable get customers => attachedDatabase.customers;
  $DuesTable get dues => attachedDatabase.dues;
  $OrdersTable get orders => attachedDatabase.orders;
  $ProductsTable get products => attachedDatabase.products;
  $RentTransactionsTable get rentTransactions =>
      attachedDatabase.rentTransactions;
  $SalesTable get sales => attachedDatabase.sales;
  CustomerDaoManager get managers => CustomerDaoManager(this);
}

class CustomerDaoManager {
  final _$CustomerDaoMixin _db;
  CustomerDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DuesTableTableManager get dues =>
      $$DuesTableTableManager(_db.attachedDatabase, _db.dues);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$RentTransactionsTableTableManager get rentTransactions =>
      $$RentTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.rentTransactions,
      );
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
}
