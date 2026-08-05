import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/domain/services/pricing_engine.dart';

Investor _investor({
  InvestmentType type = InvestmentType.cashMudaraba,
  double profitSharePercent = 30,
}) {
  return Investor(
    id: 'investor-1',
    name: 'Uncle Karim',
    investmentType: type,
    profitSharePercent: profitSharePercent,
  );
}

Sale _sale({required DateTime date, required int qty, required int price}) {
  return Sale(
    id: 'sale-${date.toIso8601String()}-$price',
    productId: 'book-a',
    qty: qty.toDouble(),
    actualSellPrice: Money.fromMinor(price),
    costPriceAtSale: Money.fromMinor((price * 0.6).round()),
    date: date,
    paymentStatus: PaymentStatus.fullCash,
    paymentMethod: PaymentMethod.cash,
    fundSource: FundSource.shop(),
  );
}

PurchaseTrip _trip({
  required DateTime date,
  required int transportCostMinor,
  int otherCostMinor = 0,
}) {
  return PurchaseTrip(
    id: 'trip-${date.toIso8601String()}',
    date: date,
    transportCost: Money.fromMinor(transportCostMinor),
    otherCosts: otherCostMinor == 0
        ? const []
        : [
            OtherCost(
              description: 'tip',
              amount: Money.fromMinor(otherCostMinor),
            ),
          ],
    cashReturned: Money.zero(),
    items: const [],
  );
}

