import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'products.dart';
import 'shared.dart';

/// One market/mokam trip. Mirrors `domain/entities/purchase.dart`'s
/// [PurchaseTrip] — see that file for why the per-item fund source split
/// (not stored here) matters.
///
/// Mutable (LWW), not append-only: a purchase trip is a normal editable
/// record right up until the trip's cash effect has been reconciled and
/// mirrored into [CashLedgerEntries] — that mirrored effect is what's
/// immutable, not this row.
class PurchaseTrips extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  DateTimeColumn get date => dateTime()();

  IntColumn get transportCostMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get cashReturnedMinor => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One line within a [PurchaseTrips] row. See
/// `domain/entities/purchase.dart`'s [PurchaseItem] doc comment — the
/// `fundSourceType`/`fundSourceInvestorId`/`isInKind` combination here is
/// Data Integrity Rules #1 and #2 made concrete at the storage layer.
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseTripId => text().references(PurchaseTrips, #id)();
  TextColumn get shopName => text()();
  TextColumn get productId => text().references(Products, #id)();

  RealColumn get qty => real()();
  IntColumn get unitPriceMinor => integer()();

  TextColumn get fundSourceType => textEnum<FundSourceType>()();
  TextColumn get fundSourceInvestorId => text().nullable()();
  BoolColumn get isInKind => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A trip-level cost not tied to a specific item (business_logic.md's
/// `otherCosts[]`) — see the "open question" note in
/// `domain/services/purchase_reconciliation.dart` about why these are not
/// split per fund source.
class PurchaseOtherCosts extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseTripId => text().references(PurchaseTrips, #id)();
  TextColumn get description => text()();
  IntColumn get amountMinor => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
