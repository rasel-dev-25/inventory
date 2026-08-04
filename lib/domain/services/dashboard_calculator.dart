/// Dashboard totals, per `notes/business_logic.md` §ঝ:
///
/// ```
/// Total Cash = Σ(Sale cash portion) + Σ(Due payments received) + Σ(Rent income)
///            − Σ(Purchase cash portion, isInKind=false)
///            − Σ(Expense: monthly_rent + daily_other)
///            − Σ(InvestorRepayment)
/// ```
///
/// and its explicit implementation note:
///
/// > "একই ক্যালকুলেশন ফাংশনে dateRange প্যারামিটার দিয়ে Day view ও All-time
/// > view — দুটোই একই লজিক দিয়ে সার্ভ করা ভালো"
///
/// [computeDashboardTotals] is that one function — [DashboardController]
/// filters every list it passes in by a `DateRange` (day or all-time)
/// before calling this, exactly like `calculateCashBalances` already
/// establishes for the cash sub-balances.
///
/// **totalCash is exact** — it is literally `calculateCashBalances`'s
/// total over whatever [CashLedgerEntry] rows are in range, and every
/// cash-moving event this app can record today (a sale's cash portion, a
/// due payment, a purchase trip's cash-out, an expense, an investor
/// repayment) already writes one. It will automatically pick up rent
/// income too, with no change to this function, the moment that v2 use
/// case exists (M3) and starts writing its own ledger entries — see
/// `lib/data/local/tables/ledger.dart`'s doc comment for why this table
/// is deliberately the one place that can never happen.
///
/// **netProfit is now true net profit** — [expensesInRange] is populated
/// from `ExpenseDao.watchAll` by `DashboardController`. It used to always
/// be `[]` (gross-profit-only) before the Expense module existed; kept
/// as its own parameter rather than folded into the ledger sum because
/// `calculateShopNetProfit` needs the raw expense amounts, not their
/// already-negated cash-ledger form.
library;

import '../../core/money/money.dart';
import '../entities/cash_ledger_entry.dart';
import '../entities/purchase.dart';
import '../entities/sale.dart';
import 'cash_balance_calculator.dart';
import 'profit_calculator.dart';
import 'purchase_reconciliation.dart';

/// One [StockMovements] row already paired with that product's *current*
/// cost price — see [computeDashboardTotals]'s `stockMovementsInRange`
/// parameter doc comment for why "current", not historical, price is the
/// deliberately correct choice here, not a shortcut.
class ValuedStockMovement {
  final double deltaQty;
  final Money costPriceNow;

  const ValuedStockMovement({
    required this.deltaQty,
    required this.costPriceNow,
  });
}

class DashboardTotals {
  final Money totalCash;
  final Money totalSaleRevenue;
  final Money totalPurchaseCashOut;
  final Money netProfit;
  final Money stockValue;

  const DashboardTotals({
    required this.totalCash,
    required this.totalSaleRevenue,
    required this.totalPurchaseCashOut,
    required this.netProfit,
    required this.stockValue,
  });
}

/// Computes every Dashboard card's figure from whatever rows the caller
/// has already filtered into a `DateRange` (day or all-time) — this
/// function itself has no knowledge of dates at all, matching the spec's
/// "one calculation, two views" instruction exactly.
///
/// [stockMovementsInRange] must carry each movement's *current* product
/// cost price, not the price at the time the movement happened. That is
/// deliberate, not a simplification: because `Products.qty` is defined as
/// the sum of all its movements (`lib/data/local/tables/ledger.dart`),
/// `Σ(deltaQty × currentCostPrice)` over *every* movement a product has
/// ever had collapses to exactly `currentQty × currentCostPrice` — i.e.
/// today's on-hand stock value, the same number `StockController`
/// already shows. Filtering that same sum down to only today's movements
/// gives exactly the spec's Day-view "stock added minus stock sold
/// today" figure, via the identical formula. One formula, two ranges, no
/// second stock-valuation code path to drift out of sync with the first.
DashboardTotals computeDashboardTotals({
  required List<CashLedgerEntry> ledgerEntriesInRange,
  required List<Sale> salesInRange,
  required List<PurchaseTrip> purchaseTripsInRange,
  required List<ValuedStockMovement> stockMovementsInRange,
  List<Money> expensesInRange = const [],
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);

  final totalCash = calculateCashBalances(
    ledgerEntriesInRange,
    currency: currency,
  ).totalAvailableFunds;

  final totalSaleRevenue = salesInRange.fold(
    zero,
    (sum, sale) => sum + sale.actualSellPrice * sale.qty,
  );

  final totalPurchaseCashOut = purchaseTripsInRange.fold(
    zero,
    (sum, trip) => sum + reconcilePurchaseTrip(trip).totalCashOut,
  );

  final netProfit = calculateShopNetProfit(
    grossProfitsFromAllSales: salesInRange.map(calculateGrossProfitPerSale),
    expenses: expensesInRange,
    currency: currency,
  );

  final stockValue = stockMovementsInRange.fold(
    zero,
    (sum, movement) => sum + movement.costPriceNow * movement.deltaQty,
  );

  return DashboardTotals(
    totalCash: totalCash,
    totalSaleRevenue: totalSaleRevenue,
    totalPurchaseCashOut: totalPurchaseCashOut,
    netProfit: netProfit,
    stockValue: stockValue,
  );
}
