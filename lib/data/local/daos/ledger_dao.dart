import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/cash_ledger_entry.dart' as domain;
import '../../../domain/entities/enums.dart';
import '../app_database.dart';
import '../tables/ledger.dart';

part 'ledger_dao.g.dart';

extension _CashLedgerEntryRowMapping on CashLedgerEntryRow {
  domain.CashLedgerEntry toDomain() {
    return domain.CashLedgerEntry(
      id: id,
      amount: Money.fromMinor(amountMinor),
      paymentMethod: paymentMethod,
      sourceType: sourceType,
      sourceId: sourceId,
      description: description,
      date: date,
    );
  }
}

/// Data access for the two append-only ledger tables —
/// [CashLedgerEntries] and [StockMovements]. Insert-only by design (see
/// both tables' own doc comments): there is no update/delete method here
/// on purpose, matching the Postgres mirror's `forbid_update_or_delete`
/// trigger. A mistaken entry is corrected with a reversal row (negated
/// amount/delta, same source), never edited in place.
///
/// Always called from within the same transaction as whatever business
/// event produced the entry (a purchase trip, a sale, a due payment) —
/// see `lib/data/usecases/` — never as a free-standing write, since a
/// ledger row that doesn't trace back to a real business row would be
/// exactly the kind of untraceable cash figure this table exists to
/// prevent.
@DriftAccessor(tables: [CashLedgerEntries, StockMovements])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  Future<void> recordCashLedgerEntry({
    required String id,
    required String shopId,
    required int amountMinor,
    required PaymentMethod paymentMethod,
    required String sourceType,
    required String sourceId,
    required DateTime date,
    required DateTime now,
    String? description,
  }) {
    return into(cashLedgerEntries).insert(
      CashLedgerEntriesCompanion.insert(
        id: id,
        shopId: shopId,
        amountMinor: amountMinor,
        paymentMethod: paymentMethod,
        sourceType: sourceType,
        sourceId: sourceId,
        description: Value(description),
        date: date,
        createdAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Every [CashLedgerEntries] row for [shopId], unfiltered — the raw
  /// input to `calculateCashBalances`/`computeDashboardTotals`. The v2
  /// Dashboard screen filters this itself by `DateRange` for its Day vs.
  /// All-time toggle (see `notes/business_logic.md` §ঝ's explicit "same
  /// function, different input" instruction) rather than this DAO
  /// accepting a date parameter — matches `StockController`'s reasoning
  /// for why `watchSaleMovements` also returns unfiltered rows.
  Stream<List<domain.CashLedgerEntry>> watchAll(String shopId) {
    final query = select(cashLedgerEntries)
      ..where((e) => e.shopId.equals(shopId));
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Every [CashLedgerEntries] row already recorded for one
  /// (`sourceType`, `sourceId`) pair — the exact rows `ledger_reversal.dart`
  /// needs to negate when a source row (an expense, a purchase trip) is
  /// deleted after the fact. Excludes nothing: a source that was already
  /// reversed once and somehow deleted again would still get every prior
  /// entry summed correctly by whatever reads this table, since each
  /// reversal is its own row, never a mutation of the original.
  Future<List<domain.CashLedgerEntry>> getEntriesForSource(
    String sourceType,
    String sourceId,
  ) async {
    final rows =
        await (select(cashLedgerEntries)..where(
              (e) =>
                  e.sourceType.equals(sourceType) & e.sourceId.equals(sourceId),
            ))
            .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  /// Every [StockMovements] row already recorded for one (`sourceType`,
  /// `sourceId`) pair — same reasoning as [getEntriesForSource], for the
  /// stock side of reversing a deleted purchase trip.
  Future<List<StockMovementRow>> getMovementsForSource(
    String sourceType,
    String sourceId,
  ) {
    return (select(stockMovements)..where(
          (m) => m.sourceType.equals(sourceType) & m.sourceId.equals(sourceId),
        ))
        .get();
  }

  /// Every `sale`-sourced [StockMovements] row for [shopId] — the raw data
  /// the v2 Stock screen's "বেশি বিক্রি হওয়া বনাম কমে যাওয়া পণ্য" (top
  /// sellers vs. slow movers) view is aggregated from client-side, per
  /// `notes/business_logic.md` §খ. Deliberately returns the raw rows
  /// rather than a pre-aggregated sum: `StockController` also needs to
  /// group by the screen's live category/investor filter, which this DAO
  /// has no knowledge of.
  Stream<List<StockMovementRow>> watchSaleMovements(String shopId) {
    final query = select(stockMovements)
      ..where((m) => m.shopId.equals(shopId) & m.sourceType.equals('sale'));
    return query.watch();
  }

  /// Every [StockMovements] row for [shopId], any `sourceType` — the raw
  /// input to `computeDashboardTotals`' stock-value figure, which (unlike
  /// [watchSaleMovements]) needs both stock-in (purchases) and stock-out
  /// (sales) movements to compute a net value for the selected
  /// `DateRange`. See that function's own doc comment for why summing
  /// `deltaQty × currentCostPrice` over *any* range — including an
  /// unbounded "all-time" one — is the same formula as today's on-hand
  /// stock value, not a second, divergent calculation.
  Stream<List<StockMovementRow>> watchAllStockMovements(String shopId) {
    final query = select(stockMovements)..where((m) => m.shopId.equals(shopId));
    return query.watch();
  }

  Future<void> recordStockMovement({
    required String id,
    required String shopId,
    required String productId,
    required double deltaQty,
    required String sourceType,
    required DateTime date,
    required DateTime now,
    String? sourceId,
  }) {
    return into(stockMovements).insert(
      StockMovementsCompanion.insert(
        id: id,
        shopId: shopId,
        productId: productId,
        deltaQty: deltaQty,
        sourceType: sourceType,
        sourceId: Value(sourceId),
        date: date,
        createdAt: now,
        syncedAt: now,
      ),
    );
  }
}
