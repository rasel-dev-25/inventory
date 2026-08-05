import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../core/settings/settings_registry.dart';
import '../../../core/time/clock.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/pricing_settings_usecases.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/pricing_engine.dart';

/// Backs the v2 Pricing Settings screen, and is also where
/// `notes/business_logic.md`'s pricing engine actually lives for the rest
/// of the app to read — `CatalogController` looks this controller up (via
/// DI, injected at the binding site in `app_pages.dart`, same as it looks
/// up `AppDatabase`) to get a live [overheadMarkupPercent] for
/// `ProductFormSheet`'s cost-price suggestion, so registered permanently
/// in `main.dart` rather than lazily per-route — a product form can open
/// before the owner has ever visited the Settings screen.
///
/// [PricingSettingsUseCases]/`pricing_engine.dart` do the actual
/// computation; this controller's only job is turning their plain
/// getters into something `Obx()` can rebuild from. `SettingsRegistry`
/// itself has no `Rx` state (its `watch()` stream exists, but bridging
/// every possible key into GetX reactivity is more machinery than this
/// needs) — [_settingsVersion] is a deliberately simple version counter
/// bumped after every write, which every settings-derived getter below
/// reads from to register as an `Obx` dependency.
class PricingSettingsController extends GetxController {
  final AppDatabase db;
  final SettingsRegistry settingsRegistry;

  /// Defaults to the real system clock — pass a `FixedClock` in tests
  /// that need to simulate a month boundary passing (see `Clock`'s own
  /// doc comment for why business code depends on this instead of
  /// calling `DateTime.now()` directly).
  final Clock clock;

  PricingSettingsController(
    this.db,
    this.settingsRegistry, {
    this.clock = const SystemClock(),
  });

  late final PricingSettingsUseCases _useCases = PricingSettingsUseCases(
    settingsRegistry,
  );

  final purchaseTrips = <PurchaseTrip>[].obs;
  final sales = <Sale>[].obs;
  final errorMessage = RxnString();
  final _settingsVersion = 0.obs;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.purchaseDao
          .watchAll(defaultShopId)
          .listen((rows) => purchaseTrips.assignAll(rows)),
    );
    _subscriptions.add(
      db.saleDao.watchAll(defaultShopId).listen((rows) {
        sales.assignAll(rows);
        _refreshIfMonthEnded();
      }),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  /// Forces an immediate month-boundary check without waiting for the
  /// next sales-watch emission — the sales watch's own first emission (at
  /// `onInit`) already covers "the app just opened", so this exists for
  /// whatever *additional* trigger point a future screen wants (e.g. the
  /// Pricing Settings screen re-checking every time it's opened) and for
  /// deterministic tests using a `FixedClock`.
  void checkForMonthlyRefresh() => _refreshIfMonthEnded();

  void _refreshIfMonthEnded() {
    final refreshed = _useCases.refreshEstimatedMonthlySalesRevenueIfMonthEnded(
      sales: sales,
      now: clock.now(),
    );
    if (refreshed) _settingsVersion.value++;
  }

  /// Today's live [OverheadSettings] snapshot.
  OverheadSettings get overheadSettings {
    // ignore: unnecessary_statements
    _settingsVersion.value;
    return _useCases.currentSettings(
      purchaseTrips: purchaseTrips,
      asOf: clock.now(),
    );
  }

  /// Null exactly when `ProductFormSheet`'s suggestion should stay
  /// hidden — see `computeOverheadMarkupPercent`'s own doc comment.
  double? get overheadMarkupPercent =>
      computeOverheadMarkupPercent(overheadSettings);

  bool get isBootstrapped {
    // ignore: unnecessary_statements
    _settingsVersion.value;
    return _useCases.isBootstrapped;
  }

  bool get isTripCostManual {
    // ignore: unnecessary_statements
    _settingsVersion.value;
    return _useCases.isTripCostManual;
  }

  bool get isSalesRevenueManual {
    // ignore: unnecessary_statements
    _settingsVersion.value;
    return _useCases.isSalesRevenueManual;
  }

  void setMonthlyShopRent(Money value) {
    _useCases.setMonthlyShopRent(value);
    _settingsVersion.value++;
  }

  void setMonthlyOwnerSalary(Money value) {
    _useCases.setMonthlyOwnerSalary(value);
    _settingsVersion.value++;
  }

  /// Passing null reverts to the auto-computed average.
  void setManualAverageMonthlyTripCost(Money? value) {
    _useCases.setManualAverageMonthlyTripCost(value);
    _settingsVersion.value++;
  }

  void setManualEstimatedMonthlySalesRevenue(Money value) {
    _useCases.setManualEstimatedMonthlySalesRevenue(value);
    _settingsVersion.value++;
  }
}
