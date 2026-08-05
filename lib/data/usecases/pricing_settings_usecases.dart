import '../../core/money/money.dart';
import '../../core/settings/feature_flags.dart';
import '../../core/settings/settings_registry.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/sale.dart';
import '../../domain/services/pricing_engine.dart';

/// Resolves a live [OverheadSettings] snapshot from [SettingsRegistry] plus
/// real purchase-trip/sale history, and owns every read/write of the
/// pricing-engine's stored configuration — the data-layer half of
/// `pricing_engine.dart`'s pure calculations (same split as
/// `InvestorController`/`investor_metrics.dart`).
///
/// **Deliberately local-only, does not sync.** `SettingsRegistry` is
/// backed by the `AppSettings` table, which `apply_jsonb_upsert`'s
/// allowlist explicitly excludes (composite `(shop_id, key)` primary key,
/// needs its own RPC — see `AppSettingsDao`'s doc comment). A second
/// device on the same shop does not see these settings until that RPC is
/// built; flagged here rather than silently assumed away.
class PricingSettingsUseCases {
  final SettingsRegistry settings;

  PricingSettingsUseCases(this.settings);

  static final _monthlyShopRent = SettingKey.money(
    'pricing.monthlyShopRent',
    defaultValue: Money.zero(),
  );
  static final _monthlyOwnerSalary = SettingKey.money(
    'pricing.monthlyOwnerSalary',
    defaultValue: Money.zero(),
  );
  static final _tripCostIsManual = SettingKey.boolean(
    'pricing.averageMonthlyTripCost.isManual',
    defaultValue: false,
  );
  static final _manualTripCost = SettingKey.money(
    'pricing.averageMonthlyTripCost.manualValue',
    defaultValue: Money.zero(),
  );
  static final _estimatedMonthlySalesRevenue = SettingKey.money(
    'pricing.estimatedMonthlySalesRevenue',
    defaultValue: Money.zero(),
  );
  static final _salesRevenueIsManual = SettingKey.boolean(
    'pricing.estimatedMonthlySalesRevenue.isManual',
    defaultValue: false,
  );

  /// The `"YYYY-MM"` key of the last calendar month
  /// [refreshEstimatedMonthlySalesRevenueIfMonthEnded] actually summed real
  /// sales for — empty string means "never". Kept distinct from the
  /// bootstrap flag (`FeatureFlags.pricingEngineBootstrapped`) because a
  /// manual override can set that flag without ever running an
  /// auto-refresh, and this key must only ever reflect a real auto-refresh
  /// having happened for that specific month.
  static final _lastAutoRefreshedMonth = SettingKey.string(
    'pricing.estimatedMonthlySalesRevenue.lastAutoRefreshedMonth',
    defaultValue: '',
  );

  /// The `"YYYY-MM"` key of the calendar month this engine first ever
  /// observed this shop — i.e. the spec's "প্রথম মাস" (first month),
  /// deliberately hidden. Set once, the very first time
  /// [refreshEstimatedMonthlySalesRevenueIfMonthEnded] is called at all,
  /// and never touched again. Without this, the very first call — which
  /// could happen on day one of using the app, or on day thirty — would
  /// treat *whatever* calendar month happens to precede "now" as a real
  /// completed operating month and immediately auto-refresh from it, even
  /// though the shop was never tracked by this app during that month at
  /// all (its real total would trivially be zero, and worse, would
  /// immediately flip [FeatureFlags.pricingEngineBootstrapped] to true —
  /// exactly the premature unhide the spec's bootstrap period exists to
  /// prevent). This key anchors "first month" to when tracking actually
  /// started, not to the calendar.
  static final _firstSeenMonth = SettingKey.string(
    'pricing.firstSeenMonth',
    defaultValue: '',
  );

  Money get monthlyShopRent => settings.get(_monthlyShopRent);
  Money get monthlyOwnerSalary => settings.get(_monthlyOwnerSalary);
  bool get isTripCostManual => settings.get(_tripCostIsManual);
  bool get isSalesRevenueManual => settings.get(_salesRevenueIsManual);

  /// Whether the spec's bootstrap period is over — the pricing suggestion
  /// stays hidden everywhere ([currentSettings]'s
  /// `estimatedMonthlySalesRevenue` comes back null) until this is true.
  bool get isBootstrapped =>
      settings.get(FeatureFlags.pricingEngineBootstrapped);

  void setMonthlyShopRent(Money value) => settings.set(_monthlyShopRent, value);

  void setMonthlyOwnerSalary(Money value) =>
      settings.set(_monthlyOwnerSalary, value);

