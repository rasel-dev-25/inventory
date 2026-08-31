import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'shared.dart';

/// Stock items, per `notes/business_logic.md` §Product.
///
/// `fundSourceType`/`fundSourceInvestorId` mirror `domain/entities/fund_source.dart`'s
/// [FundSource] exactly, but as two plain columns rather than one nested
/// object — Drift tables are flat by design. The mapping layer
/// (`lib/data/local`, next PR) is responsible for reconstructing a
/// [FundSource] from these two columns and for enforcing the same
/// invariant [FundSource]'s constructors enforce in Dart (non-null
/// `fundSourceInvestorId` if and only if `fundSourceType == investor`).
///
/// `qty` is a maintained cache, not a free-standing number: it must only
/// ever be written by the same transaction that inserts a matching
/// [StockMovements] row (in the ledger table file). It is always
/// re-derivable by summing that product's movements — this is the
/// "disciplined single write path" pattern, not the denormalized-counter
/// antipattern the v1 `Investors` table's cached totals fell into (those
/// drifted because *multiple* uncoordinated code paths wrote them).
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();

  IntColumn get costPriceMinor => integer()();
  IntColumn get suggestedSellPriceMinor => integer()();
  RealColumn get qty => real().withDefault(const Constant(0))();

  TextColumn get fundSourceType => textEnum<FundSourceType>()();
  TextColumn get fundSourceInvestorId => text().nullable()();

  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get sellUnit => text().withDefault(const Constant('pcs'))();

  BoolColumn get isRentable => boolean().withDefault(const Constant(false))();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();

  /// Only meaningful when [isRentable] is true — the tier lookup at
  /// rent-issue time (`notes/business_logic.md` §জ) is keyed by this.
  /// Nullable for the same reason [isRentable] is a general flag rather
  /// than a category-restricted column: most products never rent, so
  /// most rows never set this.
  IntColumn get pageCount => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Units of measurement (e.g. 'pcs', 'kg', 'box', 'litre', 'dozen', etc.)
@DataClassName('UnitRow')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Product photos, split out from [Products] per an external review's
/// suggestion so a product can have more than one image (gallery, sort
/// order) without a schema change later. Two paths per image (local vs
/// remote) because the two-tier image pipeline (see ARCHITECTURE.md)
/// captures locally first and uploads later — both may be non-null at
/// once during the window between capture and successful upload.
@DataClassName('ProductImageRow')
class ProductImages extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();

  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get thumbnailLocalPath => text().nullable()();
  TextColumn get thumbnailRemoteUrl => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
