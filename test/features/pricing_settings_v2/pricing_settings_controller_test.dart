import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/core/settings/key_value_store.dart';
import 'package:inventory/core/settings/settings_registry.dart';
import 'package:inventory/core/time/clock.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/features/pricing_settings_v2/controller/pricing_settings_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SettingsRegistry registry;
  late FixedClock clock;
  late PricingSettingsController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = SettingsRegistry(InMemoryKeyValueStore());
    clock = FixedClock(DateTime.utc(2026, 8, 5));

    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 20,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = PricingSettingsController(db, registry, clock: clock);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('overheadMarkupPercent is null before any bootstrap event — the '
      'controller\'s own onInit only ever primes the "first seen" month, '
      'it never bootstraps immediately', () {
    expect(controller.isBootstrapped, isFalse);
    expect(controller.overheadMarkupPercent, isNull);
  });

  test(
    'setMonthlyShopRent/setMonthlyOwnerSalary are reflected immediately',
    () {
      controller.setMonthlyShopRent(Money.fromMinor(1000000));
      controller.setMonthlyOwnerSalary(Money.fromMinor(2000000));
      expect(
        controller.overheadSettings.monthlyShopRent,
        Money.fromMinor(1000000),
      );
      expect(
        controller.overheadSettings.monthlyOwnerSalary,
        Money.fromMinor(2000000),
      );
    },
  );

  test('averageMonthlyTripCost reflects real purchase-trip history', () async {
    await SavePurchaseTripUseCase(db).call(
      PurchaseTrip(
        id: 'trip-1',
        date: DateTime.utc(2026, 7, 10),
        transportCost: Money.fromMinor(50000),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Mokam',
            productId: 'book-a',
            qty: 1,
            unitPrice: Money.fromMinor(10000),
            fundSource: FundSource.shop(),
          ),
        ],
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.overheadSettings.averageMonthlyTripCost,
      Money.fromMinor(50000),
    );
  });

  test(
    'setManualEstimatedMonthlySalesRevenue bootstraps and makes a markup computable',
    () {
      controller.setMonthlyShopRent(Money.fromMinor(1000000));
      controller.setManualEstimatedMonthlySalesRevenue(
        Money.fromMinor(10000000),
      );

      expect(controller.isBootstrapped, isTrue);
      expect(controller.overheadMarkupPercent, closeTo(0.1, 0.0001));
    },
  );

  group('the month-end auto-refresh', () {
    test(
      'stays hidden while still inside the first tracked calendar month',
      () async {
        // controller.onInit() already primed "first seen" = August 2026
        // (clock's initial value) at setUp time. A sale recorded later in
        // that same month must not cause a premature bootstrap.
        await SaveSaleUseCase(db).call(
          productId: 'book-a',
          qty: 1,
          actualSellPrice: Money.fromMinor(15000),
          amountReceivedNow: Money.fromMinor(15000),
          paymentMethod: PaymentMethod.cash,
          date: DateTime.utc(2026, 8, 10),
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.isBootstrapped, isFalse);
      },
    );

    test(
      'bootstraps from the first tracked month\'s real sales once that month ends',
      () async {
        await SaveSaleUseCase(db).call(
          productId: 'book-a',
          qty: 2,
          actualSellPrice: Money.fromMinor(15000),
          amountReceivedNow: Money.fromMinor(30000),
          paymentMethod: PaymentMethod.cash,
          date: DateTime.utc(2026, 8, 10),
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.isBootstrapped, isFalse);

        // Cross into September — the next explicit check (a real screen
        // open, simulated here via checkForMonthlyRefresh()) now sees a
        // completed August behind it.
        clock.set(DateTime.utc(2026, 9, 3));
        controller.checkForMonthlyRefresh();

        expect(controller.isBootstrapped, isTrue);
        // 2 × ৳150 = ৳300.
        expect(
          controller.overheadSettings.estimatedMonthlySalesRevenue,
          Money.fromMinor(30000),
        );
      },
    );
  });
}
