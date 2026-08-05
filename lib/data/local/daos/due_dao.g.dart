// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_dao.dart';

// ignore_for_file: type=lint
mixin _$DueDaoMixin on DatabaseAccessor<AppDatabaseV2> {
  $ShopsTable get shops => attachedDatabase.shops;
  $CustomersTable get customers => attachedDatabase.customers;
  $DuesTable get dues => attachedDatabase.dues;
  $DuePaymentsTable get duePayments => attachedDatabase.duePayments;
  DueDaoManager get managers => DueDaoManager(this);
}

class DueDaoManager {
  final _$DueDaoMixin _db;
  DueDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DuesTableTableManager get dues =>
      $$DuesTableTableManager(_db.attachedDatabase, _db.dues);
  $$DuePaymentsTableTableManager get duePayments =>
      $$DuePaymentsTableTableManager(_db.attachedDatabase, _db.duePayments);
}
