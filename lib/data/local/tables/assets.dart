import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'products.dart';
import 'shared.dart';

/// A fixed asset, per `notes/business_logic.md`'s two creation paths:
/// [FixedAssetSource.shopCashPurchase] (reduces cash, mirrored into
/// [CashLedgerEntries]) or [FixedAssetSource.convertedFromStock] (reduces
/// the source product's qty via a [StockMovements] row, zero cash effect)
/// — [sourceProductId] is only set for the latter. The v1 schema had
/// neither this distinction nor the convert-from-stock path at all.
class FixedAssets extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  IntColumn get valueMinor => integer()();
  DateTimeColumn get dateAcquired => dateTime()();

  TextColumn get sourceType => textEnum<FixedAssetSource>()();
  TextColumn get sourceProductId =>
      text().nullable().references(Products, #id)();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
