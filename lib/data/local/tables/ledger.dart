import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'products.dart';
import 'shared.dart';

/// The single source of truth for every cash figure in the app —
/// Total Cash, the three payment-method sub-balances, and the per-trip
/// reconciliation check are all just sums over this table, never a
/// bespoke formula that touches five other tables directly.
///
/// **Append-only.** No `updatedAt`, no `deletedAt` — there is deliberately
/// no way to edit or delete a row from the Dart API surface, and the
/// Postgres mirror of this table (next PR) enforces the same rule with a
/// `BEFORE UPDATE OR DELETE` trigger that raises. A mistaken entry is
/// corrected by inserting a reversal row (`amountMinor` negated,
/// `sourceType` unchanged, a note explaining why), never by editing the
/// original. This directly replaces the v1 dashboard's ad hoc formula
/// (`Σ(Sale.amount where type=='cash')` — one table, ignoring due
/// payments, rent income, purchases, expenses, and repayments entirely).
///
/// [amountMinor] is signed: positive = cash in, negative = cash out.
/// [sourceType]/[sourceId] point at whichever row caused this entry (a
/// Sale, a DuePayment, a RentTransaction return, a PurchaseTrip, an
/// Expense, or an InvestorRepayment) — polymorphic, so not a Drift
/// `.references()` foreign key; enforced by the use case that writes both
/// rows in the same transaction.
class CashLedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();

  IntColumn get amountMinor => integer()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();

  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  TextColumn get description => text().nullable()();

  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The single source of truth for stock quantity changes — every
/// increase/decrease in a product's on-hand quantity is one row here, not
/// a direct mutation of `Products.qty`. `Products.qty` remains a
/// maintained cache for fast reads, but is always re-derivable by summing
/// a product's movements, so it can never silently drift the way the v1
/// schema's cached investor totals did.
///
/// **Append-only**, same reasoning as [CashLedgerEntries]. [deltaQty] is
/// signed: positive = stock in (purchase, rent return), negative = stock
/// out (sale, rent-out, converted to a fixed asset, manual correction).
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get productId => text().references(Products, #id)();

  RealColumn get deltaQty => real()();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text().nullable()();

  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
