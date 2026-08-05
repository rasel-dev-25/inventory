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
import 'sync_enqueue_helper.dart';

/// The "cash/due router" from `notes/business_logic.md`'s Daily Sales
/// flow (§গ): records a sale, decreases stock, records whatever cash was
/// actually collected, and auto-creates a [Due] for the remainder — all
/// as one atomic local write plus one outbox event, the same shape as
/// `SavePurchaseTripUseCase` for the mirror-image side of stock moving
/// (there, stock increases and cash goes out; here, stock decreases and
/// cash comes in, partially or not at all).
///
/// [amountReceivedNow] is the one input that decides everything else —
/// [Sale] itself has no "amount paid" field (see its own doc comment:
/// [Sale.actualSellPrice] is the *total* price, not what changed hands
/// today), so `PaymentStatus` is *derived* here from comparing
/// [amountReceivedNow] against the sale total, never accepted as a
/// separate, independently-suppliable input a caller could get out of
/// sync with the real amounts:
/// - `amountReceivedNow == saleTotal` → [PaymentStatus.fullCash], no due.
/// - `amountReceivedNow == 0` → [PaymentStatus.fullDue], due for the
///   full total.
/// - anything in between → [PaymentStatus.partial], due for the
///   remainder — see [Due]'s own doc comment for why the due is only
///   ever created for the unpaid remainder, not the full sale total.
///
/// [Product.costPrice]/[Product.fundSource] are copied onto the [Sale]
/// at the moment of this call — see [Sale]'s own doc comment for why a
/// later cost-price edit on the product must never rewrite a historical
/// sale's profit.
///
/// Returns the new sale's id on success — added for
/// `QuickCaptureController`'s conversion flow, which needs to link a
/// converted capture back to the record it became; every prior caller
/// that only checked `result.isOk`/`result.failureOrNull` is unaffected.
class SaveSaleUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  SaveSaleUseCase(this.db);

  Future<Result<String>> call({
    required String productId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    required DateTime date,
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

    final product = await db.productDao.getById(productId);
    if (product == null) {
      return Result.err(NotFoundFailure('product', productId));
    }
    if (qty > product.qty) {
      return Result.err(
        BusinessRuleFailure(
          'Not enough stock: only ${product.qty} of ${product.name} available',
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

    final PaymentStatus paymentStatus;
    if (remaining.isZero) {
      paymentStatus = PaymentStatus.fullCash;
    } else if (amountReceivedNow.isZero) {
      paymentStatus = PaymentStatus.fullDue;
    } else {
      paymentStatus = PaymentStatus.partial;
    }

    if (remaining.isPositive && customerId == null) {
      return const Result.err(
        ValidationFailure(
          'customerId',
          'A customer is required to record this sale on credit',
        ),
      );
    }

    final saleId = _uuid.v7();
    final sale = Sale(
      id: saleId,
      productId: productId,
      qty: qty,
      actualSellPrice: actualSellPrice,
      costPriceAtSale: product.costPrice,
      date: date,
      customerId: customerId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      fundSource: product.fundSource,
    );

    final dateIso = date.toUtc().toIso8601String();
    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'sales',
        row: {
          'id': sale.id,
          'shop_id': shopId,
          'product_id': sale.productId,
          'qty': sale.qty,
          'actual_sell_price_minor': sale.actualSellPrice.minorUnits,
          'cost_price_minor_at_sale': sale.costPriceAtSale.minorUnits,
          'date': dateIso,
          'customer_id': sale.customerId,
          'payment_status': sale.paymentStatus.name,
          'payment_method': sale.paymentMethod.name,
          'fund_source_type': sale.fundSource.type.name,
          'fund_source_investor_id': sale.fundSource.investorId,
        },
      ),
    ];

    final movementId = _uuid.v7();
    upserts.add(
      TableUpsert(
        table: 'stock_movements',
        row: {
          'id': movementId,
          'shop_id': shopId,
          'product_id': productId,
          'delta_qty': -qty,
          'source_type': 'sale',
          'source_id': saleId,
          'date': dateIso,
        },
      ),
    );

    final ledgerId = _uuid.v7();
    if (amountReceivedNow.isPositive) {
      upserts.add(
        TableUpsert(
          table: 'cash_ledger_entries',
          row: {
            'id': ledgerId,
            'shop_id': shopId,
            'amount_minor': amountReceivedNow.minorUnits,
            'payment_method': paymentMethod.name,
            'source_type': 'sale',
            'source_id': saleId,
            'date': dateIso,
          },
        ),
      );
    }

    Due? due;
    if (remaining.isPositive) {
      due = createDue(
        id: _uuid.v7(),
        customerId: customerId!,
        sourceType: DueSourceType.sale,
        sourceId: saleId,
        remainingAmount: remaining,
        promisedDays: promisedDays,
        now: now,
      );
      upserts.add(
        TableUpsert(
          table: 'dues',
          row: {
            'id': due.id,
            'shop_id': shopId,
            'customer_id': due.customerId,
            'source_type': due.sourceType.name,
            'source_id': due.sourceId,
            'original_amount_minor': due.originalAmount.minorUnits,
            'paid_amount_minor': due.paidAmount.minorUnits,
            'promised_days': due.promisedDays,
            'status': due.status.name,
          },
        ),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'sale_recorded',
      upserts: upserts,
      localWrite: () async {
        await db.saleDao.create(sale, shopId: shopId, now: now);
        await db.productDao.adjustQty(productId, -qty, now);
        await db.ledgerDao.recordStockMovement(
          id: movementId,
          shopId: shopId,
          productId: productId,
          deltaQty: -qty,
          sourceType: 'sale',
          sourceId: saleId,
          date: date,
          now: now,
        );
        if (amountReceivedNow.isPositive) {
          await db.ledgerDao.recordCashLedgerEntry(
            id: ledgerId,
            shopId: shopId,
            amountMinor: amountReceivedNow.minorUnits,
            paymentMethod: paymentMethod,
            sourceType: 'sale',
            sourceId: saleId,
            date: date,
            now: now,
          );
        }
        if (due != null) {
          await db.dueDao.create(due, shopId: shopId, now: now);
        }
      },
    );

    return Result.ok(saleId);
  }
}
