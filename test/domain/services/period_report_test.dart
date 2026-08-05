import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/domain/services/period_report.dart';

Sale _sale({
  required String productId,
  required FundSource fundSource,
  required int qty,
  required int sellPrice,
  required int costPrice,
}) {
  return Sale(
    id: 'sale-$productId-$sellPrice-$qty',
    productId: productId,
    qty: qty.toDouble(),
    actualSellPrice: Money.fromMinor(sellPrice),
    costPriceAtSale: Money.fromMinor(costPrice),
    date: DateTime.utc(2026, 8, 5),
    paymentStatus: PaymentStatus.fullCash,
    paymentMethod: PaymentMethod.cash,
    fundSource: fundSource,
  );
}

void main() {
  group('computeInvestorProfitShareReport', () {
    final karim = Investor(
      id: 'karim',
      name: 'Uncle Karim',
      investmentType: InvestmentType.cashMudaraba,
      profitSharePercent: 30,
    );
    final loanInvestor = Investor(
      id: 'loan-investor',
      name: 'Loan Investor',
      investmentType: InvestmentType.cashLoan,
      profitSharePercent: 40, // ignored — cash loan is always zero share
    );

    test('computes gross profit and profit share per investor', () {
      final sales = [
        _sale(
          productId: 'book-a',
          fundSource: FundSource.investor('karim'),
          qty: 2,
          sellPrice: 15000,
          costPrice: 10000,
        ),
        _sale(
          productId: 'book-b',
          fundSource: FundSource.investor('karim'),
          qty: 1,
          sellPrice: 20000,
          costPrice: 12000,
        ),
      ];

      final report = computeInvestorProfitShareReport(
        investors: [karim],
        salesInRange: sales,
      );

      expect(report, hasLength(1));
      // Gross profit: (150-100)*2 + (200-120)*1 = 100 + 80 = ৳180.
      expect(report.single.grossProfit, Money.fromMinor(18000));
      // 30% of ৳180 = ৳54.
      expect(report.single.profitShare, Money.fromMinor(5400));
    });

    test('includes an investor with zero sales this period, at zero', () {
      final report = computeInvestorProfitShareReport(
        investors: [karim],
        salesInRange: const [],
      );
      expect(report.single.grossProfit, Money.zero());
      expect(report.single.profitShare, Money.zero());
    });

    test('a cashLoan investor always shows a zero profit share', () {
      final sales = [
        _sale(
          productId: 'book-a',
          fundSource: FundSource.investor('loan-investor'),
          qty: 1,
          sellPrice: 20000,
          costPrice: 10000,
        ),
      ];
      final report = computeInvestorProfitShareReport(
        investors: [loanInvestor],
        salesInRange: sales,
      );
      expect(report.single.grossProfit, Money.fromMinor(10000));
      expect(report.single.profitShare, Money.zero());
    });

    test('ignores sales funded by a different investor or the shop', () {
      final sales = [
        _sale(
          productId: 'book-a',
          fundSource: FundSource.shop(),
          qty: 5,
          sellPrice: 20000,
          costPrice: 10000,
        ),
      ];
      final report = computeInvestorProfitShareReport(
        investors: [karim],
        salesInRange: sales,
      );
      expect(report.single.grossProfit, Money.zero());
    });
  });

  group('computeProductSalesSummary', () {
    test('aggregates quantity, revenue, and gross profit per product', () {
      final sales = [
        _sale(
          productId: 'book-a',
          fundSource: FundSource.shop(),
          qty: 2,
          sellPrice: 15000,
          costPrice: 10000,
        ),
        _sale(
          productId: 'book-a',
          fundSource: FundSource.shop(),
          qty: 3,
          sellPrice: 15000,
          costPrice: 10000,
        ),
      ];

      final summary = computeProductSalesSummary(salesInRange: sales);

      expect(summary, hasLength(1));
      expect(summary.single.productId, 'book-a');
      expect(summary.single.qtySold, 5);
      expect(summary.single.revenue, Money.fromMinor(75000));
      expect(summary.single.grossProfit, Money.fromMinor(25000));
    });

    test('sorts by revenue descending', () {
      final sales = [
        _sale(
          productId: 'low-revenue',
          fundSource: FundSource.shop(),
          qty: 1,
          sellPrice: 5000,
          costPrice: 2000,
        ),
        _sale(
          productId: 'high-revenue',
          fundSource: FundSource.shop(),
          qty: 1,
          sellPrice: 50000,
          costPrice: 20000,
        ),
      ];

      final summary = computeProductSalesSummary(salesInRange: sales);

      expect(summary.map((r) => r.productId).toList(), [
        'high-revenue',
        'low-revenue',
      ]);
    });

    test('empty when there are no sales in range', () {
      expect(computeProductSalesSummary(salesInRange: const []), isEmpty);
    });
  });
}
