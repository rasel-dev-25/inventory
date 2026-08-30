import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/services/purchase_reconciliation.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// Corrects a purchase without mutating append-only stock/cash facts.
///
/// The original trip is soft-deleted and its stock/cash effects are reversed;
/// the corrected trip is written with a fresh aggregate id. Keeping the
/// correction as one outbox event makes the same state converge in Supabase.
class EditPurchaseTripUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  EditPurchaseTripUseCase(this.db);

  Future<Result<void>> call({
    required String originalTripId,
    required PurchaseTrip replacement,
    required String shopId,
    required DateTime now,
  }) async {
    final original = await db.purchaseDao.getById(originalTripId);
    if (original == null) {
      return Result.err(NotFoundFailure('purchaseTrip', originalTripId));
    }

    final stockReversal = await buildStockMovementReversal(
      db: db,
      shopId: shopId,
      sourceType: 'purchase',
      sourceId: originalTripId,
      date: now,
      now: now,
    );
    final cashReversal = await buildCashLedgerReversal(
      db: db,
      shopId: shopId,
      sourceType: 'purchase',
      sourceId: originalTripId,
      date: now,
      now: now,
    );

    final reconciliation = reconcilePurchaseTrip(replacement);
    final tripDateIso = replacement.date.toUtc().toIso8601String();
    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'purchase_trips',
        row: {
          'id': originalTripId,
          'shop_id': shopId,
          'deleted_at': now.toIso8601String(),
        },
      ),
      ...stockReversal.upserts,
      ...cashReversal.upserts,
      TableUpsert(
        table: 'purchase_trips',
        row: {
          'id': replacement.id,
          'shop_id': shopId,
          'date': tripDateIso,
          'transport_cost_minor': replacement.transportCost.minorUnits,
          'cash_returned_minor': replacement.cashReturned.minorUnits,
          'actual_cash_taken_out_minor':
              replacement.actualCashTakenOut?.minorUnits,
        },
      ),
    ];

    final movements = <({String id, String productId, double deltaQty})>[];
    for (final item in replacement.items) {
      upserts.add(
        TableUpsert(
          table: 'purchase_items',
          row: {
            'id': item.id,
            'purchase_trip_id': replacement.id,
            'shop_name': item.shopName,
            'product_id': item.productId,
            'qty': item.qty,
            'unit_price_minor': item.unitPrice.minorUnits,
            'fund_source_type': item.fundSource.type.name,
            'fund_source_investor_id': item.fundSource.investorId,
            'is_in_kind': item.isInKind,
          },
        ),
      );
      final movementId = _uuid.v7();
      movements.add((
        id: movementId,
        productId: item.productId,
        deltaQty: item.qty,
      ));
      upserts.add(
        TableUpsert(
          table: 'stock_movements',
          row: {
            'id': movementId,
            'shop_id': shopId,
            'product_id': item.productId,
            'delta_qty': item.qty,
            'source_type': 'purchase',
            'source_id': replacement.id,
            'date': tripDateIso,
          },
        ),
      );
    }

    for (final other in replacement.otherCosts) {
      final costId = _uuid.v7();
      upserts.add(
        TableUpsert(
          table: 'purchase_other_costs',
          row: {
            'id': costId,
            'purchase_trip_id': replacement.id,
            'description': other.description,
            'amount_minor': other.amount.minorUnits,
          },
        ),
      );
    }

    final ledgerEntries = <({String id, int amountMinor})>[];
    for (final bucket in reconciliation.byFundSource) {
      if (bucket.amount.minorUnits == 0) continue;
      final ledgerId = _uuid.v7();
      final amountMinor = -bucket.amount.minorUnits;
      ledgerEntries.add((id: ledgerId, amountMinor: amountMinor));
      upserts.add(
        TableUpsert(
          table: 'cash_ledger_entries',
          row: {
            'id': ledgerId,
            'shop_id': shopId,
            'amount_minor': amountMinor,
            'payment_method': PaymentMethod.cash.name,
            'source_type': 'purchase',
            'source_id': replacement.id,
            'date': tripDateIso,
          },
        ),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'purchase_trip_edited',
      upserts: upserts,
      localWrite: () async {
        await db.purchaseDao.softDeleteTrip(originalTripId, now);
        await stockReversal.localWrite();
        await cashReversal.localWrite();
        await db.purchaseDao.saveTrip(replacement, shopId: shopId, now: now);
        for (final item in replacement.items) {
          await db.productDao.adjustQty(item.productId, item.qty, now);
        }
        for (final movement in movements) {
          await db.ledgerDao.recordStockMovement(
            id: movement.id,
            shopId: shopId,
            productId: movement.productId,
            deltaQty: movement.deltaQty,
            sourceType: 'purchase',
            sourceId: replacement.id,
            date: replacement.date,
            now: now,
          );
        }
        for (final entry in ledgerEntries) {
          await db.ledgerDao.recordCashLedgerEntry(
            id: entry.id,
            shopId: shopId,
            amountMinor: entry.amountMinor,
            paymentMethod: PaymentMethod.cash,
            sourceType: 'purchase',
            sourceId: replacement.id,
            date: replacement.date,
            now: now,
          );
        }
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'update',
      changedTableName: 'purchase_trips',
      recordId: replacement.id,
      oldValueJson: jsonEncode({
        'id': original.id,
        'date': original.date.toUtc().toIso8601String(),
        'transport_cost_minor': original.transportCost.minorUnits,
        'cash_returned_minor': original.cashReturned.minorUnits,
        'item_count': original.items.length,
      }),
      now: now,
    );

    return const Result.ok(null);
  }
}
