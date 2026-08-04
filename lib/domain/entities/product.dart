import '../../core/money/money.dart';
import 'fund_source.dart';

/// A stock item, per `notes/business_logic.md` §Product.
///
/// Deliberately holds only business-meaningful fields — no `updatedAt`,
/// `deletedAt`, or sync cursor. Those are storage/sync bookkeeping, not
/// part of what a "product" *means* to the business, and live on the data
/// layer's row mapping instead (see `lib/data/local`). Keeping persistence
/// metadata out of domain entities is what keeps `domain/services/*`
/// testable with plain object literals instead of a fake row shape.
class Product {
  final String id;
  final String name;
  final String category;
  final Money costPrice;
  final Money suggestedSellPrice;

  /// Current on-hand quantity. Intentionally `double`, not [Money] — this
  /// is a physical count/weight (which can be fractional for weight-sold
  /// goods), never a currency amount, so it is not subject to the
  /// paisa-precision rule [Money] exists to enforce.
  final double qty;

  /// Required, never nullable — Data Integrity Rule #1 in
  /// business_logic.md §৪. See [FundSource] for why this is enforced by
  /// the type system rather than a runtime null-check.
  final FundSource fundSource;

  /// Only meaningful for the Book category per the spec, but left as a
  /// general flag rather than a category-name string comparison — a
  /// future non-book rentable item does not need special-casing here.
  final bool isRentable;

  final String? barcode;
  final String? sku;

  /// Only meaningful when [isRentable] is true — see this field's own
  /// column doc comment in `lib/data/local/tables/products.dart` for why
  /// it's a plain nullable field rather than restricted to a "Book"
  /// category check.
  final int? pageCount;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.suggestedSellPrice,
    required this.qty,
    required this.fundSource,
    this.isRentable = false,
    this.barcode,
    this.sku,
    this.pageCount,
  });

  Product copyWith({
    String? name,
    String? category,
    Money? costPrice,
    Money? suggestedSellPrice,
    double? qty,
    FundSource? fundSource,
    bool? isRentable,
    String? barcode,
    String? sku,
    int? pageCount,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      suggestedSellPrice: suggestedSellPrice ?? this.suggestedSellPrice,
      qty: qty ?? this.qty,
      fundSource: fundSource ?? this.fundSource,
      isRentable: isRentable ?? this.isRentable,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
