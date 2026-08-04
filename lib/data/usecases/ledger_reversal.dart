import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';

const _uuid = Uuid();

/// What a use case needs to fold a reversal into its own atomic write:
/// the outbox upserts to add to its own list, and a closure that performs
/// the actual local writes — meant to be awaited *inside* the same
/// `writeAndEnqueue` `localWrite` callback that also does whatever else
/// the use case is doing (e.g. soft-deleting the source row), so a crash
/// mid-write can never leave a reversal without its deletion or vice
/// versa.
class ReversalWrite {
  final List<TableUpsert> upserts;
  final Future<void> Function() localWrite;

  const ReversalWrite({required this.upserts, required this.localWrite});

  static const empty = ReversalWrite(upserts: [], localWrite: _noop);
  static Future<void> _noop() async {}
}

/// Builds the reversal for every [CashLedgerEntries] row already recorded
/// for one (`sourceType`, `sourceId`) pair — new, negated rows, never an
/// edit/delete of the originals, per that table's append-only design (see
/// its own doc comment). This is the fix for the gap `ExpenseDao.softDelete`/
/// `PurchaseDao.softDeleteTrip` used to leave: soft-deleting a source row
/// hid it from every read, but its cash-out impact stayed in Total Cash
/// forever, with nothing to reverse it.
///
/// Safe to call on a source with zero prior entries (an expense recorded
/// with a zero-value ledger write never happens per `ExpenseUseCases`'
/// own validation, but this doesn't assume that) — returns
/// [ReversalWrite.empty] in that case.
Future<ReversalWrite> buildCashLedgerReversal({
  required AppDatabaseV2 db,
  required String shopId,
  required String sourceType,
  required String sourceId,
  required DateTime date,
  required DateTime now,
}) async {
  final existing = await db.ledgerDao.getEntriesForSource(sourceType, sourceId);
  if (existing.isEmpty) return ReversalWrite.empty;

  final dateIso = date.toUtc().toIso8601String();
  final upserts = <TableUpsert>[];
  final writes = <Future<void> Function()>[];

  for (final entry in existing) {
    final reversalId = _uuid.v7();
    final amountMinor = -entry.amount.minorUnits;
    upserts.add(
      TableUpsert(
        table: 'cash_ledger_entries',
        row: {
          'id': reversalId,
          'shop_id': shopId,
          'amount_minor': amountMinor,
          'payment_method': entry.paymentMethod.name,
          'source_type': sourceType,
          'source_id': sourceId,
          'description': 'Reversal of deleted $sourceType',
          'date': dateIso,
        },
      ),
    );
    writes.add(
      () => db.ledgerDao.recordCashLedgerEntry(
        id: reversalId,
        shopId: shopId,
        amountMinor: amountMinor,
        paymentMethod: entry.paymentMethod,
        sourceType: sourceType,
        sourceId: sourceId,
        date: date,
        now: now,
        description: 'Reversal of deleted $sourceType',
      ),
    );
  }

  return ReversalWrite(
    upserts: upserts,
    localWrite: () async {
      for (final write in writes) {
        await write();
      }
    },
  );
}

/// Same reasoning as [buildCashLedgerReversal], for the stock side of
/// deleting a purchase trip — reverses every [StockMovements] row for
/// (`sourceType`, `sourceId`) *and* the matching `Products.qty` cache
/// (via `ProductDao.adjustQty`), so a deleted trip's stock impact doesn't
/// silently stay on the shelf.
Future<ReversalWrite> buildStockMovementReversal({
  required AppDatabaseV2 db,
  required String shopId,
  required String sourceType,
  required String sourceId,
  required DateTime date,
  required DateTime now,
}) async {
  final existing = await db.ledgerDao.getMovementsForSource(
    sourceType,
    sourceId,
  );
  if (existing.isEmpty) return ReversalWrite.empty;

  final dateIso = date.toUtc().toIso8601String();
  final upserts = <TableUpsert>[];
  final writes = <Future<void> Function()>[];

  for (final movement in existing) {
    final reversalId = _uuid.v7();
    final deltaQty = -movement.deltaQty;
    upserts.add(
      TableUpsert(
        table: 'stock_movements',
        row: {
          'id': reversalId,
          'shop_id': shopId,
          'product_id': movement.productId,
          'delta_qty': deltaQty,
          'source_type': sourceType,
          'source_id': sourceId,
          'date': dateIso,
        },
      ),
    );
    writes.add(() async {
      await db.ledgerDao.recordStockMovement(
        id: reversalId,
        shopId: shopId,
        productId: movement.productId,
        deltaQty: deltaQty,
        sourceType: sourceType,
        sourceId: sourceId,
        date: date,
        now: now,
      );
      await db.productDao.adjustQty(movement.productId, deltaQty, now);
    });
  }

  return ReversalWrite(
    upserts: upserts,
    localWrite: () async {
      for (final write in writes) {
        await write();
      }
    },
  );
}
