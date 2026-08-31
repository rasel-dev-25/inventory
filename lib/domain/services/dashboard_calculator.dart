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
library;

import '../../core/money/money.dart';
import '../entities/cash_ledger_entry.dart';
import '../entities/due.dart';
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
  final Money totalDue;
  final Money totalExpense;
  final Money totalInvestorRemaining;
  final Money dailyInvestorObligation;
  final Money monthlyShopRent;
  final Money rentPaidThisMonth;
  final Money rentRemainingThisMonth;
  final Money dailyRentObligation;

  const DashboardTotals({
    required this.totalCash,
    required this.totalSaleRevenue,
    required this.totalPurchaseCashOut,
    required this.netProfit,
    required this.stockValue,
    required this.totalDue,
    required this.totalExpense,
    required this.totalInvestorRemaining,
    required this.dailyInvestorObligation,
    this.monthlyShopRent = Money.zeroBdt,
    this.rentPaidThisMonth = Money.zeroBdt,
    this.rentRemainingThisMonth = Money.zeroBdt,
    this.dailyRentObligation = Money.zeroBdt,
  });

  Money get totalPayableObligations =>
      totalInvestorRemaining + rentRemainingThisMonth;
  Money get dailyTotalObligation =>
      dailyInvestorObligation + dailyRentObligation;
}

/// Computes every Dashboard card's figure from whatever rows the caller
/// has already filtered into a `DateRange` (day or all-time) — this
/// function itself has no knowledge of dates at all, matching the spec's
/// "one calculation, two views" instruction exactly.
DashboardTotals computeDashboardTotals({
  required List<CashLedgerEntry> ledgerEntriesInRange,
  required List<Sale> salesInRange,
  required List<PurchaseTrip> purchaseTripsInRange,
  required List<ValuedStockMovement> stockMovementsInRange,
  List<Money> expensesInRange = const [],
  List<Due> duesInRange = const [],
  Money? totalInvestorRemaining,
  Money? dailyInvestorObligation,
  Money? monthlyShopRent,
  Money? rentPaidThisMonth,
  Money? rentRemainingThisMonth,
  Money? dailyRentObligation,
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

  final totalExpense = expensesInRange.fold(
    zero,
    (sum, amount) => sum + amount,
  );

  final totalDue = duesInRange.fold(
    zero,
    (sum, due) => sum + (due.originalAmount - due.paidAmount),
  );

  return DashboardTotals(
    totalCash: totalCash,
    totalSaleRevenue: totalSaleRevenue,
    totalPurchaseCashOut: totalPurchaseCashOut,
    netProfit: netProfit,
    stockValue: stockValue,
    totalDue: totalDue,
    totalExpense: totalExpense,
    totalInvestorRemaining: totalInvestorRemaining ?? zero,
    dailyInvestorObligation: dailyInvestorObligation ?? zero,
    monthlyShopRent: monthlyShopRent ?? zero,
    rentPaidThisMonth: rentPaidThisMonth ?? zero,
    rentRemainingThisMonth: rentRemainingThisMonth ?? zero,
    dailyRentObligation: dailyRentObligation ?? zero,
  );
}
