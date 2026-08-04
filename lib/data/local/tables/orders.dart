import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'customers.dart';
import 'shared.dart';

/// A customer pre-order, per `notes/business_logic.md` §Order. The
/// "অর্ডার দাতা" tab on the Customer screen is a filtered view over this
/// table joined with [Customers] — see `customers.dart`'s doc comment.
@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get customerId => text().references(Customers, #id)();

  TextColumn get itemDescription => text()();
  DateTimeColumn get requestedDate => dateTime()();
  DateTimeColumn get neededByDate => dateTime().nullable()();
  TextColumn get status => textEnum<OrderStatus>()();
  DateTimeColumn get fulfilledDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
