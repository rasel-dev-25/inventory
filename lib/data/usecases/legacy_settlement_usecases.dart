import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/legacy_settlement.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create + settle for [LegacySettlement], per `notes/business_logic.md`
/// §৬.
///
/// **Deliberately never touches [CashLedgerEntries] or [StockMovements]**
/// — the spec is explicit that this entry "normal MokamEntry/Sale
/// ইতিহাসের সাথে মিশবে না" (never mixes with normal purchase/sale
/// history), staying a standalone opening/closing-balance note for future
/// reference only. This is *not* an oversight to fix later: recording the
/// old, ungranular five-year ledger as a fabricated cash-ledger entry
/// would corrupt `calculateCashBalances`/`computeDashboardTotals` with a
/// number that was never actually a real-time cash movement this app
/// witnessed.
class LegacySettlementUseCases {
  final AppDatabase db;
  static const _uuid = Uuid();

  LegacySettlementUseCases(this.db);

  /// [netSettlementAmount] is always computed here as
  /// `totalHistoricalInvestment - totalAlreadyReturned`, never accepted
  /// as caller input — matches the spec's "হিসাব করে" (calculated)
  /// annotation on that field.
  Future<Result<String>> create({
    required String investorId,
    required Money totalHistoricalInvestment,
    required Money totalAlreadyReturned,
    required DateTime settlementDate,
    required String shopId,
    required DateTime now,
    String? notes,
  }) async {
    if (totalHistoricalInvestment.isNegative) {
      return const Result.err(
        ValidationFailure(
          'totalHistoricalInvestment',
          'Total historical investment cannot be negative',
        ),
      );
    }
    if (totalAlreadyReturned.isNegative) {
      return const Result.err(
        ValidationFailure(
          'totalAlreadyReturned',
          'Total already returned cannot be negative',
        ),
      );
    }
    if (totalAlreadyReturned.minorUnits >
        totalHistoricalInvestment.minorUnits) {
      return const Result.err(
        ValidationFailure(
          'totalAlreadyReturned',
          'Cannot exceed the total historical investment',
        ),
      );
    }

    final investor = await db.investorDao.getById(investorId);
    if (investor == null) {
      return Result.err(NotFoundFailure('investor', investorId));
    }

    final existing = await db.investorDao.getSettlementForInvestor(investorId);
    if (existing != null) {
      return const Result.err(
        BusinessRuleFailure(
          'This investor already has a legacy settlement on file',
        ),
      );
    }

    final settlementId = _uuid.v7();
    final netSettlementAmount =
        totalHistoricalInvestment - totalAlreadyReturned;

    final settlement = LegacySettlement(
      id: settlementId,
      investorId: investorId,
      totalHistoricalInvestment: totalHistoricalInvestment,
      totalAlreadyReturned: totalAlreadyReturned,
      netSettlementAmount: netSettlementAmount,
      settlementDate: settlementDate,
      notes: notes,
      status: LegacySettlementStatus.pending,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'legacy_settlement_created',
      upserts: [
        TableUpsert(
          table: 'legacy_settlements',
          row: {
            'id': settlementId,
            'shop_id': shopId,
            'investor_id': investorId,
            'total_historical_investment_minor':
                totalHistoricalInvestment.minorUnits,
            'total_already_returned_minor': totalAlreadyReturned.minorUnits,
            'net_settlement_amount_minor': netSettlementAmount.minorUnits,
            'settlement_date': settlementDate.toUtc().toIso8601String(),
            'notes': notes,
            'status': LegacySettlementStatus.pending.name,
          },
        ),
      ],
      localWrite: () =>
          db.investorDao.createSettlement(settlement, shopId: shopId, now: now),
    );

    return Result.ok(settlementId);
  }

  /// Marks the old account closed — per the spec, once this happens the
  /// investor's normal tracking "শূন্য থেকে (fresh start)" (starts fresh
  /// from zero); this method itself does nothing beyond the status flip,
  /// since `investor_metrics.dart` already computes everything from
  /// `PurchaseItem`/`Sale`/`InvestorRepayment` rows going forward and a
  /// settled [LegacySettlement] is simply never one of those.
  Future<Result<void>> markSettled({
    required String settlementId,
    required String shopId,
    required DateTime now,
  }) async {
    final row = await (db.select(
      db.legacySettlements,
    )..where((s) => s.id.equals(settlementId))).getSingleOrNull();
    if (row == null) {
      return Result.err(NotFoundFailure('legacySettlement', settlementId));
    }
    if (row.status == LegacySettlementStatus.settled) {
      return const Result.err(
        BusinessRuleFailure('This legacy settlement is already settled'),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'legacy_settlement_settled',
      upserts: [
        TableUpsert(
          table: 'legacy_settlements',
          row: {
            'id': settlementId,
            'shop_id': shopId,
            'status': LegacySettlementStatus.settled.name,
          },
        ),
      ],
      localWrite: () => db.investorDao.markSettled(settlementId, now),
    );

    return const Result.ok(null);
  }

  /// Records a partial or full installment payment against the old ledger balance.
  /// Deducts from the remaining balance, appends a timestamped note to the
  /// history, and marks status as [LegacySettlementStatus.settled] if the
  /// remaining balance reaches zero.
  Future<Result<void>> recordPayment({
    required String settlementId,
    required Money paymentAmount,
    required String shopId,
    required DateTime now,
    String? note,
  }) async {
    final row = await (db.select(
      db.legacySettlements,
    )..where((s) => s.id.equals(settlementId))).getSingleOrNull();
    if (row == null) {
      return Result.err(NotFoundFailure('legacySettlement', settlementId));
    }
    if (row.status == LegacySettlementStatus.settled) {
      return const Result.err(
        BusinessRuleFailure('This legacy settlement is already settled'),
      );
    }
    if (paymentAmount.isZero || paymentAmount.isNegative) {
      return const Result.err(
        ValidationFailure('paymentAmount', 'Payment amount must be positive'),
      );
    }

    final currentReturned = Money.fromMinor(row.totalAlreadyReturnedMinor);
    final totalHistorical = Money.fromMinor(row.totalHistoricalInvestmentMinor);
    final newReturned = currentReturned + paymentAmount;
    final newNet = (totalHistorical > newReturned)
        ? (totalHistorical - newReturned)
        : Money.zero();
    final newStatus = newNet.isZero
        ? LegacySettlementStatus.settled
        : LegacySettlementStatus.pending;

    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final paymentEntry = '$dateStr: ${paymentAmount.format()}${note != null && note.trim().isNotEmpty ? ' (${note.trim()})' : ''}';
    final updatedNotes = row.notes == null || row.notes!.trim().isEmpty
        ? paymentEntry
        : '${row.notes}\n$paymentEntry';

    await writeAndEnqueue(
      db: db,
      eventType: 'legacy_settlement_payment_recorded',
      upserts: [
        TableUpsert(
          table: 'legacy_settlements',
          row: {
            'id': settlementId,
            'shop_id': shopId,
            'total_already_returned_minor': newReturned.minorUnits,
            'net_settlement_amount_minor': newNet.minorUnits,
            'status': newStatus.name,
            'notes': updatedNotes,
            'updated_at': now.toUtc().toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.investorDao.updateSettlementPayment(
        id: settlementId,
        newTotalAlreadyReturned: newReturned,
        newNetSettlementAmount: newNet,
        newStatus: newStatus,
        newNotes: updatedNotes,
        now: now,
      ),
    );

    return const Result.ok(null);
  }
}
