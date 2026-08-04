import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import '../app_database.dart';
import '../tables/ledger.dart';

part 'ledger_dao.g.dart';

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
class LedgerDao extends DatabaseAccessor<AppDatabaseV2> with _$LedgerDaoMixin {
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