void main() {
  group('computeOverheadMarkupPercent', () {
    test(
      'null when estimatedMonthlySalesRevenue is null (bootstrap period)',
      () {
        final settings = OverheadSettings(
          monthlyShopRent: Money.fromMinor(1000000),
          monthlyOwnerSalary: Money.fromMinor(2000000),
          averageMonthlyTripCost: Money.fromMinor(500000),
          estimatedMonthlySalesRevenue: null,
        );
        expect(computeOverheadMarkupPercent(settings), isNull);
      },
    );

    test('null when the revenue estimate is zero', () {
      final settings = OverheadSettings(
        monthlyShopRent: Money.fromMinor(1000000),
        monthlyOwnerSalary: Money.zero(),
        averageMonthlyTripCost: Money.zero(),
        estimatedMonthlySalesRevenue: Money.zero(),
      );
      expect(computeOverheadMarkupPercent(settings), isNull);
    });

    test('divides monthly overhead by the revenue estimate', () {
      // Overhead: ৳10,000 + ৳20,000 + ৳5,000 = ৳35,000. Revenue: ৳100,000.
      final settings = OverheadSettings(
        monthlyShopRent: Money.fromMinor(1000000),
        monthlyOwnerSalary: Money.fromMinor(2000000),
        averageMonthlyTripCost: Money.fromMinor(500000),
        estimatedMonthlySalesRevenue: Money.fromMinor(10000000),
      );
      expect(computeOverheadMarkupPercent(settings), closeTo(0.35, 0.0001));
    });
  });

  group('effectiveProfitSharePercent', () {
    test('a cashLoan investor always has a zero effective share', () {
      final investor = _investor(
        type: InvestmentType.cashLoan,
        profitSharePercent: 40,
      );
      expect(effectiveProfitSharePercent(investor), 0);
    });

    test('any other investment type uses the stored share', () {
      final investor = _investor(
        type: InvestmentType.cashMusharaka,
        profitSharePercent: 25,
      );
      expect(effectiveProfitSharePercent(investor), 25);
    });
  });

  group('computeRequiredMargin', () {
    test('equals the overhead markup when there is no investor share', () {
      expect(
        computeRequiredMargin(overheadMarkupPercent: 0.35),
        closeTo(0.35, 0.0001),
      );
    });

    test('divides by (1 - share) for an investor-funded product', () {
      // 0.35 / (1 - 0.30) = 0.5
      expect(
        computeRequiredMargin(
          overheadMarkupPercent: 0.35,
          investorProfitSharePercent: 30,
        ),
        closeTo(0.5, 0.0001),
      );
    });

    test('null at a 100% investor share (division by zero)', () {
      expect(
        computeRequiredMargin(
          overheadMarkupPercent: 0.35,
          investorProfitSharePercent: 100,
        ),
        isNull,
      );
    });

    test('null above a 100% investor share', () {
      expect(
        computeRequiredMargin(
          overheadMarkupPercent: 0.35,
          investorProfitSharePercent: 150,
        ),
        isNull,
      );
    });
  });

  group('suggestSellPrice', () {
    test('shop-funded product uses the overhead markup directly', () {
      final price = suggestSellPrice(
        costPrice: Money.fromMinor(10000),
        overheadMarkupPercent: 0.35,
        fundSource: FundSource.shop(),
      );
      // ৳100 × 1.35 = ৳135.
      expect(price, Money.fromMinor(13500));
    });

    test('investor-funded product compensates for the profit share', () {
      final price = suggestSellPrice(
        costPrice: Money.fromMinor(10000),
        overheadMarkupPercent: 0.35,
        fundSource: FundSource.investor('investor-1'),
        fundingInvestor: _investor(profitSharePercent: 30),
      );
      // requiredMargin = 0.35 / 0.70 = 0.5 → ৳100 × 1.5 = ৳150.
      expect(price, Money.fromMinor(15000));
    });

    test(
      'a cash-loan investor-funded product behaves like a shop-funded one',
      () {
        final price = suggestSellPrice(
          costPrice: Money.fromMinor(10000),
          overheadMarkupPercent: 0.35,
          fundSource: FundSource.investor('investor-1'),
          fundingInvestor: _investor(
            type: InvestmentType.cashLoan,
            profitSharePercent: 40,
          ),
        );
        expect(price, Money.fromMinor(13500));
      },
    );

    test(
      'treats a missing fundingInvestor as a zero share (caller must resolve it)',
      () {
        final price = suggestSellPrice(
          costPrice: Money.fromMinor(10000),
          overheadMarkupPercent: 0.35,
          fundSource: FundSource.investor('investor-1'),
        );
        expect(price, Money.fromMinor(13500));
      },
    );

    test('null when the required margin is undefined', () {
      final price = suggestSellPrice(
        costPrice: Money.fromMinor(10000),
        overheadMarkupPercent: 0.35,
        fundSource: FundSource.investor('investor-1'),
        fundingInvestor: _investor(profitSharePercent: 100),
      );
      expect(price, isNull);
    });
  });

  group('computeAverageMonthlyTripCost', () {
    test('zero when there are no trips', () {
      expect(
        computeAverageMonthlyTripCost(
          trips: const [],
          asOf: DateTime.utc(2026, 8, 1),
        ),
        Money.zero(),
      );
    });

    test('averages the last N completed calendar months', () {
      final trips = [
        _trip(
          date: DateTime.utc(2026, 5, 10),
          transportCostMinor: 10000,
        ), // May
        _trip(date: DateTime.utc(2026, 6, 5), transportCostMinor: 20000), // Jun
        _trip(
          date: DateTime.utc(2026, 6, 20),
          transportCostMinor: 10000,
        ), // Jun
        _trip(
          date: DateTime.utc(2026, 7, 15),
          transportCostMinor: 30000,
        ), // Jul
      ];
      // May ৳100, Jun ৳300, Jul ৳300 → average ৳(100+300+300)/3 = ৳233.33.
      final result = computeAverageMonthlyTripCost(
        trips: trips,
        asOf: DateTime.utc(2026, 8, 5),
        monthsToAverage: 3,
      );
      expect(result, Money.fromMinor(23333));
    });

    test('excludes trips from the current, still-in-progress month', () {
      final trips = [
        _trip(date: DateTime.utc(2026, 7, 15), transportCostMinor: 10000),
        _trip(date: DateTime.utc(2026, 8, 2), transportCostMinor: 100000000),
      ];
      final result = computeAverageMonthlyTripCost(
        trips: trips,
        asOf: DateTime.utc(2026, 8, 5),
        monthsToAverage: 3,
      );
      expect(result, Money.fromMinor(10000));
    });

    test('includes otherCosts alongside transportCost', () {
      final trips = [
        _trip(
          date: DateTime.utc(2026, 7, 10),
          transportCostMinor: 10000,
          otherCostMinor: 5000,
        ),
      ];
      final result = computeAverageMonthlyTripCost(
        trips: trips,
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(result, Money.fromMinor(15000));
    });
  });

  group('computeActualSalesRevenueForPreviousMonth', () {
    test('sums only sales dated in the single previous calendar month', () {
      final sales = [
        _sale(
          date: DateTime.utc(2026, 6, 28),
          qty: 1,
          price: 10000,
        ), // Jun — excluded
        _sale(date: DateTime.utc(2026, 7, 3), qty: 2, price: 15000), // Jul
        _sale(date: DateTime.utc(2026, 7, 20), qty: 1, price: 20000), // Jul
        _sale(
          date: DateTime.utc(2026, 8, 1),
          qty: 5,
          price: 10000,
        ), // Aug — excluded (current month)
      ];
      final revenue = computeActualSalesRevenueForPreviousMonth(
        sales: sales,
        asOf: DateTime.utc(2026, 8, 5),
      );
      // (2 × ৳150) + (1 × ৳200) = ৳500.
      expect(revenue, Money.fromMinor(50000));
    });

    test('zero when nothing was sold in the previous month', () {
      final revenue = computeActualSalesRevenueForPreviousMonth(
        sales: const [],
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(revenue, Money.zero());
    });
  });

  group('monthKey', () {
    test('formats as zero-padded YYYY-MM', () {
      expect(monthKey(DateTime.utc(2026, 1, 1)), '2026-01');
      expect(monthKey(DateTime.utc(2026, 12, 1)), '2026-12');
    });
  });
}
