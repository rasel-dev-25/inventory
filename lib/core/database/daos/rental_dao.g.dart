// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_dao.dart';

// ignore_for_file: type=lint
mixin _$RentalDaoMixin on DatabaseAccessor<AppDatabase> {
  $RentBooksTable get rentBooks => attachedDatabase.rentBooks;
  $BookRentalsTable get bookRentals => attachedDatabase.bookRentals;
  RentalDaoManager get managers => RentalDaoManager(this);
}

class RentalDaoManager {
  final _$RentalDaoMixin _db;
  RentalDaoManager(this._db);
  $$RentBooksTableTableManager get rentBooks =>
      $$RentBooksTableTableManager(_db.attachedDatabase, _db.rentBooks);
  $$BookRentalsTableTableManager get bookRentals =>
      $$BookRentalsTableTableManager(_db.attachedDatabase, _db.bookRentals);
}
