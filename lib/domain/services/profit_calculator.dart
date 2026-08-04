/// The two profit calculations `notes/business_logic.md` §ঘ requires to
/// stay separate, as two distinct named functions, forever:
///
/// > "এজেন্টকে দুইটা আলাদা ফাংশন/মেথড বানাতে বলবেন: calculateGrossProfitPerSale()
/// > আর calculateShopNetProfit() — মিশিয়ে ফেললে হিসাব ঘুলিয়ে যাবে।"
///
/// The v1 codebase violated this in the worst possible way: it inlined a
/// gross-profit-shaped formula in three different controllers (with three
/// slightly different implementations, one of which never even ran for
/// sales made via the Daily Sales screen), and its dashboard labeled a
/// pure gross-profit sum as `netProfit` without ever subtracting expenses.
/// Both functions below exist exactly once. If a profit formula needs to
/// change, this file is the only file that changes.
library;

import '../../core/money/money.dart';
import '../entities/enums.dart';
import '../entities/investor.dart';
import '../entities/sale.dart';

/// Level 1 — per-sale gross profit, used for per-investor payouts.
///
/// `grossProfit = actualSellPrice − costPrice` (per unit), scaled by
/// quantity. Deliberately has no knowledge of expenses, rent, or trip
/// costs — per business_logic.md §ঘ, splitting those into a per-sale
/// number would drive an investor's payout close to zero, which is not
/// what this calculation is for.
Money calculateGrossProfitPerSale(Sale sale) {
  return (sale.actualSellPrice - sale.costPriceAtSale) * sale.qty;
}

/// Level 2 — the shop's actual net profit across a period, used to judge
/// overall business health and to inform (but not directly drive —
/// per-investor payout is always Level 1) capital-return decisions.
///
/// `netProfit = Σ(grossProfit across all sales) − Σ(monthly_rent +
/// daily_other expenses)`.
///
/// Takes the already-computed gross profits rather than the raw [Sale]
/// list on purpose: this keeps the function honest about being a pure
/// aggregation step, and lets a caller reuse gross profits it already
/// computed via [calculateGrossProfitPerSale] without recomputing them.
Money calculateShopNetProfit({
  required Iterable<Money> grossProfitsFromAllSales,
  required Iterable<Money> expenses,
  Currency currency = Currency.bdt,
}) {
  final totalGrossProfit = grossProfitsFromAllSales.fold(
    Money.zero(currency: currency),
    (sum, profit) => sum + profit,
  );
  final totalExpenses = expenses.fold(
    Money.zero(currency: currency),
    (sum, expense) => sum + expense,
  );
  return totalGrossProfit - totalExpenses;
}

/// An investor's share of a pool of gross profit attributable to their
/// fund source, per business_logic.md §ঙ:
///
/// `share = Σ(grossProfit) × profitSharePercent` — except for
/// [InvestmentType.cashLoan], where the investor is owed capital return
/// only and their share is always zero, regardless of `profitSharePercent`
/// on file (a cash-loan investor's `profitSharePercent` should always be
/// 0 by convention, but this function does not trust that convention to
/// have been followed — it enforces the zero-share rule itself).
///
/// This is a real fix, not just a refactor: the v1 codebase's investor
/// profit-split (`inventory_controller.dart`) applied `profitPercentage`
/// unconditionally to every non-"Own Shop" investor, with no
/// [InvestmentType.cashLoan] check at all.
Money calculateInvestorProfitShare({
  required Money totalGrossProfitForInvestor,
  required Investor investor,
}) {
  if (investor.investmentType == InvestmentType.cashLoan) {
    return Money.zero(currency: totalGrossProfitForInvestor.currency);
  }
  return totalGrossProfitForInvestor * (investor.profitSharePercent / 100);
}
