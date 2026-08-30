import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/cash_ledger_entry.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/domain/services/dashboard_calculator.dart';

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
    fundSource: FundSource.shop(),
  );
}

CashLedgerEntry _ledgerEntry(String amount, {String sourceType = 'sale'}) {
  return CashLedgerEntry(
    id: 'l1',
    amount: Money.parse(amount),
    paymentMethod: PaymentMethod.cash,
    sourceType: sourceType,
    sourceId: 's1',
    date: DateTime.utc(2026, 8, 4),
  );
}

PurchaseTrip _trip({required String itemPrice, double qty = 1}) {
  return PurchaseTrip(
    id: 't1',
    date: DateTime.utc(2026, 8, 4),
    transportCost: Money.zero(),
    cashReturned: Money.zero(),
    items: [
      PurchaseItem(
        id: 'i1',
        shopName: 'Mokam',
        productId: 'p1',
        qty: qty,
        unitPrice: Money.parse(itemPrice),
        fundSource: FundSource.shop(),
      ),
    ],
  );
}

void main() {
  group('computeDashboardTotals', () {
    test('totalCash is exactly the sum of ledger entries in range', () {
      final totals = computeDashboardTotals(
        ledgerEntriesInRange: [_ledgerEntry('100'), _ledgerEntry('-30')],
        salesInRange: const [],
        purchaseTripsInRange: const [],
        stockMovementsInRange: const [],
      );
      expect(totals.totalCash, Money.parse('70'));
    });

    test(
      'totalSaleRevenue sums actualSellPrice times qty, not cash received',
      () {
        final totals = computeDashboardTotals(
          ledgerEntriesInRange: const [],
          salesInRange: [
            _sale(sellPrice: '150', costPrice: '100', qty: 2),
            _sale(sellPrice: '80', costPrice: '50'),
          ],
          purchaseTripsInRange: const [],
          stockMovementsInRange: const [],
        );
        // 150*2 + 80 = 380 — a partial/due sale still counts its full total.
        expect(totals.totalSaleRevenue, Money.parse('380'));
      },
    );

    test('totalPurchaseCashOut delegates to reconcilePurchaseTrip', () {
      final totals = computeDashboardTotals(
        ledgerEntriesInRange: const [],
        salesInRange: const [],
        purchaseTripsInRange: [_trip(itemPrice: '200', qty: 3)],
        stockMovementsInRange: const [],
      );
      expect(totals.totalPurchaseCashOut, Money.parse('600'));
    });

    test(
      'netProfit is gross profit minus expenses when expenses are given',
      () {
        final totals = computeDashboardTotals(
          ledgerEntriesInRange: const [],
          salesInRange: [_sale(sellPrice: '150', costPrice: '100', qty: 2)],
          purchaseTripsInRange: const [],
          stockMovementsInRange: const [],
          expensesInRange: [Money.parse('30')],
        );
        // gross profit = (150-100)*2 = 100; net = 100 - 30 = 70.
        expect(totals.netProfit, Money.parse('70'));
      },
    );

    test(
      'netProfit equals total gross profit when there are no expenses yet',
      () {
        final totals = computeDashboardTotals(
          ledgerEntriesInRange: const [],
          salesInRange: [_sale(sellPrice: '150', costPrice: '100', qty: 2)],
          purchaseTripsInRange: const [],
          stockMovementsInRange: const [],
        );
        expect(totals.netProfit, Money.parse('100'));
      },
    );

    test(
      'stockValue sums deltaQty times current cost price, sign preserved',
      () {
        final totals = computeDashboardTotals(
          ledgerEntriesInRange: const [],
          salesInRange: const [],
          purchaseTripsInRange: const [],
          stockMovementsInRange: [
            ValuedStockMovement(deltaQty: 10, costPriceNow: Money.parse('100')),
            ValuedStockMovement(deltaQty: -3, costPriceNow: Money.parse('100')),
          ],
        );
        // (10 + (-3)) * 100 = 700 — net units on hand, valued at current cost.
        expect(totals.stockValue, Money.parse('700'));
      },
    );

    test(
      'stockValue over every movement a product ever had equals its current on-hand value',
      () {
        // Simulates the file-level doc comment's claim: summing every
        // movement (purchase +12, two sales -5 and -2) at the *current*
        // cost price gives exactly currentQty (5) * currentCostPrice.
        final totals = computeDashboardTotals(
          ledgerEntriesInRange: const [],
          salesInRange: const [],
          purchaseTripsInRange: const [],
          stockMovementsInRange: [
            ValuedStockMovement(deltaQty: 12, costPriceNow: Money.parse('40')),
            ValuedStockMovement(deltaQty: -5, costPriceNow: Money.parse('40')),
            ValuedStockMovement(deltaQty: -2, costPriceNow: Money.parse('40')),
          ],
        );
        expect(totals.stockValue, Money.parse('40') * 5);
      },
    );

    test('totalExpense sums all expense amounts in range', () {
      final totals = computeDashboardTotals(
        ledgerEntriesInRange: const [],
        salesInRange: const [],
        purchaseTripsInRange: const [],
        stockMovementsInRange: const [],
        expensesInRange: [Money.parse('150'), Money.parse('350')],
      );
      expect(totals.totalExpense, Money.parse('500'));
    });

    test('totalDue sums remaining uncollected balances from dues in range', () {
      final due1 = Due(
        id: 'd1',
        customerId: 'c1',
        sourceType: DueSourceType.sale,
        sourceId: 's1',
        originalAmount: Money.parse('500'),
        paidAmount: Money.parse('100'),
        status: DueStatus.partiallyPaid,
        createdAt: DateTime.utc(2026, 8, 4),
      );
      final due2 = Due(
        id: 'd2',
        customerId: 'c2',
        sourceType: DueSourceType.sale,
        sourceId: 's2',
        originalAmount: Money.parse('300'),
        paidAmount: Money.zero(),
        status: DueStatus.pending,
        createdAt: DateTime.utc(2026, 8, 4),
      );
      final totals = computeDashboardTotals(
        ledgerEntriesInRange: const [],
        salesInRange: const [],
        purchaseTripsInRange: const [],
        stockMovementsInRange: const [],
        duesInRange: [due1, due2],
      );
      // (500 - 100) + (300 - 0) = 700
      expect(totals.totalDue, Money.parse('700'));
    });

    test('carries totalInvestorRemaining and dailyInvestorObligation', () {
      final totals = computeDashboardTotals(
        ledgerEntriesInRange: const [],
        salesInRange: const [],
        purchaseTripsInRange: const [],
        stockMovementsInRange: const [],
        totalInvestorRemaining: Money.parse('50000'),
        dailyInvestorObligation: Money.parse('555.55'),
      );
      expect(totals.totalInvestorRemaining, Money.parse('50000'));
      expect(totals.dailyInvestorObligation, Money.parse('555.55'));
    });
  });
}
