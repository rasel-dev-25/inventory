/// Per-investor metrics, per `notes/business_logic.md` §ঙ (Investor page):
///
/// - মোট বিনিয়োগ (total investment) = cash they gave + in-kind valuation
/// - বর্তমান স্টক মূল্য (current stock value, in their name)
/// - কেনা (total purchased, cash portion only)
/// - বিক্রি (total sold, at actual sell price)
/// - লাভ (তার ভাগ) (their profit share)
/// - বাকি ব্যালেন্স / ফেরত পাওনা (remaining balance owed)
///
/// [computeInvestorMetrics] is a pure function, same discipline as
/// `profit_calculator.dart`/`purchase_reconciliation.dart`/
/// `dashboard_calculator.dart` — every list argument must already be
/// filtered to *this* investor by the caller (`InvestorController`), this
/// function has no database access and no knowledge of any other
/// investor.
///
/// **Deliberately uses [Sale.fundSource]/[Product.fundSource], not a join
/// through a product-ownership lookup at report time.** A [Sale] copies
/// its product's fund source at the moment of sale
/// (`SaveSaleUseCase`'s own doc comment explains why), so filtering sales
/// by `sale.fundSource.investorId` reflects who actually funded *that
/// unit* when it sold — correct even if a product's fund source were ever
/// reassigned later (no such flow exists today, but this metric would
/// stay historically accurate if one did).
///
/// **Not yet implemented, flagged rather than guessed at:** the spec's
/// "কবে দিতে হবে" (next payment due date, from `capitalReturnTermDays`/
/// `profitPayoutCycle`) needs a concrete reference date (first investment
/// date) this function doesn't have — see the working plan for why this
/// is a deferred follow-up, not silently skipped.
library;

import '../../core/money/money.dart';
import '../entities/investor.dart';
import '../entities/product.dart';
import '../entities/purchase.dart';
import '../entities/sale.dart';
import 'profit_calculator.dart';

class InvestorMetrics {
  final Money totalInvestment;
  final Money currentStockValue;
  final Money totalPurchasedCash;
  final Money totalSoldRevenue;
  final Money totalGrossProfit;
  final Money profitShare;
  final Money totalRepaidCapital;
  final Money remainingBalance;

  const InvestorMetrics({
    required this.totalInvestment,
    required this.currentStockValue,
    required this.totalPurchasedCash,
    required this.totalSoldRevenue,
    required this.totalGrossProfit,
    required this.profitShare,
    required this.totalRepaidCapital,
    required this.remainingBalance,
  });
}

/// Computes [investor]'s metrics from pre-filtered lists — every
/// [PurchaseItem] in [purchaseItemsForInvestor], every [Product] in
/// [productsForInvestor], and every [Sale] in [salesForInvestor] must
/// already belong to this investor's fund source; every [Money] in
/// [capitalReturnRepayments] must already be a
/// `RepaymentType.capitalReturn` repayment to this investor (never a
/// profit-share one — see this file's own doc comment on
/// [InvestorMetrics.remainingBalance] for why mixing the two would be
/// wrong).
InvestorMetrics computeInvestorMetrics({
  required Investor investor,
  required List<PurchaseItem> purchaseItemsForInvestor,
  required List<Product> productsForInvestor,
  required List<Sale> salesForInvestor,
  required List<Money> capitalReturnRepayments,
  Currency currency = Currency.bdt,
}) {
  final zero = Money.zero(currency: currency);

  final totalPurchasedCash = purchaseItemsForInvestor
      .where((item) => !item.isInKind)
      .fold(zero, (sum, item) => sum + item.lineTotal);

  final totalInKind = purchaseItemsForInvestor
      .where((item) => item.isInKind)
      .fold(zero, (sum, item) => sum + item.lineTotal);

  final effectiveCash = investor.initialCashInvestment > totalPurchasedCash
      ? investor.initialCashInvestment
      : totalPurchasedCash;

  final totalInvestment = effectiveCash + totalInKind;

  final currentStockValue = productsForInvestor.fold(
    zero,
    (sum, product) => sum + product.costPrice * product.qty,
  );

  final totalSoldRevenue = salesForInvestor.fold(
    zero,
    (sum, sale) => sum + sale.actualSellPrice * sale.qty,
  );

  final totalGrossProfit = salesForInvestor
      .map(calculateGrossProfitPerSale)
      .fold(zero, (sum, profit) => sum + profit);
  final profitShare = calculateInvestorProfitShare(
    totalGrossProfitForInvestor: totalGrossProfit,
    investor: investor,
  );

  final totalRepaidCapital = capitalReturnRepayments.fold(
    zero,
    (sum, amount) => sum + amount,
  );

  return InvestorMetrics(
    totalInvestment: totalInvestment,
    currentStockValue: currentStockValue,
    totalPurchasedCash: totalPurchasedCash,
    totalSoldRevenue: totalSoldRevenue,
    totalGrossProfit: totalGrossProfit,
    profitShare: profitShare,
    totalRepaidCapital: totalRepaidCapital,
    remainingBalance: totalInvestment - totalRepaidCapital,
  );
}
