/// The overhead-markup sell-price suggestion engine, per
/// `notes/business_logic.md`'s "প্রাইসিং রেকমেন্ডেশন ইঞ্জিন" — what you
/// asked for: after entering a cost price, the system suggests a sell
/// price that accounts for shop rent, owner salary, mokam trip costs, and
/// whatever profit share an investor is owed, all at once.
///
/// Every function here is pure — no database access, no `SettingsRegistry`
/// read, no clock read. `PricingSettingsUseCases`
/// (`lib/data/usecases/pricing_settings_usecases.dart`) is the layer that
/// resolves a live [OverheadSettings] snapshot from stored settings plus
/// real purchase-trip/sale history and feeds it in here — same split as
/// `investor_metrics.dart`/`rent_lifecycle.dart`.
library;

import '../../core/money/money.dart';
import '../entities/enums.dart';
import '../entities/fund_source.dart';
import '../entities/investor.dart';
import '../entities/purchase.dart';
import '../entities/sale.dart';

/// The four inputs the spec's `monthlyOverhead`/`overheadMarkupPercent`
/// formulas need. [estimatedMonthlySalesRevenue] is null exactly when the
/// spec's bootstrap period applies — no completed month of real sales
/// data exists yet to estimate from — and every function below that
/// depends on it degrades to returning null rather than guessing, so a
/// caller only ever has to check one thing (is the suggestion null) to
/// know whether to show it.
class OverheadSettings {
  final Money monthlyShopRent;
  final Money monthlyOwnerSalary;
  final Money averageMonthlyTripCost;
  final Money? estimatedMonthlySalesRevenue;

  const OverheadSettings({
    required this.monthlyShopRent,
    required this.monthlyOwnerSalary,
    required this.averageMonthlyTripCost,
    this.estimatedMonthlySalesRevenue,
  });

  Money get monthlyOverhead =>
      monthlyShopRent + monthlyOwnerSalary + averageMonthlyTripCost;
}

/// `monthlyOverhead ÷ estimatedMonthlySalesRevenue` — null when there's no
/// usable revenue estimate yet (bootstrap period) or it's zero/negative
/// (would be a division by zero, and a shop with no sales has nothing
/// meaningful to markup against anyway).
double? computeOverheadMarkupPercent(OverheadSettings settings) {
  final revenue = settings.estimatedMonthlySalesRevenue;
  if (revenue == null || !revenue.isPositive) return null;
  return settings.monthlyOverhead.minorUnits / revenue.minorUnits;
}

/// A [InvestmentType.cashLoan] investor never takes a profit share — same
/// rule `calculateInvestorProfitShare` (`profit_calculator.dart`) enforces
/// for the actual profit-share deduction. The pricing suggestion must
/// agree with that deduction, or a cash-loan-funded product would be
/// needlessly marked up to cover a share it never actually pays.
double effectiveProfitSharePercent(Investor investor) {
  return investor.investmentType == InvestmentType.cashLoan
      ? 0
      : investor.profitSharePercent;
}

/// `overheadMarkupPercent ÷ (1 − share)` for an investor-funded product,
/// or just `overheadMarkupPercent` when [investorProfitSharePercent] is
/// zero (a shop-funded product, or a cash-loan investor per
/// [effectiveProfitSharePercent]).
///
/// Null when [investorProfitSharePercent] is 100 or more — the spec's
/// formula divides by `(1 − share)`, which is undefined (or negative,
/// which would mean a *lower* margin covers less profit — nonsensical) at
/// or past a full 100% share. The spec doesn't describe this edge case
/// (no investor arrangement gives away the *entire* gross profit and
/// still expects the shop to also cover overhead from it), so this
/// returns null — "cannot suggest a price" — rather than fabricating one.
double? computeRequiredMargin({
  required double overheadMarkupPercent,
  double investorProfitSharePercent = 0,
}) {
  final shareFraction = investorProfitSharePercent / 100;
  if (shareFraction >= 1) return null;
  return overheadMarkupPercent / (1 - shareFraction);
}

/// `costPrice × (1 + requiredMargin)` — the one number this whole engine
/// exists to produce, always shown next to the cost-price entry per the
/// spec, always manually overridable (this function has no opinion on
/// what the UI does with the result; `ProductFormSheet` decides that).
///
/// [fundingInvestor] must be non-null whenever [fundSource] is
/// [FundSourceType.investor] for the investor's share to be accounted
/// for — passing null in that case is treated the same as a shop-funded
/// product (share 0), which is *wrong* for an investor-funded product,
/// so callers must always resolve the investor first.
Money? suggestSellPrice({
  required Money costPrice,
  required double overheadMarkupPercent,
  required FundSource fundSource,
  Investor? fundingInvestor,
}) {
  final sharePercent = (fundSource.isInvestor && fundingInvestor != null)
      ? effectiveProfitSharePercent(fundingInvestor)
      : 0.0;
  final requiredMargin = computeRequiredMargin(
    overheadMarkupPercent: overheadMarkupPercent,
    investorProfitSharePercent: sharePercent,
  );
  if (requiredMargin == null) return null;
  return costPrice * (1 + requiredMargin);
}

/// The average of the last [monthsToAverage] *completed* calendar months'
/// transport + other trip costs, per the spec's "MokamEntry-র
/// transportCost+otherCosts থেকে গত কয়েক মাসের গড়". [asOf]'s own
/// still-in-progress month is always excluded, so a half-finished month
/// never drags the average down.
Money computeAverageMonthlyTripCost({
  required List<PurchaseTrip> trips,
  required DateTime asOf,
  int monthsToAverage = 3,
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);
  final currentMonthStart = DateTime.utc(asOf.year, asOf.month, 1);
  final windowStart = DateTime.utc(asOf.year, asOf.month - monthsToAverage, 1);

  final totalsByMonth = <String, Money>{};
  for (final trip in trips) {
    final tripMonthStart = DateTime.utc(trip.date.year, trip.date.month, 1);
    if (!tripMonthStart.isBefore(currentMonthStart) ||
        tripMonthStart.isBefore(windowStart)) {
      continue;
    }
    final key = _monthKey(tripMonthStart);
    final cost = trip.transportCost + trip.otherCostsTotal;
    totalsByMonth[key] = (totalsByMonth[key] ?? zero) + cost;
  }

  if (totalsByMonth.isEmpty) return zero;
  final total = totalsByMonth.values.fold(zero, (sum, m) => sum + m);
  return total / totalsByMonth.length;
}

/// The real total of [sales] dated in the single calendar month
/// immediately before [asOf]'s month — exactly what the spec's monthly
/// auto-refresh sets `estimatedMonthlySalesRevenue` from.
Money computeActualSalesRevenueForPreviousMonth({
  required List<Sale> sales,
  required DateTime asOf,
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);
  final currentMonthStart = DateTime.utc(asOf.year, asOf.month, 1);
  final previousMonthStart = DateTime.utc(asOf.year, asOf.month - 1, 1);

  return sales
      .where((s) {
        final saleMonthStart = DateTime.utc(s.date.year, s.date.month, 1);
        return !saleMonthStart.isBefore(previousMonthStart) &&
            saleMonthStart.isBefore(currentMonthStart);
      })
      .fold(zero, (sum, s) => sum + s.actualSellPrice * s.qty);
}

/// A stable `"YYYY-MM"` key for the calendar month [monthStart] falls
/// in — used by `PricingSettingsUseCases` to remember which month was
/// last auto-refreshed, so the same month is never re-summed twice.
String monthKey(DateTime monthStart) => _monthKey(monthStart);

String _monthKey(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}
