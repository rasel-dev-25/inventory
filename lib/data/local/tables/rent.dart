import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'customers.dart';
import 'products.dart';
import 'shared.dart';

/// A configurable pricing tier for book rental, per
/// `notes/business_logic.md` §RentPricingTier. A real table (not a
/// setting) because it is genuinely a set of rows the owner edits, and the
/// v1 app's hardcoded, non-configurable formula
/// (`((pageCount-1)~/100+1)*10.0`) did not match the spec's tier table at
/// all — this table is what makes the tier lookup actually configurable,
/// as the spec asks for explicitly.
@DataClassName('RentPricingTierRow')
class RentPricingTiers extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  IntColumn get maxPages => integer()();
  IntColumn get days => integer()();
  IntColumn get priceMinor => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A book rental, per `notes/business_logic.md` §RentTransaction / §জ.
///
/// There is no `availableCopies` column here or on [Products] — it is
/// derived on read as `product.qty − COUNT(RentTransactions WHERE
/// bookProductId = product.id AND status = active)`, a cheap indexed
/// count, not worth caching. This is unlike `Products.qty` (cached,
/// disciplined single-writer) — the two are different because copies-out
/// is a small, fast aggregate while qty is read on every list row; see
/// ARCHITECTURE.md for the general rule of when a cache is and isn't
/// justified.
@DataClassName('RentTransactionRow')
class RentTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get bookProductId => text().references(Products, #id)();
  TextColumn get customerId => text().references(Customers, #id)();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get depositMinor => integer().withDefault(const Constant(0))();

  IntColumn get extraDayChargeMinor => integer().nullable()();
  IntColumn get damageChargeMinor => integer().nullable()();

  TextColumn get status => textEnum<RentStatus>()();
  DateTimeColumn get returnedDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
