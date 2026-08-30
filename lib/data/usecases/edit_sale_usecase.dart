import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/due.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/sale.dart';
import '../../domain/services/due_lifecycle.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// Edits an existing [Sale] by reversing the prior sale's stock and cash
/// impacts, and reapplying the newly updated quantity, pricing, cash collection,
/// and due balance atomically in one transaction with outbox synchronization.
class EditSaleUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  EditSaleUseCase(this.db);

  Future<Result<void>> call({
    required String saleId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    required String shopId,
    required DateTime now,
    String? customerId,
    int? promisedDays,
  }) async {
    if (qty <= 0) {
      return const Result.err(
        ValidationFailure('qty', 'Quantity must be positive'),
      );
    }
    if (amountReceivedNow.isNegative) {
      return const Result.err(
        ValidationFailure(
          'amountReceivedNow',
          'Amount received cannot be negative',
        ),
      );
    }

    final existingSale = await db.saleDao.getById(saleId);
    if (existingSale == null) {
      return Result.err(NotFoundFailure('sale', saleId));
    }

    final product = await db.productDao.getById(existingSale.productId);
    if (product == null) {
      return Result.err(NotFoundFailure('product', existingSale.productId));
    }

    // Available stock including the units already allocated to this sale
    final effectiveAvailableQty = product.qty + existingSale.qty;
    if (qty > effectiveAvailableQty) {
      return Result.err(
        BusinessRuleFailure(
          'Not enough stock: only $effectiveAvailableQty of ${product.name} available',
        ),
      );
    }

    final saleTotal = actualSellPrice * qty;
    if (amountReceivedNow > saleTotal) {
      return const Result.err(
        BusinessRuleFailure('Amount received cannot exceed the sale total'),
      );
    }

    final remaining = saleTotal - amountReceivedNow;
    if (remaining.isPositive && (customerId == null || customerId.isEmpty)) {
      return const Result.err(
        ValidationFailure('customerId', 'Select a customer for the due amount'),
      );
    }

    final PaymentStatus paymentStatus;
    if (remaining.isZero) {
      paymentStatus = PaymentStatus.fullCash;
    } else if (amountReceivedNow.isZero) {
      paymentStatus = PaymentStatus.fullDue;
    } else {
      paymentStatus = PaymentStatus.partial;
    }

    // 1. Reversals of prior sale
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

    final oldDue = await db.dueDao.getBySource('sale', saleId);

    // 2. New updated sale entity
    final updatedSale = existingSale.copyWith(
      qty: qty,
      actualSellPrice: actualSellPrice,
      customerId: customerId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
    );

    // 3. New movements & entries
    final newMovementId = _uuid.v7();
    final newMovementRow = {
      'id': newMovementId,
      'shop_id': shopId,
      'product_id': existingSale.productId,
      'delta_qty': -qty,
      'source_type': 'sale',
      'source_id': saleId,
      'date': now.toIso8601String(),
    };

    final newCashLedgerId = _uuid.v7();
    final newCashLedgerRow = amountReceivedNow.isPositive
        ? {
            'id': newCashLedgerId,
            'shop_id': shopId,
            'amount_minor': amountReceivedNow.minorUnits,
            'payment_method': paymentMethod.name,
            'source_type': 'sale',
            'source_id': saleId,
            'description': 'Sale of ${product.name} (edited)',
            'date': now.toIso8601String(),
          }
        : null;

    final newDue = remaining.isPositive
        ? createDue(
            id: _uuid.v7(),
            customerId: customerId!,
            sourceType: DueSourceType.sale,
            sourceId: saleId,
            remainingAmount: remaining,
            promisedDays: promisedDays,
            now: now,
          )
        : null;

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'sales',
        row: {
          'id': saleId,
          'shop_id': shopId,
          'product_id': existingSale.productId,
          'qty': qty,
          'actual_sell_price_minor': actualSellPrice.minorUnits,
          'cost_price_minor_at_sale': existingSale.costPriceAtSale.minorUnits,
          'date': existingSale.date.toUtc().toIso8601String(),
          'customer_id': customerId,
          'payment_status': paymentStatus.name,
          'payment_method': paymentMethod.name,
          'fund_source_type': existingSale.fundSource.type.name,
          'fund_source_investor_id': existingSale.fundSource.investorId,
        },
      ),
      ...stockReversal.upserts,
      ...cashReversal.upserts,
      if (oldDue != null)
        TableUpsert(
          table: 'dues',
          row: {
            'id': oldDue.id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
      TableUpsert(
        table: 'stock_movements',
        row: newMovementRow,
      ),
      if (newCashLedgerRow != null)
        TableUpsert(
          table: 'cash_ledger_entries',
          row: newCashLedgerRow,
        ),
      if (newDue != null)
        TableUpsert(
          table: 'dues',
          row: {
            'id': newDue.id,
            'shop_id': shopId,
            'customer_id': newDue.customerId,
            'source_type': newDue.sourceType.name,
            'source_id': newDue.sourceId,
            'original_amount_minor': newDue.originalAmount.minorUnits,
            'paid_amount_minor': newDue.paidAmount.minorUnits,
            'promised_days': newDue.promisedDays,
            'status': newDue.status.name,
            'created_at': now.toIso8601String(),
          },
        ),
    ];

    await writeAndEnqueue(
      db: db,
      eventType: 'sale_updated',
      upserts: upserts,
      localWrite: () async {
        // Reversals
        await stockReversal.localWrite();
        await cashReversal.localWrite();
        if (oldDue != null) {
          await db.dueDao.softDelete(oldDue.id, now);
        }

        // Apply new sale & movements
        await db.saleDao.updateSale(updatedSale, shopId: shopId, now: now);
        await db.ledgerDao.recordStockMovement(
          id: newMovementId,
          shopId: shopId,
          productId: existingSale.productId,
          deltaQty: -qty,
          sourceType: 'sale',
          sourceId: saleId,
          date: now,
          now: now,
        );
        await db.productDao.adjustQty(existingSale.productId, -qty, now);

        if (amountReceivedNow.isPositive) {
          await db.ledgerDao.recordCashLedgerEntry(
            id: newCashLedgerId,
            shopId: shopId,
            amountMinor: amountReceivedNow.minorUnits,
            paymentMethod: paymentMethod,
            sourceType: 'sale',
            sourceId: saleId,
            date: now,
            now: now,
            description: 'Sale of ${product.name} (edited)',
          );
        }

        if (newDue != null) {
          await db.dueDao.create(newDue, shopId: shopId, now: now);
        }
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'update',
      changedTableName: 'sales',
      recordId: saleId,
      oldValueJson: jsonEncode({
        'id': existingSale.id,
        'qty': existingSale.qty,
        'actual_sell_price_minor': existingSale.actualSellPrice.minorUnits,
        'payment_status': existingSale.paymentStatus.name,
      }),
      newValueJson: jsonEncode({
        'id': updatedSale.id,
        'qty': updatedSale.qty,
        'actual_sell_price_minor': updatedSale.actualSellPrice.minorUnits,
        'payment_status': updatedSale.paymentStatus.name,
      }),
      now: now,
    );

    return const Result.ok(null);
  }
}