  /// Passing null reverts to the auto-computed average
  /// ([computeAverageMonthlyTripCost] over real [PurchaseTrip] history) —
  /// matches the spec's "গত কয়েক মাসের গড়, অথবা ম্যানুয়াল" (average of the
  /// last few months, or manual).
  void setManualAverageMonthlyTripCost(Money? value) {
    if (value == null) {
      settings.set(_tripCostIsManual, false);
      return;
    }
    settings.set(_tripCostIsManual, true);
    settings.set(_manualTripCost, value);
  }

  /// A manual estimate immediately unhides the suggestion (same as a real
  /// auto-refresh would) — the spec's "ম্যানুয়াল ওভাররাইড সবসময় সম্ভব"
  /// (manual override is always possible) doesn't gate on the bootstrap
  /// period at all, it's an escape hatch available from day one.
  ///
  /// **Does not prevent the next month-end auto-refresh from overwriting
  /// this** — see [refreshEstimatedMonthlySalesRevenueIfMonthEnded]'s doc
  /// comment for why that's the reading this engine takes of "auto-refresh
  /// every month end, manual override always possible" rather than a
  /// manual value permanently pinning the setting.
  void setManualEstimatedMonthlySalesRevenue(Money value) {
    settings.set(_salesRevenueIsManual, true);
    settings.set(_estimatedMonthlySalesRevenue, value);
    settings.set(FeatureFlags.pricingEngineBootstrapped, true);
  }

  /// Builds today's [OverheadSettings] — [purchaseTrips] must be every
  /// non-deleted trip for this shop (a caller like `PricingSettingsController`
  /// already watches this for the trip-cost average; this function does
  /// no I/O of its own, matching every other pure-input domain service).
  OverheadSettings currentSettings({
    required List<PurchaseTrip> purchaseTrips,
    required DateTime asOf,
  }) {
    final tripCost = isTripCostManual
        ? settings.get(_manualTripCost)
        : computeAverageMonthlyTripCost(trips: purchaseTrips, asOf: asOf);

    return OverheadSettings(
      monthlyShopRent: monthlyShopRent,
      monthlyOwnerSalary: monthlyOwnerSalary,
      averageMonthlyTripCost: tripCost,
      estimatedMonthlySalesRevenue: isBootstrapped
          ? settings.get(_estimatedMonthlySalesRevenue)
          : null,
    );
  }

  /// Call this wherever is convenient — once per app foreground, once per
  /// Settings-screen or product-form open — there is no true midnight-cron
  /// scheduler in this app, so "month end" here honestly means "the next
  /// time this runs after the calendar month has turned over", not a
  /// literally-scheduled job. Safe to call as often as you like: it's a
  /// no-op once this month boundary has already been handled.
  ///
  /// **This unconditionally overwrites whatever is currently stored**,
  /// including a manual override set via
  /// [setManualEstimatedMonthlySalesRevenue] earlier in the same month —
  /// matches this engine's reading of the spec's "প্রতি মাস শেষে
  /// অটো-রিফ্রেশ হবে ... ম্যানুয়াল ওভাররাইড সবসময় সম্ভব": auto-refresh is
  /// the unconditional scheduled behavior, manual override is a transient
  /// escape hatch available between refreshes, not a permanent pin.
  ///
  /// Returns true if it actually refreshed something (useful for a
  /// "your suggested prices just updated" toast, though no caller shows
  /// one yet).
  bool refreshEstimatedMonthlySalesRevenueIfMonthEnded({
    required List<Sale> sales,
    required DateTime now,
  }) {
    final currentMonthKey = monthKey(DateTime.utc(now.year, now.month, 1));
    final firstSeenMonth = settings.get(_firstSeenMonth);
    if (firstSeenMonth.isEmpty) {
      // The very first time this shop has ever been checked — see
      // [_firstSeenMonth]'s doc comment for why this primes the anchor
      // and returns without refreshing anything, rather than summarizing
      // whatever month happens to precede "now".
      settings.set(_firstSeenMonth, currentMonthKey);
      return false;
    }

    final previousMonthStart = DateTime.utc(now.year, now.month - 1, 1);
    final previousMonthKey = monthKey(previousMonthStart);
    if (previousMonthKey.compareTo(firstSeenMonth) < 0) {
      // Still inside the first tracked calendar month — nothing real to
      // summarize yet (the spec's bootstrap period).
      return false;
    }
    if (settings.get(_lastAutoRefreshedMonth) == previousMonthKey) {
      return false;
    }

    final revenue = computeActualSalesRevenueForPreviousMonth(
      sales: sales,
      asOf: now,
    );
    settings.set(_estimatedMonthlySalesRevenue, revenue);
    settings.set(_salesRevenueIsManual, false);
    settings.set(_lastAutoRefreshedMonth, previousMonthKey);
    settings.set(FeatureFlags.pricingEngineBootstrapped, true);
    return true;
  }
}
