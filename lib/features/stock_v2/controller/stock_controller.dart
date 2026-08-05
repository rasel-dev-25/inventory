import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';

/// Sentinel used for [StockController.selectedFundFilter] to mean
/// "shop-funded only" — distinct from `null`, which means "no fund
/// filter, show everything", since a real investor id could otherwise
/// collide with any other sentinel string.
const shopFundFilterValue = '__shop__';

/// Backs the v2 Stock screen — `notes/business_logic.md` §খ: category and
/// investor filters (both derived from [Product.fundSource]/
/// [Product.category], never stored redundantly), per-category cost/
/// sale-value/profit totals, and the "top sellers vs. slow movers" view
/// computed from [StockMovements] rows tagged `sourceType == 'sale'`
/// (never re-derived from `Sales` directly — the movements table is
/// already the single source of truth for quantity changes, see
/// `LedgerDao`'s own doc comment).
class StockController extends GetxController {
  final AppDatabase db;

  StockController(this.db);

  final products = <Product>[].obs;
  final categories = <CategoryRow>[].obs;
  final investors = <Investor>[].obs;
  final saleMovements = <StockMovementRow>[].obs;

  /// `null` = all categories.
  final selectedCategory = RxnString();

  /// `null` = all fund sources, [shopFundFilterValue] = shop-funded only,
  /// anything else = that investor's id.
  final selectedFundFilter = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.categoryDao
          .watchAll(defaultShopId)
          .listen((rows) => categories.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
    _subscriptions.add(
      db.ledgerDao
          .watchSaleMovements(defaultShopId)
          .listen((rows) => saleMovements.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  List<Product> get filteredProducts {
    return products.where((p) {
      if (selectedCategory.value != null &&
          p.category != selectedCategory.value) {
        return false;
      }
      final filter = selectedFundFilter.value;
      if (filter == null) return true;
      if (filter == shopFundFilterValue) return p.fundSource.isShop;
      return p.fundSource.investorId == filter;
    }).toList();
  }

  /// `Σ(qty × costPrice)` over [filteredProducts] — "মোট cost value".
  Money get totalCostValue => filteredProducts.fold(
    Money.zero(),
    (sum, p) => sum + p.costPrice * p.qty,
  );

  /// `Σ(qty × suggestedSellPrice)` — "সম্ভাব্য sale value".
  Money get potentialSaleValue => filteredProducts.fold(
    Money.zero(),
    (sum, p) => sum + p.suggestedSellPrice * p.qty,
  );

  /// "সম্ভাব্য profit" — the spread between the two totals above, not a
  /// per-sale realized profit (that's `ProfitCalculator`'s job once a sale
  /// actually happens at whatever price the seller negotiates).
  Money get potentialProfit => potentialSaleValue - totalCostValue;

  /// Total quantity sold per product, all time — [StockMovements.deltaQty]
  /// is negative for a sale, so this negates it back to a positive "units
  /// sold" count.
  Map<String, double> get soldQtyByProduct {
    final totals = <String, double>{};
    for (final movement in saleMovements) {
      totals[movement.productId] =
          (totals[movement.productId] ?? 0) + (-movement.deltaQty);
    }
    return totals;
  }

  /// The 5 fastest-moving products within [filteredProducts], busiest
  /// first — empty until at least one sale has been recorded.
  List<Product> get topSellers {
    final sold = soldQtyByProduct;
    final withSales = filteredProducts
        .where((p) => (sold[p.id] ?? 0) > 0)
        .toList();
    withSales.sort((a, b) => (sold[b.id] ?? 0).compareTo(sold[a.id] ?? 0));
    return withSales.take(5).toList();
  }

  /// Up to 5 in-stock products within [filteredProducts] that have never
  /// sold a single unit, largest on-hand quantity first — the "কমে যাওয়া"
  /// (slow-moving) counterpart to [topSellers].
  List<Product> get slowMovers {
    final sold = soldQtyByProduct;
    final noSales = filteredProducts
        .where((p) => (sold[p.id] ?? 0) == 0 && p.qty > 0)
        .toList();
    noSales.sort((a, b) => b.qty.compareTo(a.qty));
    return noSales.take(5).toList();
  }

  String investorName(String id) {
    for (final investor in investors) {
      if (investor.id == id) return investor.name;
    }
    return id;
  }
}
