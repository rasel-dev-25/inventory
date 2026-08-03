import '../platform/capabilities.dart';
import 'settings_registry.dart';

/// A capability or module the app can turn on/off. Kept as one flat enum
/// rather than a free-text flag table (an external review's suggestion,
/// generalised) so every flag in the app is discoverable in one place and
/// the compiler catches a typo'd flag name — a `switch` over this enum is
/// exhaustiveness-checked.
enum FeatureFlag {
  /// Camera capture for product/receipt photos and QuickCapture photo
  /// notes. Gated by [PlatformCapabilities.hasCamera] — false on Windows
  /// and Web, where the UI falls back to a file picker instead of hiding
  /// the action entirely.
  camera,

  /// Voice recording for QuickCapture. Android-only for now — see
  /// ARCHITECTURE.md for why Windows/Web do not get a voice-note fallback
  /// (there is no equivalent "native OS voice recorder" integration point
  /// on those platforms, unlike the spec's Android-first design intent).
  microphone,

  /// The rent/rental module (§জ of business_logic.md). Off during initial
  /// bring-up in M1 since it lands in M3; the flag exists from day one so
  /// turning it on later is a config change, not a code change, and so a
  /// future second shop that doesn't rent books can turn it off.
  rentalModule,

  /// The investor/fund-source module. Identity + attribution ships in M1
  /// (purchases need it from day one per Data Integrity Rule #1); payouts,
  /// legacy settlement and reminders land in M2 behind the same flag.
  investorModule,

  /// Customer pre-orders (§ Order entity).
  ordersModule,

  /// Fixed assets, including the convert-from-stock path.
  assetsModule,

  /// The overhead-markup pricing suggestion engine. The spec requires this
  /// to be hidden for the shop's first month of operation (no
  /// `estimatedMonthlySalesRevenue` yet to bootstrap from) and to
  /// auto-enable after the first month closes — see
  /// [FeatureFlags.isPricingEngineBootstrapped].
  pricingRecommendationEngine,

  /// Barcode scanning as a fast path into product search/entry. Never
  /// required — most stock (attar, dates, topi, miswak, local books) has
  /// no manufacturer barcode, so this is additive only.
  barcodeScanning,
}

/// Resolves whether a [FeatureFlag] is currently enabled, combining three
/// independent sources so call sites never need to know which one applies:
/// hard platform capability (camera/mic), an owner-configurable module
/// toggle (rental/investor/orders/assets/barcode), and a spec-driven
/// automatic condition (the pricing engine's first-month bootstrap hide).
class FeatureFlags {
  final PlatformCapabilities capabilities;
  final SettingsRegistry settings;

  FeatureFlags({required this.capabilities, required this.settings});

  static final _moduleToggleKeys = <FeatureFlag, SettingKey<bool>>{
    FeatureFlag.rentalModule: SettingKey.boolean(
      'feature.rentalModule',
      defaultValue: true,
    ),
    FeatureFlag.investorModule: SettingKey.boolean(
      'feature.investorModule',
      defaultValue: true,
    ),
    FeatureFlag.ordersModule: SettingKey.boolean(
      'feature.ordersModule',
      defaultValue: true,
    ),
    FeatureFlag.assetsModule: SettingKey.boolean(
      'feature.assetsModule',
      defaultValue: true,
    ),
    FeatureFlag.barcodeScanning: SettingKey.boolean(
      'feature.barcodeScanning',
      defaultValue: true,
    ),
  };

  /// Set once, automatically, the first time a monthly close computes a
  /// real `estimatedMonthlySalesRevenue` (see the pricing engine service in
  /// M2). Exposed here so [FeatureFlag.pricingRecommendationEngine]
  /// resolves correctly without the pricing module needing its own
  /// separate flag-reading logic.
  static final pricingEngineBootstrapped = SettingKey.boolean(
    'pricingEngine.bootstrapped',
    defaultValue: false,
  );

  bool isEnabled(FeatureFlag flag) {
    switch (flag) {
      case FeatureFlag.camera:
        return capabilities.hasCamera;
      case FeatureFlag.microphone:
        return capabilities.hasMicrophone;
      case FeatureFlag.pricingRecommendationEngine:
        return settings.get(pricingEngineBootstrapped);
      case FeatureFlag.rentalModule:
      case FeatureFlag.investorModule:
      case FeatureFlag.ordersModule:
      case FeatureFlag.assetsModule:
      case FeatureFlag.barcodeScanning:
        final key = _moduleToggleKeys[flag]!;
        return settings.get(key);
    }
  }

  /// Owner-facing toggle for module flags. Throws [ArgumentError] for flags
  /// that are not owner-configurable (camera/microphone are hard platform
  /// facts; the pricing bootstrap flag is system-set only) — calling this
  /// with the wrong flag is a programming error, not a runtime condition to
  /// handle gracefully.
  void setModuleEnabled(FeatureFlag flag, bool enabled) {
    final key = _moduleToggleKeys[flag];
    if (key == null) {
      throw ArgumentError.value(
        flag,
        'flag',
        'Not an owner-configurable module flag',
      );
    }
    settings.set(key, enabled);
  }
}
