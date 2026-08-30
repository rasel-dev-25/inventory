import 'dart:convert';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// Soft-deletes a sale *and* reverses everything [SaveSaleUseCase] wrote
/// alongside it:
/// - Reverses stock movement (and restores `Products.qty` via `ProductDao.adjustQty`)
/// - Reverses cash ledger entry (negating collected cash in Total Cash)
/// - Soft-deletes any associated [Due] created for an unpaid balance
///
/// All written as one atomic local transaction + one outbox event for Supabase.
class DeleteSaleUseCase {
  final AppDatabase db;

  DeleteSaleUseCase(this.db);

  Future<Result<void>> call({
    required String saleId,
    required String shopId,
    required DateTime now,
  }) async {
    final sale = await db.saleDao.getById(saleId);
    if (sale == null) {
      return Result.err(NotFoundFailure('sale', saleId));
    }

    final stockReversal = await buildStockMovementReversal(
      db: db,
      shopId: shopId,
      sourceType: 'sale',
      sourceId: saleId,
      date: now,
      now: now,
    );

    final cashReversal = await buildCashLedgerReversal(
      db: db,
      shopId: shopId,
      sourceType: 'sale',
      sourceId: saleId,
      date: now,
      now: now,
    );

    final due = await db.dueDao.getBySource('sale', saleId);

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'sales',
        row: {
          'id': saleId,
          'shop_id': shopId,
          'deleted_at': now.toIso8601String(),
        },
      ),
      ...stockReversal.upserts,
      ...cashReversal.upserts,
      if (due != null)
        TableUpsert(
          table: 'dues',
          row: {
            'id': due.id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
    ];

    await writeAndEnqueue(
      db: db,
      eventType: 'sale_deleted',
      upserts: upserts,
      localWrite: () async {
        await db.saleDao.softDelete(saleId, now);
        await stockReversal.localWrite();
        await cashReversal.localWrite();
        if (due != null) {
          await db.dueDao.softDelete(due.id, now);
        }
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'sales',
      recordId: saleId,
      oldValueJson: jsonEncode({
        'id': sale.id,
        'product_id': sale.productId,
        'qty': sale.qty,
        'actual_sell_price_minor': sale.actualSellPrice.minorUnits,
        'cost_price_minor_at_sale': sale.costPriceAtSale.minorUnits,
        'date': sale.date.toUtc().toIso8601String(),
        'payment_status': sale.paymentStatus.name,
      }),
      now: now,
    );

    return const Result.ok(null);
  }
}
