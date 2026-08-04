import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../domain/entities/investor.dart' as domain;
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

/// Data access for [Investors]. Deliberately does not compute any
/// aggregate here (total invested, current stock value, profit share) —
/// those are the M2 investor-metrics service's job, always computed on
/// read from [PurchaseItems]/[Sales]/[InvestorRepayments], never cached on
/// this row. The v1 schema's `Investors.totalBought`/`totalSold`/
/// `totalProfit`/`remainingBalance` columns are exactly the bug this
/// avoids repeating — see ARCHITECTURE.md.
@DriftAccessor(tables: [Investors])
class InvestorDao extends DatabaseAccessor<AppDatabaseV2>
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
}
