import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/services/purchase_reconciliation.dart';

PurchaseItem _item({
  required String qty,
  required String unitPrice,
  FundSource? fundSource,
  bool isInKind = false,
  String shopName = 'Test Shop',
}) {
  return PurchaseItem(
    id: 'item-$qty-$unitPrice-$isInKind',
    shopName: shopName,
    productId: 'p1',
    qty: double.parse(qty),
    unitPrice: Money.parse(unitPrice),
    fundSource: fundSource ?? FundSource.shop(),
    isInKind: isInKind,
  );
}

void main() {
  group('reconcilePurchaseTrip', () {
    test(
      'matches the spec formula for a simple all-cash, single-fund-source trip',
      () {
        final trip = PurchaseTrip(
          id: 't1',
          date: DateTime.utc(2026, 8, 3),
          transportCost: Money.parse('50'),
          otherCosts: [OtherCost(description: 'tip', amount: Money.zero())],
          cashReturned: Money.parse('20'),
          items: [
            _item(qty: '2', unitPrice: '100'), // 200
            _item(qty: '1', unitPrice: '300'), // 300
          ],
        );

        final result = reconcilePurchaseTrip(trip);

        // total items cash = 200 + 300 = 500
        expect(result.totalItemsCash, Money.parse('500'));
        // total cash out = 500 + 50 (transport) + 0 (other) - 20 (returned) = 530
        expect(result.totalCashOut, Money.parse('530'));
        expect(result.reconciles(Money.parse('530')), isTrue);
        expect(result.reconciles(Money.parse('500')), isFalse);
      },
    );

    test(
      'in-kind items never contribute to any cash figure (Data Integrity Rule #2)',
      () {
        final investorSource = FundSource.investor('inv-1');
        final trip = PurchaseTrip(
          id: 't2',
          date: DateTime.utc(2026, 8, 3),
          transportCost: Money.zero(),
          cashReturned: Money.zero(),
          items: [
            _item(
              qty: '1',
              unitPrice: '1000',
              fundSource: investorSource,
              isInKind: true,
            ),
            _item(qty: '2', unitPrice: '50'), // 100, shop cash
          ],
        );

        final result = reconcilePurchaseTrip(trip);

        // Only the cash item counts toward totalItemsCash / totalCashOut.
        expect(result.totalItemsCash, Money.parse('100'));
        expect(result.totalCashOut, Money.parse('100'));

        // The in-kind item is valued, but in a completely separate bucket.
        expect(result.inKindByFundSource, hasLength(1));
        expect(result.inKindByFundSource.first.fundSource, investorSource);
        expect(result.inKindByFundSource.first.value, Money.parse('1000'));

        // And it must not appear in byFundSource (the cash breakdown) at all.
        expect(
          result.byFundSource.any((f) => f.fundSource == investorSource),
          isFalse,
        );
      },
    );

    test('splits item cash correctly across multiple fund sources in one trip '
        '(no trip-level overhead in this case)', () {
      final investorA = FundSource.investor('inv-a');
      final investorB = FundSource.investor('inv-b');
      final trip = PurchaseTrip(
        id: 't3',
        date: DateTime.utc(2026, 8, 3),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          _item(qty: '1', unitPrice: '100'), // shop: 100
          _item(qty: '1', unitPrice: '200', fundSource: investorA), // A: 200
          _item(
            qty: '1',
            unitPrice: '50',
            fundSource: investorA,
          ), // A: +50 = 250
          _item(qty: '1', unitPrice: '300', fundSource: investorB), // B: 300
        ],
      );

      final result = reconcilePurchaseTrip(trip);

      expect(result.totalItemsCash, Money.parse('650'));
      final byFundSourceMap = {
        for (final f in result.byFundSource) f.fundSource: f.amount,
      };
      expect(byFundSourceMap[FundSource.shop()], Money.parse('100'));
      expect(byFundSourceMap[investorA], Money.parse('250'));
      expect(byFundSourceMap[investorB], Money.parse('300'));

      // The per-fund-source item totals must sum back to the trip total —
      // no leakage, same guarantee Money.allocate provides for percentage
      // splits.
      final sum = result.byFundSource.fold(
        Money.zero(),
        (s, f) => s + f.amount,
      );
      expect(sum, result.totalItemsCash);
    });

    test('trip-level overhead (transport + other costs − cash returned) is '
        'charged to the shop, not split across investors — the resolved '
        'decision replacing the old open question', () {
      final investorA = FundSource.investor('inv-a');
      final trip = PurchaseTrip(
        id: 't3b',
        date: DateTime.utc(2026, 8, 3),
        transportCost: Money.parse('80'),
        otherCosts: [
          OtherCost(description: 'loading', amount: Money.parse('20')),
        ],
        cashReturned: Money.parse('30'),
        items: [
          _item(qty: '1', unitPrice: '100'), // shop: 100
          _item(qty: '1', unitPrice: '400', fundSource: investorA), // A: 400
        ],
      );

      final result = reconcilePurchaseTrip(trip);

      // tripOverhead = 80 + 20 - 30 = 70, charged entirely to the shop.
      final byFundSourceMap = {
        for (final f in result.byFundSource) f.fundSource: f.amount,
      };
      expect(
        byFundSourceMap[FundSource.shop()],
        Money.parse('170'),
      ); // 100 + 70
      expect(byFundSourceMap[investorA], Money.parse('400')); // untouched

      // byFundSource must always sum to exactly totalCashOut once trip
      // overhead is included — this is the whole point of resolving the
      // attribution question rather than leaving overhead unattributed.
      final sum = result.byFundSource.fold(
        Money.zero(),
        (s, f) => s + f.amount,
      );
      expect(sum, result.totalCashOut);
      expect(
        result.totalCashOut,
        Money.parse('570'),
      ); // 500 items + 70 overhead
    });

    test(
      'a trip with only in-kind items has zero cash out but still reconciles at zero',
      () {
        final trip = PurchaseTrip(
          id: 't4',
          date: DateTime.utc(2026, 8, 3),
          transportCost: Money.zero(),
          cashReturned: Money.zero(),
          items: [
            _item(
              qty: '5',
              unitPrice: '20',
              isInKind: true,
              fundSource: FundSource.investor('inv-1'),
            ),
          ],
        );

        final result = reconcilePurchaseTrip(trip);

        expect(result.totalCashOut.isZero, isTrue);
        expect(result.reconciles(Money.zero()), isTrue);
        expect(result.inKindByFundSource.single.value, Money.parse('100'));
      },
    );

    test(
      'cashReturned larger than items+transport can make totalCashOut negative — '
      'the function does not clamp this, since a negative reconciliation is a real '
      'signal something was recorded wrong and should surface, not be hidden',
      () {
        final trip = PurchaseTrip(
          id: 't5',
          date: DateTime.utc(2026, 8, 3),
          transportCost: Money.zero(),
          cashReturned: Money.parse('1000'),
          items: [_item(qty: '1', unitPrice: '100')],
        );

        final result = reconcilePurchaseTrip(trip);
        expect(result.totalCashOut, Money.parse('-900'));
      },
    );
  });

  group('valueInKindContributions', () {
    test(
      'groups multiple in-kind items from the same investor into one valuation',
      () {
        final investor = FundSource.investor('inv-1');
        final trip = PurchaseTrip(
          id: 't6',
          date: DateTime.utc(2026, 8, 3),
          transportCost: Money.zero(),
          cashReturned: Money.zero(),
          items: [
            _item(
              qty: '2',
              unitPrice: '100',
              isInKind: true,
              fundSource: investor,
            ),
            _item(
              qty: '3',
              unitPrice: '50',
              isInKind: true,
              fundSource: investor,
            ),
          ],
        );

        final result = valueInKindContributions(trip);
        expect(result, hasLength(1));
        // 2*100 + 3*50 = 350
        expect(result.single.value, Money.parse('350'));
      },
    );

    test('returns an empty list when there are no in-kind items', () {
      final trip = PurchaseTrip(
        id: 't7',
        date: DateTime.utc(2026, 8, 3),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [_item(qty: '1', unitPrice: '10')],
      );
      expect(valueInKindContributions(trip), isEmpty);
    });
  });
}
