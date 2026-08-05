import 'package:inventory/core/money/money.dart';
import 'package:inventory/core/settings/key_value_store.dart';
import 'package:inventory/core/settings/settings_registry.dart';
import 'package:inventory/data/usecases/pricing_settings_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:test/test.dart';

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

PurchaseTrip _trip({required DateTime date, required int transportCostMinor}) {
  return PurchaseTrip(
    id: 'trip-${date.toIso8601String()}',
    date: date,
    transportCost: Money.fromMinor(transportCostMinor),
    cashReturned: Money.zero(),
    items: const [],
  );
}

void main() {
  late SettingsRegistry registry;
  late PricingSettingsUseCases useCases;

  setUp(() {
    registry = SettingsRegistry(InMemoryKeyValueStore());
    useCases = PricingSettingsUseCases(registry);
  });

  test('defaults to zero shop rent and owner salary', () {
    expect(useCases.monthlyShopRent, Money.zero());
    expect(useCases.monthlyOwnerSalary, Money.zero());
  });

  test('setMonthlyShopRent/setMonthlyOwnerSalary round-trip', () {
    useCases.setMonthlyShopRent(Money.fromMinor(1000000));
    useCases.setMonthlyOwnerSalary(Money.fromMinor(2000000));
    expect(useCases.monthlyShopRent, Money.fromMinor(1000000));
    expect(useCases.monthlyOwnerSalary, Money.fromMinor(2000000));
  });

  group('currentSettings', () {
    test('estimatedMonthlySalesRevenue is null before any bootstrap event', () {
      final settings = useCases.currentSettings(
        purchaseTrips: const [],
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(settings.estimatedMonthlySalesRevenue, isNull);
    });

    test('averages real trip history when trip cost is not manual', () {
      final trips = [
        _trip(date: DateTime.utc(2026, 7, 10), transportCostMinor: 30000),
      ];
      final settings = useCases.currentSettings(
        purchaseTrips: trips,
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(settings.averageMonthlyTripCost, Money.fromMinor(30000));
    });

    test('uses the manual trip cost override when one is set', () {
      useCases.setManualAverageMonthlyTripCost(Money.fromMinor(99999));
      final settings = useCases.currentSettings(
        purchaseTrips: [
          _trip(date: DateTime.utc(2026, 7, 10), transportCostMinor: 30000),
        ],
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(settings.averageMonthlyTripCost, Money.fromMinor(99999));
      expect(useCases.isTripCostManual, isTrue);
    });

    test(
      'reverting the manual trip cost override falls back to the average',
      () {
        useCases.setManualAverageMonthlyTripCost(Money.fromMinor(99999));
        useCases.setManualAverageMonthlyTripCost(null);
        expect(useCases.isTripCostManual, isFalse);
        final settings = useCases.currentSettings(
          purchaseTrips: [
            _trip(date: DateTime.utc(2026, 7, 10), transportCostMinor: 30000),
          ],
          asOf: DateTime.utc(2026, 8, 5),
        );
        expect(settings.averageMonthlyTripCost, Money.fromMinor(30000));
      },
    );
  });

  group('setManualEstimatedMonthlySalesRevenue', () {
    test('immediately bootstraps the engine', () {
      expect(useCases.isBootstrapped, isFalse);
      useCases.setManualEstimatedMonthlySalesRevenue(Money.fromMinor(5000000));
      expect(useCases.isBootstrapped, isTrue);
      expect(useCases.isSalesRevenueManual, isTrue);

      final settings = useCases.currentSettings(
        purchaseTrips: const [],
        asOf: DateTime.utc(2026, 8, 5),
      );
      expect(settings.estimatedMonthlySalesRevenue, Money.fromMinor(5000000));
    });
  });

  group('refreshEstimatedMonthlySalesRevenueIfMonthEnded', () {
    test(
      'the very first call primes the "first seen" month and refreshes nothing',
      () {
        final refreshed = useCases
            .refreshEstimatedMonthlySalesRevenueIfMonthEnded(
              sales: [
                _sale(date: DateTime.utc(2026, 7, 3), qty: 100, price: 999999),
              ],
              now: DateTime.utc(2026, 8, 5),
            );

        expect(
          refreshed,
          isFalse,
          reason:
              'a shop\'s very first tracked month must never be summarized '
              'from whatever month happened to precede it — see '
              '_firstSeenMonth\'s doc comment',
        );
        expect(useCases.isBootstrapped, isFalse);
      },
    );

    test('stays hidden for the rest of that first tracked calendar month', () {
      useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
        sales: const [],
        now: DateTime.utc(2026, 8, 1),
      );

      final stillWithinAugust = useCases
          .refreshEstimatedMonthlySalesRevenueIfMonthEnded(
            sales: [
              _sale(date: DateTime.utc(2026, 8, 3), qty: 5, price: 10000),
            ],
            now: DateTime.utc(2026, 8, 28),
          );

      expect(stillWithinAugust, isFalse);
      expect(useCases.isBootstrapped, isFalse);
    });

    test(
      'bootstraps once the first tracked month\'s boundary is crossed, from that month\'s real sales',
      () {
        useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
          sales: const [],
          now: DateTime.utc(2026, 8, 1),
        );

        final sales = [
          _sale(date: DateTime.utc(2026, 8, 3), qty: 2, price: 15000),
          _sale(date: DateTime.utc(2026, 8, 20), qty: 1, price: 20000),
          _sale(
            date: DateTime.utc(2026, 7, 1),
            qty: 100,
            price: 100000,
          ), // excluded
        ];

        final refreshed = useCases
            .refreshEstimatedMonthlySalesRevenueIfMonthEnded(
              sales: sales,
              now: DateTime.utc(2026, 9, 5),
            );

        expect(refreshed, isTrue);
        expect(useCases.isBootstrapped, isTrue);
        expect(useCases.isSalesRevenueManual, isFalse);
        final settings = useCases.currentSettings(
          purchaseTrips: const [],
          asOf: DateTime.utc(2026, 9, 5),
        );
        // (2 × ৳150) + (1 × ৳200) = ৳500.
        expect(settings.estimatedMonthlySalesRevenue, Money.fromMinor(50000));
      },
    );

    test('is a no-op the second time it is called for the same month', () {
      useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
        sales: const [],
        now: DateTime.utc(2026, 8, 1),
      );
      useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
        sales: [_sale(date: DateTime.utc(2026, 8, 3), qty: 1, price: 10000)],
        now: DateTime.utc(2026, 9, 5),
      );

      // Even with wildly different sales passed in, a second call within
      // the same "as of" month must not re-sum — it already ran for August.
      final refreshedAgain = useCases
          .refreshEstimatedMonthlySalesRevenueIfMonthEnded(
            sales: [
              _sale(date: DateTime.utc(2026, 8, 3), qty: 50, price: 500000),
            ],
            now: DateTime.utc(2026, 9, 20),
          );

      expect(refreshedAgain, isFalse);
      final settings = useCases.currentSettings(
        purchaseTrips: const [],
        asOf: DateTime.utc(2026, 9, 20),
      );
      expect(settings.estimatedMonthlySalesRevenue, Money.fromMinor(10000));
    });

    test('runs again once a new month boundary is reached', () {
      useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
        sales: const [],
        now: DateTime.utc(2026, 8, 1),
      );
      useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
        sales: [_sale(date: DateTime.utc(2026, 8, 3), qty: 1, price: 10000)],
        now: DateTime.utc(2026, 9, 5),
      );

      final refreshedInOctober = useCases
          .refreshEstimatedMonthlySalesRevenueIfMonthEnded(
            sales: [
              _sale(date: DateTime.utc(2026, 8, 3), qty: 1, price: 10000),
              _sale(date: DateTime.utc(2026, 9, 10), qty: 1, price: 40000),
            ],
            now: DateTime.utc(2026, 10, 2),
          );

      expect(refreshedInOctober, isTrue);
      final settings = useCases.currentSettings(
        purchaseTrips: const [],
        asOf: DateTime.utc(2026, 10, 2),
      );
      expect(settings.estimatedMonthlySalesRevenue, Money.fromMinor(40000));
    });

    test(
      'overwrites an earlier manual override at the next month boundary',
      () {
        useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
          sales: const [],
          now: DateTime.utc(2026, 8, 1),
        );
        useCases.setManualEstimatedMonthlySalesRevenue(Money.fromMinor(999999));
        expect(useCases.isSalesRevenueManual, isTrue);

        useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
          sales: [_sale(date: DateTime.utc(2026, 8, 3), qty: 1, price: 10000)],
          now: DateTime.utc(2026, 9, 5),
        );

        expect(useCases.isSalesRevenueManual, isFalse);
        final settings = useCases.currentSettings(
          purchaseTrips: const [],
          asOf: DateTime.utc(2026, 9, 5),
        );
        expect(settings.estimatedMonthlySalesRevenue, Money.fromMinor(10000));
      },
    );
  });
}
