import '../../domain/entities/product.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create/update for [Product] — [ProductDao] already builds the storage
/// companion from a domain entity; this layer additionally builds the
/// matching outbox row from the exact same [Product]/[now] values, and
/// writes both together. Never touches `qty` directly — that only ever
/// changes alongside a stock movement (see `SavePurchaseTripUseCase`),
/// same rule `ProductDao.adjustQty`'s own doc comment states.
class ProductUseCases {
  final AppDatabaseV2 db;

  ProductUseCases(this.db);

  Future<void> create(
    Product product, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'product_created',
      upserts: [
        TableUpsert(
          table: 'products',
          row: _rowFor(product, shopId: shopId),
        ),
      ],
      localWrite: () => db.productDao.create(product, shopId: shopId, now: now),
    );
  }

  Future<void> update(
    Product product, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'product_updated',
      upserts: [
        TableUpsert(
          table: 'products',
          row: _rowFor(product, shopId: shopId),
        ),
      ],
      localWrite: () =>
          db.productDao.updateProduct(product, shopId: shopId, now: now),
    );
  }

  Map<String, Object?> _rowFor(Product product, {required String shopId}) {
    return {
      'id': product.id,
      'shop_id': shopId,
      'name': product.name,
      'category': product.category,
      'cost_price_minor': product.costPrice.minorUnits,
      'suggested_sell_price_minor': product.suggestedSellPrice.minorUnits,
      // Included even though the class doc comment says this use case
      // never *changes* qty — matching ProductDao._companionFor exactly,
      // which writes qty on every call (create and update alike). The
      // "never touches qty" guarantee is therefore the caller's
      // responsibility: an edit-product flow must round-trip the
      // product's existing qty unchanged, never recompute it, exactly as
      // it must for the local write this outbox row mirrors.
      'qty': product.qty,
      'fund_source_type': product.fundSource.type.name,
      'fund_source_investor_id': product.fundSource.investorId,
      'is_rentable': product.isRentable,
      'barcode': product.barcode,
      'sku': product.sku,
    };
  }
}
