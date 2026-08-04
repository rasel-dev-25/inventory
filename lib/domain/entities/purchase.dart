import '../../core/money/money.dart';
import 'fund_source.dart';

/// One line item within a [PurchaseTrip], per `notes/business_logic.md`
/// §PurchaseItem.
///
/// [fundSource] is required (Data Integrity Rule #1) and independent per
/// item — the same trip can have some items paid from the shop's own cash
/// and others from a specific investor's money in the same visit to the
/// market. [isInKind] is the other half of Rule #2: when true, this item
/// must never contribute to a cash total anywhere — it only adds stock,
/// valued at [unitPrice] and tagged to [fundSource], with zero cash
/// movement. See `reconcilePurchaseTrip` for where that separation is
/// enforced.
class PurchaseItem {
  final String id;
  final String shopName;
  final String productId;
  final double qty;
  final Money unitPrice;
  final FundSource fundSource;
  final bool isInKind;

  const PurchaseItem({
    required this.id,
    required this.shopName,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.fundSource,
    this.isInKind = false,
  });

  /// The line total (qty × unitPrice), regardless of whether it's cash or
  /// in-kind — callers deciding whether this counts as a cash expense must
  /// check [isInKind] themselves; this getter intentionally does not bake
  /// that decision in, since it's needed both ways (cash reconciliation
  /// excludes it, stock valuation includes it).
  Money get lineTotal => unitPrice * qty;
}

/// A free-form cost incurred on a purchase trip that isn't tied to a
/// specific item — e.g. a shop-keeper's tip, a loading fee. Distinct from
/// transport cost because the spec lists them separately
/// (`otherCosts[]` vs `transportCost`).
class OtherCost {
  final String description;
  final Money amount;

  const OtherCost({required this.description, required this.amount});
}

/// A single market/mokam trip, per `notes/business_logic.md` §Purchase.
/// One trip can contain items from multiple shops, funded from multiple
/// sources — see [PurchaseItem.fundSource].
class PurchaseTrip {
  final String id;
  final DateTime date;
  final Money transportCost;
  final List<OtherCost> otherCosts;

  /// Change/refund actually brought back from the trip — subtracted in the
  /// reconciliation formula.
  final Money cashReturned;

  final List<PurchaseItem> items;

  const PurchaseTrip({
    required this.id,
    required this.date,
    required this.transportCost,
    this.otherCosts = const [],
    required this.cashReturned,
    required this.items,
  });

  Money get otherCostsTotal => otherCosts.fold(
    Money.zero(currency: transportCost.currency),
    (sum, c) => sum + c.amount,
  );
}
