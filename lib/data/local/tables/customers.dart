import 'package:drift/drift.dart';

import 'shared.dart';

/// One row per customer. Per `notes/business_logic.md` §Customer, "buyer /
/// order-giver / renter / due-taker" are explicitly *views* over this
/// table joined with Sales/Orders/RentTransactions/Dues — there is no
/// `type` column here, unlike v1's `Customers.type`. Classifying a
/// customer is a query concern (in the repository layer), not a stored
/// fact, so one person can be a buyer, a renter, and a due-taker at once
/// without three disconnected rows.
@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get contact => text().nullable()();

  BoolColumn get suspicionFlag =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerImageRow')
class CustomerImages extends Table {
  TextColumn get id => text()();
  TextColumn get customerId =>
      text().references(Customers, #id, onDelete: KeyAction.cascade)();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}
