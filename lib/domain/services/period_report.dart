/// The two sections a period-based accounting report needs beyond what
/// `dashboard_calculator.dart`'s [computeDashboardTotals] already gives —
/// per-investor profit-share owed for the period, and which products
/// actually moved. `ReportsController` calls [computeDashboardTotals]
/// directly for the P&L summary (it is already range-agnostic — see its
/// own doc comment) and calls the two functions here for everything else
/// a report screen wants, so no profit/revenue formula exists in two
/// places.
library;

import '../../core/money/money.dart';
import '../entities/investor.dart';
import '../entities/sale.dart';
import 'profit_calculator.dart';

/// One investor's profit share owed for whatever period [salesInRange]
/// was already filtered to.
class InvestorPeriodShare {
  final Investor investor;
  final Money grossProfit;
  final Money profitShare;

  const InvestorPeriodShare({
    required this.investor,
    required this.grossProfit,
    required this.profitShare,
  });
}

/// One row per [investors] entry, in the same order — every investor is
/// included even at zero, so a report never silently omits someone who
/// simply had no sales this period (that omission is itself useful
/// information, e.g. "this investor's stock didn't move at all in
/// August").
///
/// [salesInRange] must already be filtered to the report's `DateRange`
/// (`list.whereInRange(range, (s) => s.date)`) — this function has no
/// knowledge of dates, matching every other pure calculator in this
/// directory.
List<InvestorPeriodShare> computeInvestorProfitShareReport({
  required List<Investor> investors,
  required List<Sale> salesInRange,
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);
  return investors.map((investor) {
    final theirSales = salesInRange.where(
      (s) => s.fundSource.investorId == investor.id,
    );
    final grossProfit = theirSales.fold(
      zero,
      (sum, sale) => sum + calculateGrossProfitPerSale(sale),
    );
    final share = calculateInvestorProfitShare(
      totalGrossProfitForInvestor: grossProfit,
      investor: investor,
    );
    return InvestorPeriodShare(
      investor: investor,
      grossProfit: grossProfit,
      profitShare: share,
    );
  }).toList();
}

/// One product's aggregated sales for whatever period [salesInRange] was
/// already filtered to.
class ProductPeriodSales {
  final String productId;
  final double qtySold;
  final Money revenue;
  final Money grossProfit;

  const ProductPeriodSales({
    required this.productId,
    required this.qtySold,
    required this.revenue,
    required this.grossProfit,
  });
}

/// Every product that had at least one sale in [salesInRange], sorted by
/// [ProductPeriodSales.revenue] descending — the report's "what actually
/// sold this period" section. Unlike `stock_v2`'s all-time top-sellers
/// list, this is genuinely period-scoped: the same product can rank
/// differently in last month's report versus this month's.
List<ProductPeriodSales> computeProductSalesSummary({
  required List<Sale> salesInRange,
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);
  final byProduct = <String, ({double qty, Money revenue, Money profit})>{};

  for (final sale in salesInRange) {
    final existing =
        byProduct[sale.productId] ?? (qty: 0.0, revenue: zero, profit: zero);
    byProduct[sale.productId] = (
      qty: existing.qty + sale.qty,
      revenue: existing.revenue + sale.actualSellPrice * sale.qty,
      profit: existing.profit + calculateGrossProfitPerSale(sale),
    );
  }

  final rows = byProduct.entries
      .map(
        (e) => ProductPeriodSales(
          productId: e.key,
          qtySold: e.value.qty,
          revenue: e.value.revenue,
          grossProfit: e.value.profit,
        ),
      )
      .toList();
  rows.sort((a, b) => b.revenue.compareTo(a.revenue));
  return rows;
}
