import '../../core/money/money.dart';
import 'enums.dart';

/// A fixed asset, per `notes/business_logic.md`'s "দুইভাবে যোগ করার
/// ব্যবস্থা" (two ways to add one):
///
/// - [FixedAssetSource.shopCashPurchase] — bought outright with the
///   shop's cash (a showcase, a fan); [sourceProductId] is null.
/// - [FixedAssetSource.convertedFromStock] — a product pulled off the
///   sellable shelf and kept instead (an attar showpiece bottle used for
///   decoration); [sourceProductId] points at that [Product].
///
/// [value] is the asset's recorded worth regardless of source — for a
/// cash purchase, the price actually paid; for a stock conversion, the
/// converted quantity's cost-price value (see
/// `FixedAssetUseCases.createFromStock`'s own doc comment for why that's
/// computed, not asked for, on that path).
class FixedAsset {
  final String id;
  final String name;
  final Money value;
  final DateTime dateAcquired;
  final FixedAssetSource sourceType;
  final String? sourceProductId;

  const FixedAsset({
    required this.id,
    required this.name,
    required this.value,
    required this.dateAcquired,
    required this.sourceType,
    this.sourceProductId,
  });
}
