// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_image_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerImageDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $CustomersTable get customers => attachedDatabase.customers;
  $CustomerImagesTable get customerImages => attachedDatabase.customerImages;
  CustomerImageDaoManager get managers => CustomerImageDaoManager(this);
}

class CustomerImageDaoManager {
  final _$CustomerImageDaoMixin _db;
  CustomerImageDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$CustomerImagesTableTableManager get customerImages =>
      $$CustomerImagesTableTableManager(
        _db.attachedDatabase,
        _db.customerImages,
      );
}
