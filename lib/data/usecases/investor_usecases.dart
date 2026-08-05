import '../../domain/entities/investor.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create/update for [Investor] — same shape as [ProductUseCases]/
/// [CustomerUseCases]: [InvestorDao] already builds the storage companion
/// from a domain entity, this layer builds the matching outbox row from
/// the exact same values and writes both together.
///
/// No `softDelete` here yet (unlike `CustomerUseCases`) — an investor with
/// purchase/sale/repayment history attached is a much bigger deletion
/// question (what happens to `investor_metrics.dart`'s totals for
/// already-recorded history?) than a customer's, and the spec does not
/// describe an investor-removal flow. Deferred rather than guessed at.
class InvestorUseCases {
  final AppDatabase db;

  InvestorUseCases(this.db);

  Future<void> create(
    Investor investor, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'investor_created',
      upserts: [
        TableUpsert(
          table: 'investors',
          row: _rowFor(investor, shopId: shopId),
        ),
      ],
      localWrite: () =>
          db.investorDao.create(investor, shopId: shopId, now: now),
    );
  }

  Future<void> update(
    Investor investor, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'investor_updated',
      upserts: [
        TableUpsert(
          table: 'investors',
          row: _rowFor(investor, shopId: shopId),
        ),
      ],
      localWrite: () =>
          db.investorDao.updateInvestor(investor, shopId: shopId, now: now),
    );
  }

  Map<String, Object?> _rowFor(Investor investor, {required String shopId}) {
    return {
      'id': investor.id,
      'shop_id': shopId,
      'name': investor.name,
      'contact': investor.contact,
      'investment_type': investor.investmentType.name,
      'profit_share_percent': investor.profitSharePercent,
      'capital_return_term_days': investor.capitalReturnTermDays,
      'profit_payout_cycle': investor.profitPayoutCycle.name,
      'notes': investor.notes,
    };
  }
}
