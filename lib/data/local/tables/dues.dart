import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'customers.dart';
import 'shared.dart';

/// An outstanding balance from a credit sale or an unpaid rental charge,
/// per `notes/business_logic.md` §Due.
///
/// [status] and the running total are updated exclusively by
/// `PayDueUseCase` (domain layer, next PR) inside one transaction together
/// with the [DuePayments] row that caused the change — the same
/// "disciplined single write path" pattern as `Products.qty`, not a
/// separately-recomputed aggregate. [paidAmountMinor] is always
/// re-derivable by summing this due's [DuePayments] if it's ever suspected
/// of drifting.
///
/// [sourceId] is polymorphic (`sourceType` says whether it points at a
/// `Sales.id` or a `RentTransactions.id`) — Drift can't express a
/// conditional foreign key, so this reference is enforced in the
/// repository layer, not the schema.
class Dues extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get customerId => text().references(Customers, #id)();

  TextColumn get sourceType => textEnum<DueSourceType>()();
  TextColumn get sourceId => text()();

  IntColumn get originalAmountMinor => integer()();
  IntColumn get paidAmountMinor => integer().withDefault(const Constant(0))();
  IntColumn get promisedDays => integer().nullable()();
  TextColumn get status => textEnum<DueStatus>()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One payment against a [Dues] row. Append-only — a due is never "edited"
/// down, it accumulates payments, same reasoning as [CashLedgerEntries].
class DuePayments extends Table {
  TextColumn get id => text()();
  TextColumn get dueId => text().references(Dues, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
