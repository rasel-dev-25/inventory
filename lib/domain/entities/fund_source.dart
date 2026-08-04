import 'enums.dart';

/// Who funded a purchase item, or who a product's stock value belongs to:
/// the shop's own cash, or a specific investor.
///
/// This is the direct fix for Data Integrity Rule #1 in
/// `notes/business_logic.md` §৪: "প্রতিটা PurchaseItem/Sale-এর একটা নির্দিষ্ট
/// fundSource থাকতেই হবে (nullable না)". The v1 schema had `Products.investor`
/// as a free-text, nullable-by-omission `TextColumn` defaulting to
/// `'Own Shop'`, matched against `Investor.name` by string — so a renamed
/// investor silently broke every historical attribution. Here, [FundSource]
/// is a required constructor argument everywhere it's used (see
/// [PurchaseItem], `Product`), and [investorId] is only present at all when
/// [type] is [FundSourceType.investor] — the invariant is enforced by the
/// constructor, not by a runtime check a call site can forget.
class FundSource {
  final FundSourceType type;

  /// The owning investor's id. Always non-null when [type] is
  /// [FundSourceType.investor], and always null when [type] is
  /// [FundSourceType.shop] — [FundSource.shop] and [FundSource.investor]
  /// are the only two ways to construct this class, so that invariant
  /// cannot be violated by a caller passing the wrong combination.
  final String? investorId;

  const FundSource._(this.type, this.investorId);

  factory FundSource.shop() => const FundSource._(FundSourceType.shop, null);

  factory FundSource.investor(String investorId) {
    if (investorId.isEmpty) {
      throw ArgumentError.value(
        investorId,
        'investorId',
        'An investor fund source requires a non-empty investor id',
      );
    }
    return FundSource._(FundSourceType.investor, investorId);
  }

  bool get isShop => type == FundSourceType.shop;
  bool get isInvestor => type == FundSourceType.investor;

  @override
  bool operator ==(Object other) =>
      other is FundSource &&
      other.type == type &&
      other.investorId == investorId;

  @override
  int get hashCode => Object.hash(type, investorId);

  @override
  String toString() =>
      isShop ? 'FundSource(shop)' : 'FundSource(investor: $investorId)';
}
