import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../app_database.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/purchase.dart' as domain;
import '../tables/purchases.dart';

part 'purchase_dao.g.dart';

extension _PurchaseItemRowMapping on PurchaseItemRow {
  domain.PurchaseItem toDomain() {
    return domain.PurchaseItem(
      id: id,
      shopName: shopName,
      productId: productId,
      qty: qty,
      unitPrice: Money.fromMinor(unitPriceMinor),
      fundSource: fundSourceType == FundSourceType.shop
          ? FundSource.shop()
          : FundSource.investor(fundSourceInvestorId!),
      isInKind: isInKind,
    );
  }
}

/// Data access for a purchase trip aggregate — [PurchaseTrips] +
/// [PurchaseItems] + [PurchaseOtherCosts] together, since the spec treats
/// a trip and its lines as one unit (§ক): you never save a trip without
/// its items, and you never read one without the other.
///
/// [saveTrip] is the concrete example of the "disciplined single
/// transaction" rule referenced throughout `lib/data/local/tables/`: the
/// trip row, every item row, and every other-cost row are written inside
/// one Drift `transaction()` block. If the app crashes mid-write, either
/// all of it lands or none of it does — never a trip with half its items,
/// which is exactly what the v1 `savePurchase()` (no transaction at all)
/// could produce.
///
/// [domain.OtherCost] has no id of its own in the domain model (it is not
/// an independently addressable entity, just a trip-level line) — this
/// DAO generates a storage-only UUIDv7 for each [PurchaseOtherCosts] row
/// purely to satisfy the table's primary key, and never surfaces that id
/// back to the domain layer.
@DriftAccessor(tables: [PurchaseTrips, PurchaseItems, PurchaseOtherCosts])
class PurchaseDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(super.db);

  static const _uuid = Uuid();

  Future<domain.PurchaseTrip?> getById(String id) async {
    final tripRow = await (select(
      purchaseTrips,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (tripRow == null) return null;

    final itemRows = await (select(
      purchaseItems,
    )..where((i) => i.purchaseTripId.equals(id) & i.deletedAt.isNull())).get();
    final otherCostRows = await (select(
      purchaseOtherCosts,
    )..where((o) => o.purchaseTripId.equals(id))).get();

    return domain.PurchaseTrip(
      id: tripRow.id,
      date: tripRow.date,
      transportCost: Money.fromMinor(tripRow.transportCostMinor),
      otherCosts: [
        for (final o in otherCostRows)
          domain.OtherCost(
            description: o.description,
            amount: Money.fromMinor(o.amountMinor),
          ),
      ],
      cashReturned: Money.fromMinor(tripRow.cashReturnedMinor),
      actualCashTakenOut: tripRow.actualCashTakenOutMinor == null
          ? null
          : Money.fromMinor(tripRow.actualCashTakenOutMinor!),
      items: [for (final i in itemRows) i.toDomain()],
    );
  }

  Stream<List<domain.PurchaseTrip>> watchRecent(
    String shopId, {
    int limit = 50,
  }) {
    final query = select(purchaseTrips)
      ..where((t) => t.shopId.equals(shopId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);
    // Each trip's items/other-costs are loaded lazily via getById once a
    // caller drills into one — a trip list view only needs the header
    // fields, not every line, so this deliberately does not eager-load
    // items for every row in the stream.
    return query.watch().asyncMap((rows) async {
      final trips = <domain.PurchaseTrip>[];
      for (final row in rows) {
        final full = await getById(row.id);
        if (full != null) trips.add(full);
      }
      return trips;
    });
  }

  /// Every trip for [shopId], unlimited — same reasoning as
  /// `SaleDao.watchAll`: [watchRecent]'s cap is right for a scrolling list,
  /// wrong for the v2 Dashboard's totals, which must never silently
  /// under-count once a shop has more trips than that limit.
  Stream<List<domain.PurchaseTrip>> watchAll(String shopId) {
    final query = select(purchaseTrips)
      ..where((t) => t.shopId.equals(shopId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch().asyncMap((rows) async {
      final trips = <domain.PurchaseTrip>[];
      for (final row in rows) {
        final full = await getById(row.id);
        if (full != null) trips.add(full);
      }
      return trips;
    });
  }

  /// Inserts a full trip — the trip row, every item, and every other-cost
  /// — atomically. See the class doc comment for why this must be one
  /// transaction. Does not touch [StockMovements] or [CashLedgerEntries];
  /// pairing this with the matching stock-in and cash-out entries is
  /// `SavePurchaseTripUseCase`'s job (a later PR) — this DAO is the
  /// storage primitive it will call inside its own transaction.
  Future<void> saveTrip(
    domain.PurchaseTrip trip, {
    required String shopId,
    required DateTime now,
  }) async {
    await db.transaction(() async {
      await into(purchaseTrips).insert(
        PurchaseTripsCompanion.insert(
          id: trip.id,
          shopId: shopId,
          date: trip.date,
          transportCostMinor: Value(trip.transportCost.minorUnits),
          cashReturnedMinor: Value(trip.cashReturned.minorUnits),
          actualCashTakenOutMinor: Value(trip.actualCashTakenOut?.minorUnits),
          createdAt: now,
          updatedAt: now,
          syncedAt: now,
        ),
      );

      for (final item in trip.items) {
        await into(purchaseItems).insert(
          PurchaseItemsCompanion.insert(
            id: item.id,
            purchaseTripId: trip.id,
            shopName: item.shopName,
            productId: item.productId,
            qty: item.qty,
            unitPriceMinor: item.unitPrice.minorUnits,
            fundSourceType: item.fundSource.type,
            fundSourceInvestorId: Value(item.fundSource.investorId),
            isInKind: Value(item.isInKind),
            createdAt: now,
            updatedAt: now,
            syncedAt: now,
          ),
        );
      }

      for (final otherCost in trip.otherCosts) {
        await into(purchaseOtherCosts).insert(
          PurchaseOtherCostsCompanion.insert(
            id: _uuid.v7(),
            purchaseTripId: trip.id,
            description: otherCost.description,
            amountMinor: otherCost.amount.minorUnits,
          ),
        );
      }
    });
  }

  /// Only hides the trip from every read (`getById`/`watchRecent`/
  /// `watchAll`) — does **not** touch `StockMovements`/`CashLedgerEntries`.
  /// `DeletePurchaseTripUseCase` pairs this with reversals of both in the
  /// same transaction; calling this method directly (bypassing that use
  /// case) would leave the trip's stock and cash impact in place forever.
  Future<void> softDeleteTrip(String id, DateTime now) {
    return (update(purchaseTrips)..where((t) => t.id.equals(id))).write(
      PurchaseTripsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Every soft-deleted [PurchaseTrips] row for [shopId] — the Recycle
  /// Bin's source list, same shape as `CustomerDao.watchDeleted`. Only
  /// the trip header row, not its items/other-costs — same reasoning
  /// `watchRecent` documents for why a list view doesn't eager-load
  /// those.
  ///
  /// Deliberately no `restore` — see `DeletePurchaseTripUseCase`'s own
  /// doc comment: undoing a deleted trip would need to re-apply the
  /// stock/cash reversal it already wrote, which
  /// `buildStockMovementReversal`/`buildCashLedgerReversal` cannot
  /// safely do a second time.
  Stream<List<PurchaseTripRow>> watchDeleted(String shopId) {
    final query = select(purchaseTrips)
      ..where((t) => t.shopId.equals(shopId) & t.deletedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]);
    return query.watch();
  }
}
