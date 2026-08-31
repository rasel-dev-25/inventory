import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/fixed_asset.dart' as domain;
import '../app_database.dart';
import '../tables/assets.dart';

part 'fixed_asset_dao.g.dart';

extension _FixedAssetRowMapping on FixedAssetRow {
  domain.FixedAsset toDomain() {
    return domain.FixedAsset(
      id: id,
      name: name,
      value: Money.fromMinor(valueMinor),
      dateAcquired: dateAcquired,
      sourceType: sourceType,
      sourceProductId: sourceProductId,
    );
  }
}

/// Data access for [FixedAssets]. Only `create` and `softDelete` — no
/// `update` — matching the same convention `ExpenseDao`/`SaleDao`
/// establish for any row with a direct, paired write elsewhere (a cash
/// ledger entry for a cash purchase, a stock movement for a stock
/// conversion): editing the value/source after the fact would leave that
/// paired write silently wrong.
@DriftAccessor(tables: [FixedAssets])
class FixedAssetDao extends DatabaseAccessor<AppDatabase>
    with _$FixedAssetDaoMixin {
  FixedAssetDao(super.db);

  Future<domain.FixedAsset?> getById(String id) async {
    final row = await (select(
      fixedAssets,
    )..where((a) => a.id.equals(id) & a.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.FixedAsset>> watchAll(String shopId) {
    final query = select(fixedAssets)
      ..where((a) => a.shopId.equals(shopId) & a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.dateAcquired)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.FixedAsset asset, {
    required String shopId,
    required DateTime now,
  }) {
    return into(fixedAssets).insert(
      FixedAssetsCompanion.insert(
        id: asset.id,
        shopId: shopId,
        name: asset.name,
        valueMinor: asset.value.minorUnits,
        dateAcquired: asset.dateAcquired,
        sourceType: asset.sourceType,
        sourceProductId: Value(asset.sourceProductId),
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(fixedAssets)..where((a) => a.id.equals(id))).write(
      FixedAssetsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Every soft-deleted [FixedAssets] row for [shopId] — the Recycle
  /// Bin's source list, same shape as `CustomerDao.watchDeleted`.
  Stream<List<FixedAssetRow>> watchDeleted(String shopId) {
    final query = select(fixedAssets)
      ..where((a) => a.shopId.equals(shopId) & a.deletedAt.isNotNull())
      ..orderBy([(a) => OrderingTerm.desc(a.deletedAt)]);
    return query.watch();
  }

  // Deliberately no `restore` — see `FixedAssetUseCases.delete`'s own doc
  // comment for why un-deleting an asset is not safely offered: doing so
  // would need to re-apply whichever cash-ledger or stock-movement entry
  // `delete`'s reversal already negated, and `buildCashLedgerReversal`/
  // `buildStockMovementReversal` cannot safely run a second time on an
  // already-reversed source (see `ledger_reversal.dart`'s own doc
  // comment) — same reasoning `ExpenseDao.watchDeleted` documents.

  /// Permanently deletes a single fixed asset.
  Future<bool> hardDelete(String id) async {
    final rows = await (delete(fixedAssets)..where((a) => a.id.equals(id))).go();
    return rows > 0;
  }
}
