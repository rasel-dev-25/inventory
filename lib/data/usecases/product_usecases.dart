import 'dart:convert';

import '../../domain/entities/product.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'sync_enqueue_helper.dart';

/// Create/update/delete for [Product] — [ProductDao] already builds the
/// storage companion from a domain entity; this layer additionally builds
/// the matching outbox row from the exact same [Product]/[now] values, and
/// writes both together. Never touches `qty` directly — that only ever
/// changes alongside a stock movement (see `SavePurchaseTripUseCase`),
/// same rule `ProductDao.adjustQty`'s own doc comment states.
///
/// [create]/[update] are audit-logged — see `audit_log_usecases.dart`'s
/// own doc comment, which names this exact call site (`update`, tracking
/// a changed selling price) as the concrete example of the coverage this
/// module was still missing when only delete/restore on four other
/// entities were wired up. [update] fetches the pre-write row itself
/// (`db.productDao.getById`) rather than asking every caller to also pass
/// the "before" state, matching `CustomerUseCases.softDelete`'s own
/// self-fetch convention.
class ProductUseCases {
  final AppDatabaseV2 db;

  ProductUseCases(this.db);

  Future<void> create(
    Product product, {
    required String shopId,
    required DateTime now,
  }) async {
    await writeAndEnqueue(
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

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'insert',
      changedTableName: 'products',
      recordId: product.id,
      newValueJson: jsonEncode(_rowFor(product, shopId: shopId)),
      now: now,
    );
  }

  Future<void> update(
    Product product, {
    required String shopId,
    required DateTime now,
  }) async {
    final existing = await db.productDao.getById(product.id);

    await writeAndEnqueue(
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

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'update',
      changedTableName: 'products',
      recordId: product.id,
      oldValueJson: existing == null
          ? null
          : jsonEncode(_rowFor(existing, shopId: shopId)),
      newValueJson: jsonEncode(_rowFor(product, shopId: shopId)),
      now: now,
    );
  }

  /// Soft-deletes the product. No reversal needed (unlike
  /// `ExpenseUseCases.softDelete`/`DeletePurchaseTripUseCase`) — creating
  /// or updating a product never writes a paired cash-ledger or
  /// stock-movement row (see the class doc comment and
  /// `ProductDao.adjustQty`'s own), so there is nothing else to undo. Safe
  /// to [restore] unconditionally for the same reason — see
  /// `ProductDao.restore`'s own doc comment.
  Future<void> softDelete(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    final existing = await db.productDao.getById(id);

    await writeAndEnqueue(
      db: db,
      eventType: 'product_deleted',
      upserts: [
        TableUpsert(
          table: 'products',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.productDao.softDelete(id, now),
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'products',
      recordId: id,
      oldValueJson: existing == null
          ? null
          : jsonEncode(_rowFor(existing, shopId: shopId)),
      now: now,
    );
  }

  /// Un-deletes — see `ProductDao.restore`'s own doc comment for why this
  /// is safe unconditionally. Not currently pushed to the outbox, same
  /// "local-only Recycle Bin action" caveat `CustomerUseCases.restore`
  /// documents.
  Future<void> restore(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    await db.productDao.restore(id, now);
    final restored = await db.productDao.getById(id);

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'restore',
      changedTableName: 'products',
      recordId: id,
      newValueJson: restored == null
          ? null
          : jsonEncode(_rowFor(restored, shopId: shopId)),
      now: now,
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
      'page_count': product.pageCount,
    };
  }
}
