import 'package:uuid/uuid.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/services/purchase_reconciliation.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// The `SavePurchaseTripUseCase` both `PurchaseDao.saveTrip` and
/// `ProductDao.adjustQty`'s own doc comments point at as "a later PR" —
/// this is that PR. Pairs the trip/items/other-costs write
/// (`PurchaseDao.saveTrip`) with the two things the spec requires happen
/// alongside it, in the same transaction:
///
/// - **Stock movements** — every item (in-kind included: it is still
///   real stock physically received, just funded differently — see
///   `StockMovements`' own doc comment) increases the matching product's
///   `qty` via `ProductDao.adjustQty`, paired with a `StockMovements` row
///   so the qty change is always traceable to this trip, never a bare
///   mutation.
/// - **Cash ledger entries** — one negative (cash-out) entry per
///   fund-source bucket from `reconcilePurchaseTrip`, so this trip's cash
///   impact flows into `calculateCashBalances` the same way every other
///   cash event does, per the working plan's "Total Cash can never again
///   drift from reality" design (see `cash_balance_calculator.dart`).
///
/// **Payment method simplification, flagged not silently assumed:** a
/// [PurchaseTrip] has no payment-method field in the domain model — the
/// spec's purchase flow describes a physical trip to a market/mokam,
/// which is a cash transaction in practice, so every ledger entry this
/// use case writes uses [PaymentMethod.cash]. If purchases ever need to
/// support mobile-banking/bank-transfer funding, that is a domain-model
/// change ([PurchaseTrip] needs the field first), not something to guess
/// at here.
class SavePurchaseTripUseCase {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  SavePurchaseTripUseCase(this.db);

  Future<void> call(
    PurchaseTrip trip, {
    required String shopId,
    required DateTime now,
  }) async {
    final reconciliation = reconcilePurchaseTrip(trip);
    final tripDateIso = trip.date.toUtc().toIso8601String();

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'purchase_trips',
        row: {
          'id': trip.id,
          'shop_id': shopId,
          'date': tripDateIso,
          'transport_cost_minor': trip.transportCost.minorUnits,
          'cash_returned_minor': trip.cashReturned.minorUnits,
        },
      ),
    ];

    final movements = <({String id, String productId, double deltaQty})>[];
    for (final item in trip.items) {
      upserts.add(
        TableUpsert(
          table: 'purchase_items',
          row: {
            'id': item.id,
            'purchase_trip_id': trip.id,
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
            'source_id': trip.id,
            'date': tripDateIso,
          },
        ),
      );
    }

    for (final other in trip.otherCosts) {
      upserts.add(
        TableUpsert(
          table: 'purchase_other_costs',
          row: {
            'id': _uuid.v7(),
            'purchase_trip_id': trip.id,
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
      // Cash-out, hence negated — see CashLedgerEntries.amountMinor's own
      // doc comment ("positive = cash in, negative = cash out").
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
            'source_id': trip.id,
            'date': tripDateIso,
          },
        ),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'purchase_trip_recorded',
      upserts: upserts,
      localWrite: () async {
        await db.purchaseDao.saveTrip(trip, shopId: shopId, now: now);

        for (final item in trip.items) {
          await db.productDao.adjustQty(item.productId, item.qty, now);
        }
        for (final movement in movements) {
          await db.ledgerDao.recordStockMovement(
            id: movement.id,
            shopId: shopId,
            productId: movement.productId,
            deltaQty: movement.deltaQty,
            sourceType: 'purchase',
            sourceId: trip.id,
            date: trip.date,
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
            sourceId: trip.id,
            date: trip.date,
            now: now,
          );
        }
      },
    );
  }
}
