import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/domain/services/profit_calculator.dart';

Sale _sale({
  required String sellPrice,
  required String costPrice,
  double qty = 1,
  FundSource? fundSource,
}) {
  return Sale(
    id: 's1',
    productId: 'p1',
    qty: qty,
    actualSellPrice: Money.parse(sellPrice),
    costPriceAtSale: Money.parse(costPrice),
    date: DateTime.utc(2026, 8, 3),
    paymentStatus: PaymentStatus.fullCash,
    paymentMethod: PaymentMethod.cash,
    fundSource: fundSource ?? FundSource.shop(),
  );
}

void main() {
  group('calculateGrossProfitPerSale', () {
    test('is sellPrice minus costPrice, scaled by qty', () {
      final sale = _sale(sellPrice: '150', costPrice: '100', qty: 3);
      expect(calculateGrossProfitPerSale(sale), Money.parse('150'));
    });

    test('is zero when sold exactly at cost', () {
      final sale = _sale(sellPrice: '100', costPrice: '100');
      expect(calculateGrossProfitPerSale(sale).isZero, isTrue);
    });

    test('can be negative when sold below cost (a loss-leader sale)', () {
      final sale = _sale(sellPrice: '80', costPrice: '100');
      expect(calculateGrossProfitPerSale(sale), Money.parse('-20'));
    });

    test(
      'does not know about expenses at all — it is a pure per-sale number',
      () {
        // There is no expenses parameter on this function's signature —
        // this test exists to make that contract explicit and regression-
        // proof against a future "helpful" refactor that tries to merge the
        // two profit tiers.
        final sale = _sale(sellPrice: '150', costPrice: '100');
        expect(calculateGrossProfitPerSale(sale), Money.parse('50'));
      },
    );
  });

  group('calculateShopNetProfit', () {
    test('sums gross profits then subtracts expenses', () {
      final grossProfits = [
        Money.parse('100'),
        Money.parse('200'),
        Money.parse('50'),
      ];
      final expenses = [Money.parse('80'), Money.parse('20')];
      final net = calculateShopNetProfit(
        grossProfitsFromAllSales: grossProfits,
        expenses: expenses,
      );
      // 100 + 200 + 50 - 80 - 20 = 250
      expect(net, Money.parse('250'));
    });

    test('can go negative when expenses exceed gross profit', () {
      final net = calculateShopNetProfit(
        grossProfitsFromAllSales: [Money.parse('50')],
        expenses: [Money.parse('200')],
      );
      expect(net, Money.parse('-150'));
    });

    test('handles empty inputs as zero, not a crash', () {
      final net = calculateShopNetProfit(
        grossProfitsFromAllSales: [],
        expenses: [],
      );
      expect(net.isZero, isTrue);
    });

    test('is a different number from summing gross profits alone — this is '
        'the exact v1 bug (dashboard labelled gross profit as netProfit)', () {
      final grossProfits = [Money.parse('1000')];
      final expenses = [Money.parse('300')];
      final net = calculateShopNetProfit(
        grossProfitsFromAllSales: grossProfits,
        expenses: expenses,
      );
      final grossOnly = grossProfits.fold(Money.zero(), (a, b) => a + b);
      expect(net, isNot(equals(grossOnly)));
      expect(net, Money.parse('700'));
    });
  });

  group('calculateInvestorProfitShare', () {
    test(
      'cashLoan investors always get zero share, regardless of percent on file',
      () {
        final investor = Investor(
          id: 'i1',
          name: 'Legacy lender',
          investmentType: InvestmentType.cashLoan,
          profitSharePercent: 30, // even if someone mistakenly set this
        );
        final share = calculateInvestorProfitShare(
          totalGrossProfitForInvestor: Money.parse('1000'),
          investor: investor,
        );
        expect(share.isZero, isTrue);
      },
    );

    test('mudaraba investors get their configured percentage', () {
      final investor = Investor(
        id: 'i2',
        name: 'Attar Bhai',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 30,
      );
      final share = calculateInvestorProfitShare(
        totalGrossProfitForInvestor: Money.parse('1000'),
        investor: investor,
      );
      expect(share, Money.parse('300'));
    });

    test('goodsInKind investors also earn a share', () {
      final investor = Investor(
        id: 'i3',
        name: 'In-kind supplier',
        investmentType: InvestmentType.goodsInKind,
        profitSharePercent: 50,
      );
      final share = calculateInvestorProfitShare(
        totalGrossProfitForInvestor: Money.parse('200'),
        investor: investor,
      );
      expect(share, Money.parse('100'));
    });

    test(
      'a musharaka investor with 0% configured earns nothing, same result as cashLoan',
      () {
        final investor = Investor(
          id: 'i4',
          name: 'Zero percent',
          investmentType: InvestmentType.cashMusharaka,
          profitSharePercent: 0,
        );
        final share = calculateInvestorProfitShare(
          totalGrossProfitForInvestor: Money.parse('500'),
          investor: investor,
        );
        expect(share.isZero, isTrue);
      },
    );
  });
}
