import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/investor_repayment.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Records a payment made *to* an investor — capital return or profit-share
/// payout, per `notes/business_logic.md` §ঙ/§চ's "ইনভেস্টর পরিশোধ তালিকা".
///
/// Always cash-out, same shape as [SavePurchaseTripUseCase]'s ledger
/// entries: writes the [InvestorRepayments] row and a negative
/// `cash_ledger_entries` row together, so this repayment's cash impact
/// flows into `calculateCashBalances`/`computeDashboardTotals` the same
/// way every other cash event does — never a repayment that happened but
/// left no trace in Total Cash.
class RecordInvestorRepaymentUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  RecordInvestorRepaymentUseCase(this.db);

  Future<Result<void>> call({
    required String investorId,
    required Money amount,
    required RepaymentType type,
    required PaymentMethod paymentMethod,
    required DateTime date,
    required String shopId,
    required DateTime now,
  }) async {
    if (!amount.isPositive) {
      return const Result.err(
        ValidationFailure('amount', 'Repayment amount must be positive'),
      );
    }

    final investor = await db.investorDao.getById(investorId);
    if (investor == null) {
      return Result.err(NotFoundFailure('investor', investorId));
    }

    final repaymentId = _uuid.v7();
    final repayment = InvestorRepayment(
      id: repaymentId,
      investorId: investorId,
      amount: amount,
      type: type,
      paymentMethod: paymentMethod,
      date: date,
    );

    final ledgerId = _uuid.v7();
    final dateIso = date.toUtc().toIso8601String();

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'investor_repayments',
        row: {
          'id': repaymentId,
          'shop_id': shopId,
          'investor_id': investorId,
          'amount_minor': amount.minorUnits,
          'type': type.name,
          'payment_method': paymentMethod.name,
          'date': dateIso,
        },
      ),
      TableUpsert(
        table: 'cash_ledger_entries',
        row: {
          'id': ledgerId,
          'shop_id': shopId,
          // Cash-out, hence negated — same convention as
          // SavePurchaseTripUseCase's ledger entries.
          'amount_minor': -amount.minorUnits,
          'payment_method': paymentMethod.name,
          'source_type': 'investor_repayment',
          'source_id': repaymentId,
          'date': dateIso,
        },
      ),
    ];

    await writeAndEnqueue(
      db: db,
      eventType: 'investor_repayment_recorded',
      upserts: upserts,
      localWrite: () async {
        await db.investorDao.recordRepayment(
          repayment,
          shopId: shopId,
          now: now,
        );
        await db.ledgerDao.recordCashLedgerEntry(
          id: ledgerId,
          shopId: shopId,
          amountMinor: -amount.minorUnits,
          paymentMethod: paymentMethod,
          sourceType: 'investor_repayment',
          sourceId: repaymentId,
          date: date,
          now: now,
        );
      },
    );

    return const Result.ok(null);
  }
}
