/// Purchase-trip reconciliation, per `notes/business_logic.md` §ক.
///
/// The spec's formula:
///
/// > মোট বের হওয়া টাকা = Σ(item.qty × item.unitPrice, শুধু isInKind=false গুলো)
/// > + transportCost + Σ(otherCosts) − cashReturned
/// >
/// > এই টোটাল fund-source অনুযায়ী ভাগ করে... মিলিয়ে দেখা যাবে বাস্তবে যে টাকা
/// > নিয়ে বের হয়েছিলেন তার সাথে মিলছে কিনা
///
/// i.e. total cash out = the cash (non-in-kind) items + trip-level costs −
/// change brought back, and that total should be checked against what the
/// owner actually took out — the spec's own "sanity check" for a trip.
///
/// **Open question, flagged rather than silently assumed:** the spec is
/// explicit that each *item* has its own fund source, but does not say
/// whether `transportCost`/`otherCosts`/`cashReturned` — which are
/// trip-level, not per item — should be split across fund sources too, or
/// always charged to the shop's own cash. This implementation takes the
/// conservative, spec-literal reading: [PurchaseTripReconciliation.byFundSource]
/// only ever contains the *item* totals (which do have an explicit fund
/// source), while transport/other/returned stay as unattributed trip-level
/// numbers in the overall total. If trip overhead should sometimes be
/// billed to a specific investor too, that needs a product decision before
/// this function's behaviour changes.
library;

import '../../core/money/money.dart';
import '../entities/fund_source.dart';
import '../entities/purchase.dart';

/// The cash total attributable to one fund source, from item costs only
/// (see the "open question" note above) — excludes in-kind items, which
/// never contribute cash.
class FundSourceCashOut {
  final FundSource fundSource;
  final Money amount;

  const FundSourceCashOut({required this.fundSource, required this.amount});
}

/// The stock valuation contributed by in-kind items for one fund source —
/// tracked separately from cash because in-kind items must never appear in
/// a cash total (Data Integrity Rule #2).
class InKindValuation {
  final FundSource fundSource;
  final Money value;

  const InKindValuation({required this.fundSource, required this.value});
}

class PurchaseTripReconciliation {
  /// Σ(qty × unitPrice) across all non-in-kind items, regardless of fund
  /// source.
  final Money totalItemsCash;

  final Money transportCost;
  final Money otherCostsTotal;
  final Money cashReturned;

  /// `totalItemsCash + transportCost + otherCostsTotal − cashReturned` —
  /// the spec's "মোট বের হওয়া টাকা".
  final Money totalCashOut;

  /// Per-fund-source breakdown of [totalItemsCash] only — see the "open
  /// question" note on this file for why trip-level costs are not split
  /// here.
  final List<FundSourceCashOut> byFundSource;

  /// In-kind contributions, valued but excluded from every cash figure
  /// above.
  final List<InKindValuation> inKindByFundSource;

  const PurchaseTripReconciliation({
    required this.totalItemsCash,
    required this.transportCost,
    required this.otherCostsTotal,
    required this.cashReturned,
    required this.totalCashOut,
    required this.byFundSource,
    required this.inKindByFundSource,
  });

  /// True when what the owner says they actually took out of the shop for
  /// this trip matches [totalCashOut] exactly — the spec's sanity check.
  /// A caller surfacing a mismatch to the user should show the *difference*
  /// (`actualCashTakenOut - totalCashOut`), not just a boolean, so they can
  /// see whether they're short or over.
  bool reconciles(Money actualCashTakenOut) =>
      actualCashTakenOut == totalCashOut;
}

/// Computes the cash reconciliation for one purchase trip. Pure function
/// of [trip] — no I/O, no database, fully unit-testable with a
/// hand-built [PurchaseTrip].
PurchaseTripReconciliation reconcilePurchaseTrip(PurchaseTrip trip) {
  final currency = trip.transportCost.currency;
  final zero = Money.zero(currency: currency);

  final cashItems = trip.items.where((item) => !item.isInKind);

  final totalItemsCash = cashItems.fold(
    zero,
    (sum, item) => sum + item.lineTotal,
  );

  final otherCostsTotal = trip.otherCostsTotal;

  final totalCashOut =
      totalItemsCash + trip.transportCost + otherCostsTotal - trip.cashReturned;

  final byFundSourceMap = <FundSource, Money>{};
  for (final item in cashItems) {
    byFundSourceMap.update(
      item.fundSource,
      (existing) => existing + item.lineTotal,
      ifAbsent: () => item.lineTotal,
    );
  }

  return PurchaseTripReconciliation(
    totalItemsCash: totalItemsCash,
    transportCost: trip.transportCost,
    otherCostsTotal: otherCostsTotal,
    cashReturned: trip.cashReturned,
    totalCashOut: totalCashOut,
    byFundSource: [
      for (final entry in byFundSourceMap.entries)
        FundSourceCashOut(fundSource: entry.key, amount: entry.value),
    ],
    inKindByFundSource: valueInKindContributions(trip),
  );
}

/// Values the in-kind items on a trip per fund source, entirely separate
/// from the cash reconciliation above — Data Integrity Rule #2 requires
/// in-kind items to never touch a cash figure, only stock/investor
/// valuation.
List<InKindValuation> valueInKindContributions(PurchaseTrip trip) {
  final inKindItems = trip.items.where((item) => item.isInKind);
  final byFundSourceMap = <FundSource, Money>{};
  for (final item in inKindItems) {
    byFundSourceMap.update(
      item.fundSource,
      (existing) => existing + item.lineTotal,
      ifAbsent: () => item.lineTotal,
    );
  }
  return [
    for (final entry in byFundSourceMap.entries)
      InKindValuation(fundSource: entry.key, value: entry.value),
  ];
}
