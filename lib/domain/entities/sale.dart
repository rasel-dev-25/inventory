import '../../core/money/money.dart';
import 'enums.dart';
import 'fund_source.dart';

/// A single sale line, per `notes/business_logic.md` §Sale.
///
/// [actualSellPrice] and [costPriceAtSale] are both captured *per unit, at
/// the time of sale* rather than looked up live from the current
/// [Product] — a later cost-price edit on the product must never rewrite
/// the profit on a sale that already happened. This is what makes
/// `calculateGrossProfitPerSale` a pure function of the [Sale] alone.
class Sale {
  final String id;
  final String productId;
  final double qty;

  /// The price actually charged per unit — spec explicitly allows this to
  /// differ from `Product.suggestedSellPrice` ("বিক্রির সময় কমবেশি করা
  /// যায়").
  final Money actualSellPrice;

  /// The product's cost price per unit *as of this sale*, copied at sale
  /// time — see the class doc above for why this must not be a live
  /// lookup.
  final Money costPriceAtSale;

  final DateTime date;
  final String? customerId;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;

  /// Inherited from the product at sale time — whose stock this sale drew
  /// down, for investor attribution. Same "copy, don't look up live"
  /// reasoning as [costPriceAtSale].
  final FundSource fundSource;

  const Sale({
    required this.id,
    required this.productId,
    required this.qty,
    required this.actualSellPrice,
    required this.costPriceAtSale,
    required this.date,
    this.customerId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.fundSource,
  });
}
