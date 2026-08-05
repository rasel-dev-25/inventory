import '../entities/product.dart';

/// Barcode scanning is a fast path *into* product search, per the working
/// plan's own framing — never required (most of this shop's actual stock,
/// attar/dates/topi/miswak/local books, has no manufacturer barcode at
/// all), purely additive for the products that do. This is the one real
/// piece of logic that fast path needs: matching a scanned code back to a
/// [Product] — everything else (the camera view, the permission prompt)
/// is UI/platform plumbing, not business logic, and lives in
/// `lib/core/widgets/barcode_scanner_view.dart` instead.
///
/// Pure — [products] must already be whatever list the caller has on
/// hand (every v2 screen that could use this already watches the full
/// product list for its own autosuggest), matching every other
/// pure-input calculator in this directory. A blank [barcode] never
/// matches anything, even if some [Product.barcode] were ever
/// (incorrectly) stored as an empty string — scanning nothing should
/// never accidentally select a product that also has nothing recorded.
Product? findProductByBarcode(List<Product> products, String barcode) {
  final trimmed = barcode.trim();
  if (trimmed.isEmpty) return null;
  for (final product in products) {
    if (product.barcode == trimmed) return product;
  }
  return null;
}
