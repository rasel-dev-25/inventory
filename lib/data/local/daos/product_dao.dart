import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../app_database.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/product.dart' as domain;
import '../tables/products.dart';

part 'product_dao.g.dart';

/// Maps between the storage row ([ProductRow], generated from the
/// [Products] table) and the domain entity ([domain.Product]) — the only
/// place this mapping happens, so a schema column rename only ever
/// touches this one function pair.
extension _ProductRowMapping on ProductRow {
  domain.Product toDomain() {
    return domain.Product(
      id: id,
      name: name,
      category: category,
      costPrice: Money.fromMinor(costPriceMinor),
      suggestedSellPrice: Money.fromMinor(suggestedSellPriceMinor),
      qty: qty,
      fundSource: fundSourceType == FundSourceType.shop
          ? FundSource.shop()
          : FundSource.investor(fundSourceInvestorId!),
      isRentable: isRentable,
      barcode: barcode,
      sku: sku,
      pageCount: pageCount,
    );
  }
}

/// Data access for [Products] — the only place that translates between
/// [domain.Product] and the storage row. Every write method here is a
/// single statement, not a multi-table transaction (unlike
/// [PurchaseDao].saveTrip) — a product create/update has no other table it
/// must stay in lockstep with.
///
/// `qty` is intentionally NOT written directly by [updateQty] here without
/// a matching [StockMovements] row — see `tables/products.dart`'s doc
/// comment on the "disciplined single writer" rule. Once
/// `CompleteSaleUseCase`/`SavePurchaseTripUseCase` exist (a later PR),
/// they own that pairing; this DAO only exposes the primitive `adjustQty`
/// used by those use cases, not a public `setQty` that could be called
/// without the accompanying movement row.
///
/// Deliberately **no `hardDeleteOlderThan`**, unlike `CustomerDao`/
/// `OrderDao`/`ExpenseDao`: `Products.id` is a foreign key target for
/// `StockMovements`, `SaleItems`, `PurchaseItems`, and `RentTiers` (see
/// `tables/ledger.dart`/`sales.dart`/`purchases.dart`/`products.dart`'s
/// own `references(Products, #id)` columns) — a real `DELETE` on any
/// product with actual sale/purchase/rent history would violate those FK
/// constraints. [softDelete]/[restore] (hide/un-hide) are as far as this
/// DAO goes; `RetentionPolicyUseCase` does not prune this table.
@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabaseV2>
    with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<domain.Product?> getById(String id) async {
    final row = await (select(
      products,
    )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  /// All non-deleted products for the current shop, live-updating.
  Stream<List<domain.Product>> watchAll(String shopId) {
    final query = select(products)
      ..where((p) => p.shopId.equals(shopId) & p.deletedAt.isNull())
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Stream<List<domain.Product>> watchByCategory(String shopId, String category) {
    final query = select(products)
      ..where(
        (p) =>
            p.shopId.equals(shopId) &
            p.category.equals(category) &
            p.deletedAt.isNull(),
      )
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Inserts a new product. [now] is threaded in explicitly (from `Clock`)
  /// rather than read from `DateTime.now()` here, so this method stays
  /// deterministic in tests.
  Future<void> create(
    domain.Product product, {
    required String shopId,
    required DateTime now,
  }) {
    return into(
      products,
    ).insert(_companionFor(product, shopId: shopId, now: now));
  }

  /// Full-row update (name/category/prices/fund source/etc.) — never
  /// touches `qty`, see the class doc comment.
  Future<void> updateProduct(
    domain.Product product, {
    required String shopId,
    required DateTime now,
  }) {
    final companion = _companionFor(
      product,
      shopId: shopId,
      now: now,
    ).copyWith(updatedAt: Value(now));
    return (update(
      products,
    )..where((p) => p.id.equals(product.id))).write(companion);
  }

  /// The one place `qty` may change outside a fresh insert — always called
  /// alongside a [StockMovements] insert in the same transaction by
  /// whichever use case triggered the change; never exposed as a bare
  /// "set qty to X" to prevent qty and the movement log from ever drifting
  /// apart.
  Future<void> adjustQty(String productId, double delta, DateTime now) async {
    final row = await (select(
      products,
    )..where((p) => p.id.equals(productId))).getSingle();
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(qty: Value(row.qty + delta), updatedAt: Value(now)),
    );
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Every soft-deleted [Products] row for [shopId] — the Recycle Bin's
  /// source list, same shape as `CustomerDao.watchDeleted`. Returns the
  /// raw generated row (not [domain.Product]) for the same reason: only
  /// the bin needs `deletedAt`, and the domain entity doesn't carry it.
  Stream<List<ProductRow>> watchDeleted(String shopId) {
    final query = select(products)
      ..where((p) => p.shopId.equals(shopId) & p.deletedAt.isNotNull())
      ..orderBy([(p) => OrderingTerm.desc(p.deletedAt)]);
    return query.watch();
  }

  /// Un-deletes — clears `deletedAt` and nothing else. Safe to offer
  /// unconditionally, same reasoning as `CustomerDao.restore`: creating a
  /// product never writes a paired cash-ledger or stock-movement entry
  /// (see this class's own doc comment — `qty` only ever moves via
  /// [adjustQty], driven by other use cases, never by create/update
  /// here), so there is nothing else to undo.
  Future<void> restore(String id, DateTime now) {
    return (update(products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  ProductsCompanion _companionFor(
    domain.Product product, {
    required String shopId,
    required DateTime now,
  }) {
    return ProductsCompanion.insert(
      id: product.id,
      shopId: shopId,
      name: product.name,
      category: product.category,
      costPriceMinor: product.costPrice.minorUnits,
      suggestedSellPriceMinor: product.suggestedSellPrice.minorUnits,
      qty: Value(product.qty),
      fundSourceType: product.fundSource.type,
      fundSourceInvestorId: Value(product.fundSource.investorId),
      isRentable: Value(product.isRentable),
      barcode: Value(product.barcode),
      sku: Value(product.sku),
      pageCount: Value(product.pageCount),
      createdAt: now,
      updatedAt: now,
      syncedAt: now,
    );
  }
}
