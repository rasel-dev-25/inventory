import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart' as domain;
import '../../../domain/entities/investor_repayment.dart' as domain;
import '../../../domain/entities/legacy_settlement.dart' as domain;
import '../app_database.dart';
import '../tables/investors.dart';

part 'investor_dao.g.dart';

extension _InvestorRowMapping on InvestorRow {
  domain.Investor toDomain() {
    return domain.Investor(
      id: id,
      name: name,
      contact: contact,
      investmentType: investmentType,
      profitSharePercent: profitSharePercent,
      capitalReturnTermDays: capitalReturnTermDays,
      profitPayoutCycle: profitPayoutCycle,
      notes: notes,
    );
  }
}

extension _InvestorRepaymentRowMapping on InvestorRepaymentRow {
  domain.InvestorRepayment toDomain() {
    return domain.InvestorRepayment(
      id: id,
      investorId: investorId,
      amount: Money.fromMinor(amountMinor),
      type: type,
      paymentMethod: paymentMethod,
      date: date,
    );
  }
}

extension _LegacySettlementRowMapping on LegacySettlementRow {
  domain.LegacySettlement toDomain() {
    return domain.LegacySettlement(
      id: id,
      investorId: investorId,
      totalHistoricalInvestment: Money.fromMinor(
        totalHistoricalInvestmentMinor,
      ),
      totalAlreadyReturned: Money.fromMinor(totalAlreadyReturnedMinor),
      netSettlementAmount: Money.fromMinor(netSettlementAmountMinor),
      settlementDate: settlementDate,
      notes: notes,
      status: status,
    );
  }
}

/// Data access for [Investors] + [InvestorRepayments] +
/// [LegacySettlements] — grouped in one accessor the same way `DueDao`
/// covers `Dues` + `DuePayments`, since a repayment (or a legacy
/// settlement) is never meaningful without its investor.
///
/// Deliberately does not compute any aggregate here (total invested,
/// current stock value, profit share) — those are `investor_metrics.dart`'s
/// job, always computed on read from [PurchaseItems]/[Sales]/
/// [InvestorRepayments], never cached on this row. The v1 schema's
/// `Investors.totalBought`/`totalSold`/`totalProfit`/`remainingBalance`
/// columns are exactly the bug this avoids repeating — see ARCHITECTURE.md.
@DriftAccessor(tables: [Investors, InvestorRepayments, LegacySettlements])
class InvestorDao extends DatabaseAccessor<AppDatabase>
    with _$InvestorDaoMixin {
  InvestorDao(super.db);

  Future<domain.Investor?> getById(String id) async {
    final row = await (select(
      investors,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Investor>> watchAll(String shopId) {
    final query = select(investors)
      ..where((i) => i.shopId.equals(shopId) & i.deletedAt.isNull())
      ..orderBy([(i) => OrderingTerm.asc(i.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Investor investor, {
    required String shopId,
    required DateTime now,
  }) {
    return into(
      investors,
    ).insert(_companionFor(investor, shopId: shopId, now: now));
  }

  Future<void> updateInvestor(
    domain.Investor investor, {
    required String shopId,
    required DateTime now,
  }) {
    final companion = _companionFor(
      investor,
      shopId: shopId,
      now: now,
    ).copyWith(updatedAt: Value(now));
    return (update(
      investors,
    )..where((i) => i.id.equals(investor.id))).write(companion);
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(investors)..where((i) => i.id.equals(id))).write(
      InvestorsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  InvestorsCompanion _companionFor(
    domain.Investor investor, {
    required String shopId,
    required DateTime now,
  }) {
    return InvestorsCompanion.insert(
      id: investor.id,
      shopId: shopId,
      name: investor.name,
      contact: Value(investor.contact),
      investmentType: investor.investmentType,
      profitSharePercent: Value(investor.profitSharePercent),
      capitalReturnTermDays: Value(investor.capitalReturnTermDays),
      profitPayoutCycle: investor.profitPayoutCycle,
      notes: Value(investor.notes),
      createdAt: now,
      updatedAt: now,
      syncedAt: now,
    );
  }

  /// Every repayment ever made to any investor of [shopId] — unfiltered by
  /// investor on purpose, since `investor_metrics.dart` needs to group
  /// these itself per investor, the same reasoning `LedgerDao.watchAll`
  /// documents for why it doesn't pre-aggregate either.
  Stream<List<domain.InvestorRepayment>> watchAllRepayments(String shopId) {
    final query = select(investorRepayments)
      ..where((r) => r.shopId.equals(shopId));
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> recordRepayment(
    domain.InvestorRepayment repayment, {
    required String shopId,
    required DateTime now,
  }) {
    return into(investorRepayments).insert(
      InvestorRepaymentsCompanion.insert(
        id: repayment.id,
        shopId: shopId,
        investorId: repayment.investorId,
        amountMinor: repayment.amount.minorUnits,
        type: repayment.type,
        paymentMethod: repayment.paymentMethod,
        date: repayment.date,
        createdAt: now,
        syncedAt: now,
      ),
    );
  }

  /// At most one per investor, by business rule (the spec's "একবারই" —
  /// "only once") — [LegacySettlementUseCases.create] enforces that by
  /// checking this before inserting, not a database constraint, since a
  /// unique index would need to special-case soft-deletes this table
  /// doesn't have.
  Future<domain.LegacySettlement?> getSettlementForInvestor(
    String investorId,
  ) async {
    final row = await (select(
      legacySettlements,
    )..where((s) => s.investorId.equals(investorId))).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.LegacySettlement>> watchAllSettlements(String shopId) {
    final query = select(legacySettlements)
      ..where((s) => s.shopId.equals(shopId))
      ..orderBy([(s) => OrderingTerm.desc(s.settlementDate)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> createSettlement(
    domain.LegacySettlement settlement, {
    required String shopId,
    required DateTime now,
  }) {
    return into(legacySettlements).insert(
      LegacySettlementsCompanion.insert(
        id: settlement.id,
        shopId: shopId,
        investorId: settlement.investorId,
        totalHistoricalInvestmentMinor:
            settlement.totalHistoricalInvestment.minorUnits,
        totalAlreadyReturnedMinor: Value(
          settlement.totalAlreadyReturned.minorUnits,
        ),
        netSettlementAmountMinor: settlement.netSettlementAmount.minorUnits,
        settlementDate: settlement.settlementDate,
        notes: Value(settlement.notes),
        status: settlement.status,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  /// No general `update` — every field except [status] is filled in once
  /// at creation and never edited again (see the class doc comment on
  /// `LegacySettlement`); this is the only mutation this row ever gets.
  Future<void> markSettled(String id, DateTime now) {
    return (update(legacySettlements)..where((s) => s.id.equals(id))).write(
      LegacySettlementsCompanion(
        status: const Value(LegacySettlementStatus.settled),
        updatedAt: Value(now),
      ),
    );
  }
}
