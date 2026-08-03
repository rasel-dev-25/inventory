// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  $CustomerPurchasesTable get customerPurchases =>
      attachedDatabase.customerPurchases;
  $CustomerOrdersTable get customerOrders => attachedDatabase.customerOrders;
  $CustomerTypesTable get customerTypes => attachedDatabase.customerTypes;
  CustomerDaoManager get managers => CustomerDaoManager(this);
}

class CustomerDaoManager {
  final _$CustomerDaoMixin _db;
  CustomerDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
  $$CustomerPurchasesTableTableManager get customerPurchases =>
      $$CustomerPurchasesTableTableManager(
        _db.attachedDatabase,
        _db.customerPurchases,
      );
  $$CustomerOrdersTableTableManager get customerOrders =>
      $$CustomerOrdersTableTableManager(
        _db.attachedDatabase,
        _db.customerOrders,
      );
  $$CustomerTypesTableTableManager get customerTypes =>
      $$CustomerTypesTableTableManager(_db.attachedDatabase, _db.customerTypes);
}
