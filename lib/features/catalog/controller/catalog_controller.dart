import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/category_usecases.dart';
import '../../../data/usecases/product_usecases.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../pricing_settings_v2/controller/pricing_settings_controller.dart';

/// Backs the new v2 categories/products screens
/// (`lib/features/catalog/view/`). Reads live from [AppDatabaseV2] via
/// `CategoryDao`/`ProductDao`'s `watch*` streams, and writes through
/// `CategoryUseCases`/`ProductUseCases` so every create/rename/reorder
/// also enqueues its outbox event — see `SYNC.md`.
///
/// Deliberately a single controller for both categories and products,
/// not two: the products screen needs the live category list for its
/// picker regardless, and there is no independent categories screen a
/// user reaches without also caring about products.
class CatalogController extends GetxController {
  final AppDatabaseV2 db;

  /// The pricing-engine controller — a permanent, app-wide singleton (see
  /// its own doc comment), injected here rather than looked up ad hoc so
  /// [overheadMarkupPercent] stays plain constructor-injected state like
  /// every other v2 controller dependency.
  final PricingSettingsController pricingSettings;

  static const _uuid = Uuid();

  CatalogController(this.db, this.pricingSettings);

  late final CategoryUseCases _categoryUseCases = CategoryUseCases(db);
  late final ProductUseCases _productUseCases = ProductUseCases(db);

  /// Null exactly when `ProductFormSheet`'s cost-price suggestion should
  /// stay hidden (the pricing engine's bootstrap period, or no usable
  /// revenue estimate yet) — see `computeOverheadMarkupPercent`'s doc
  /// comment for the exact conditions.
  double? get overheadMarkupPercent => pricingSettings.overheadMarkupPercent;

  final categories = <CategoryRow>[].obs;
  final products = <Product>[].obs;
  final investors = <Investor>[].obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    // Cancelled in onClose(); an uncancelled watch() subscription is a
    // leak in production and, worse, can deadlock a test's
    // `db.close()` call while the subscription is still trying to query
    // a database that's mid-shutdown — caught by a real test hang, not
    // by inspection.
    _subscriptions.add(
      db.categoryDao
          .watchAll(defaultShopId)
          .listen((rows) => categories.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Future<bool> createCategory(String name) async {
    if (name.trim().isEmpty) {
      errorMessage.value = 'nameRequired'.tr;
      return false;
    }
    try {
      final nextSortOrder = categories.isEmpty
          ? 0
          : categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) +
                1;
      await _categoryUseCases.create(
        id: _uuid.v7(),
        shopId: defaultShopId,
        name: name.trim(),
        sortOrder: nextSortOrder,
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> renameCategory(String id, String name) async {
    if (name.trim().isEmpty) return false;
    try {
      await _categoryUseCases.rename(
        id: id,
        shopId: defaultShopId,
        name: name.trim(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> moveCategory(CategoryRow category, {required bool up}) async {
    final sorted = [...categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = sorted.indexWhere((c) => c.id == category.id);
    final swapIndex = up ? index - 1 : index + 1;
    if (index < 0 || swapIndex < 0 || swapIndex >= sorted.length) return false;

    final other = sorted[swapIndex];
    try {
      await _categoryUseCases.reorder(
        id: category.id,
        shopId: defaultShopId,
        sortOrder: other.sortOrder,
      );
      await _categoryUseCases.reorder(
        id: other.id,
        shopId: defaultShopId,
        sortOrder: category.sortOrder,
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> createProduct({
    required String name,
    required String category,
    required Money costPrice,
    required Money suggestedSellPrice,
    required FundSource fundSource,
    bool isRentable = false,
    String? barcode,
    String? sku,
    int? pageCount,
  }) async {
    try {
      final product = Product(
        id: _uuid.v7(),
        name: name.trim(),
        category: category,
        costPrice: costPrice,
        suggestedSellPrice: suggestedSellPrice,
        qty: 0,
        fundSource: fundSource,
        isRentable: isRentable,
        barcode: barcode,
        sku: sku,
        pageCount: pageCount,
      );
      await _productUseCases.create(
        product,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  /// [existing] must be the product as currently stored (from
  /// [products]) — every field this doesn't explicitly change is carried
  /// over unchanged, including `qty`, which this screen never edits
  /// directly (see `ProductUseCases`' class doc comment).
  Future<bool> updateProduct(
    Product existing, {
    String? name,
    String? category,
    Money? costPrice,
    Money? suggestedSellPrice,
    FundSource? fundSource,
    bool? isRentable,
    String? barcode,
    String? sku,
    int? pageCount,
  }) async {
    try {
      final updated = existing.copyWith(
        name: name,
        category: category,
        costPrice: costPrice,
        suggestedSellPrice: suggestedSellPrice,
        fundSource: fundSource,
        isRentable: isRentable,
        barcode: barcode,
        sku: sku,
        pageCount: pageCount,
      );
      await _productUseCases.update(
        updated,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }
}
