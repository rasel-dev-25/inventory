import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/domain/services/investor_metrics.dart';

const _investorId = 'investor-1';

Investor _investor({
  InvestmentType type = InvestmentType.cashMudaraba,
  double profitSharePercent = 30,
}) {
  return Investor(
    id: _investorId,
    name: 'Uncle Karim',
    investmentType: type,
    profitSharePercent: profitSharePercent,
  );
}

PurchaseItem _item({
  required String price,
  double qty = 1,
  bool isInKind = false,
}) {
  return PurchaseItem(
    id: 'item-1',
    shopName: 'Mokam',
    productId: 'p1',
    qty: qty,
    unitPrice: Money.parse(price),
    fundSource: FundSource.investor(_investorId),
    isInKind: isInKind,
  );
}

Sale _sale({
  required String sellPrice,
  required String costPrice,
  double qty = 1,
}) {
  return Sale(
    id: 's1',
    productId: 'p1',
    qty: qty,
    actualSellPrice: Money.parse(sellPrice),
    costPriceAtSale: Money.parse(costPrice),
    date: DateTime.utc(2026, 8, 4),
    paymentStatus: PaymentStatus.fullCash,
    paymentMethod: PaymentMethod.cash,
    fundSource: FundSource.investor(_investorId),
  );
}

void main() {
  group('computeInvestorMetrics', () {
    test('totalInvestment sums cash and in-kind purchase items together', () {
      final metrics = computeInvestorMetrics(
        investor: _investor(),
        purchaseItemsForInvestor: [
          _item(price: '1000', qty: 2), // cash: 2000
          _item(price: '500', qty: 1, isInKind: true), // in-kind: 500
        ],
        productsForInvestor: const [],
        salesForInvestor: const [],
        capitalReturnRepayments: const [],
      );
      expect(metrics.totalInvestment, Money.parse('2500'));
    });

    test('totalPurchasedCash excludes in-kind items', () {
      final metrics = computeInvestorMetrics(
        investor: _investor(),
        purchaseItemsForInvestor: [
          _item(price: '1000', qty: 2),
          _item(price: '500', qty: 1, isInKind: true),
        ],
        productsForInvestor: const [],
        salesForInvestor: const [],
        capitalReturnRepayments: const [],
      );
      expect(metrics.totalPurchasedCash, Money.parse('2000'));
    });

    test('currentStockValue is qty times cost price over their products', () {
      final metrics = computeInvestorMetrics(
        investor: _investor(),
        purchaseItemsForInvestor: const [],
        productsForInvestor: [
          Product(
            id: 'p1',
            name: 'Book A',
            category: 'Book',
            costPrice: Money.parse('100'),
            suggestedSellPrice: Money.parse('150'),
            qty: 6,
            fundSource: FundSource.investor(_investorId),
          ),
        ],
        salesForInvestor: const [],
        capitalReturnRepayments: const [],
      );
      expect(metrics.currentStockValue, Money.parse('600'));
    });

    test('totalSoldRevenue and profitShare come from their sales', () {
      final metrics = computeInvestorMetrics(
        investor: _investor(profitSharePercent: 30),
        purchaseItemsForInvestor: const [],
        productsForInvestor: const [],
        salesForInvestor: [_sale(sellPrice: '150', costPrice: '100', qty: 2)],
        capitalReturnRepayments: const [],
      );
      expect(metrics.totalSoldRevenue, Money.parse('300'));
      // gross profit = (150-100)*2 = 100; 30% share = 30.
      expect(metrics.profitShare, Money.parse('30'));
    });

    test('a cash-loan investor always has a zero profit share', () {
      final metrics = computeInvestorMetrics(
        investor: _investor(
          type: InvestmentType.cashLoan,
          profitSharePercent: 0,
        ),
        purchaseItemsForInvestor: const [],
        productsForInvestor: const [],
        salesForInvestor: [_sale(sellPrice: '150', costPrice: '100', qty: 2)],
        capitalReturnRepayments: const [],
      );
      expect(metrics.profitShare.isZero, isTrue);
    });

    test(
      'remainingBalance is totalInvestment minus capital-return repayments only',
      () {
        final metrics = computeInvestorMetrics(
          investor: _investor(),
          purchaseItemsForInvestor: [_item(price: '1000', qty: 1)],
          productsForInvestor: const [],
          salesForInvestor: const [],
          capitalReturnRepayments: [Money.parse('400')],
        );
        expect(metrics.totalRepaidCapital, Money.parse('400'));
        expect(metrics.remainingBalance, Money.parse('600'));
      },
    );
  });
}
