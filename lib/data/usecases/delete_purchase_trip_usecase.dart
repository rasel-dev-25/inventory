import 'dart:convert';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// Soft-deletes a purchase trip *and* reverses everything
/// [SavePurchaseTripUseCase] wrote alongside it — every `StockMovements`
/// row (and the `Products.qty` cache those movements fed, via
/// `ProductDao.adjustQty`) and every `CashLedgerEntries` row, all keyed by
/// `sourceType: 'purchase', sourceId: trip.id`. See `ledger_reversal.dart`
/// for why these are new, negated rows rather than edits — `StockMovements`/
/// `CashLedgerEntries` are both append-only.
///
/// Did not exist before this use case: `PurchaseDao.softDeleteTrip` was
/// dead code, reachable from no screen, with no wrapper pairing it with
/// the reversal its own doc comment now describes as mandatory. This is
/// that wrapper, built at the same time as the fix — not a pre-existing
/// flow that regressed.
class DeletePurchaseTripUseCase {
  final AppDatabaseV2 db;

  DeletePurchaseTripUseCase(this.db);

  Future<Result<void>> call({
    required String tripId,
    required String shopId,
    required DateTime now,
  }) async {
    final trip = await db.purchaseDao.getById(tripId);
    if (trip == null) {
      return Result.err(NotFoundFailure('purchaseTrip', tripId));
    }

    final stockReversal = await buildStockMovementReversal(
      db: db,
      shopId: shopId,
      sourceType: 'purchase',
      sourceId: tripId,
      date: now,
      now: now,
    );
    final cashReversal = await buildCashLedgerReversal(
      db: db,
      shopId: shopId,
      sourceType: 'purchase',
      sourceId: tripId,
      date: now,
      now: now,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'purchase_trip_deleted',
      upserts: [
        TableUpsert(
          table: 'purchase_trips',
          row: {
            'id': tripId,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
        ...stockReversal.upserts,
        ...cashReversal.upserts,
      ],
      localWrite: () async {
        await db.purchaseDao.softDeleteTrip(tripId, now);
        await stockReversal.localWrite();
        await cashReversal.localWrite();
      },
    );

    // Audit-logged — see `CustomerUseCases.softDelete`'s own doc comment
    // for the scope this belongs to. No `restore` counterpart, and no UI
    // trigger yet either — see `RetentionPolicyUseCase`'s own doc
    // comment on why `PurchaseTrips` is excluded from that policy too.
    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'purchase_trips',
      recordId: tripId,
      oldValueJson: jsonEncode({
        'id': trip.id,
        'date': trip.date.toUtc().toIso8601String(),
        'transport_cost_minor': trip.transportCost.minorUnits,
        'cash_returned_minor': trip.cashReturned.minorUnits,
        'item_count': trip.items.length,
      }),
      now: now,
    );

    return const Result.ok(null);
  }
}
