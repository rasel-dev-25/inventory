import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/fixed_asset.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// The two fixed-asset creation paths, per `notes/business_logic.md`'s
/// "দুইভাবে যোগ করার ব্যবস্থা" — deliberately two separate methods, not
/// one method branching on a `source` parameter, since the two paths
/// touch entirely different tables (cash ledger vs. stock movements) and
/// have entirely different validation (a value the owner types vs. a
/// quantity that must not exceed on-hand stock).
class FixedAssetUseCases {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  FixedAssetUseCases(this.db);

  /// Path 1 — "সরাসরি কেনা": bought outright with the shop's cash. Pairs
  /// the asset with a negative `cash_ledger_entries` row, same shape as
  /// every other cash-out use case in this directory.
  Future<Result<void>> createFromCashPurchase({
    required String name,
    required Money value,
    required DateTime dateAcquired,
    required String shopId,
    required DateTime now,
  }) async {
    if (name.trim().isEmpty) {
      return const Result.err(
        ValidationFailure('name', 'Give this asset a name'),
      );
    }
    if (!value.isPositive) {
      return const Result.err(
        ValidationFailure('value', 'Asset value must be positive'),
      );
    }

    final asset = FixedAsset(
      id: _uuid.v7(),
      name: name.trim(),
      value: value,
      dateAcquired: dateAcquired,
      sourceType: FixedAssetSource.shopCashPurchase,
    );

    final ledgerId = _uuid.v7();
    final dateIso = dateAcquired.toUtc().toIso8601String();

    await writeAndEnqueue(
      db: db,
      eventType: 'fixed_asset_purchased',
      upserts: [
        TableUpsert(table: 'fixed_assets', row: _rowFor(asset, shopId)),
        TableUpsert(
          table: 'cash_ledger_entries',
          row: {
            'id': ledgerId,
            'shop_id': shopId,
            'amount_minor': -value.minorUnits,
            'payment_method': PaymentMethod.cash.name,
            'source_type': 'fixed_asset',
            'source_id': asset.id,
            'description': 'Fixed asset purchase: ${asset.name}',
            'date': dateIso,
          },
        ),
      ],
      localWrite: () async {
        await db.fixedAssetDao.create(asset, shopId: shopId, now: now);
        await db.ledgerDao.recordCashLedgerEntry(
          id: ledgerId,
          shopId: shopId,
          amountMinor: -value.minorUnits,
          paymentMethod: PaymentMethod.cash,
          sourceType: 'fixed_asset',
          sourceId: asset.id,
          date: dateAcquired,
          now: now,
          description: 'Fixed asset purchase: ${asset.name}',
        );
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'insert',
      changedTableName: 'fixed_assets',
      recordId: asset.id,
      newValueJson: jsonEncode(_rowFor(asset, shopId)),
      now: now,
    );

    return const Result.ok(null);
  }

  /// Path 2 — "স্টক থেকে কনভার্ট": pulls [qty] units of [productId] off
  /// the sellable shelf and records them as a fixed asset instead. Pairs
  /// the asset with a negative `stock_movements` row (and the matching
  /// `Products.qty` decrement) — **no** cash ledger entry, per the
  /// spec's explicit "কোনো নতুন Cash movement হবে না".
  ///
  /// [FixedAsset.value] is computed here as `product.costPrice × qty`,
  /// never asked for — unlike the cash-purchase path, there is no
  /// independent price being paid right now to record; the product's own
  /// cost price is the only real number describing what this asset is
  /// worth.
  Future<Result<void>> createFromStock({
    required String productId,
    required double qty,
    required String shopId,
    required DateTime now,
    String? name,
    DateTime? dateAcquired,
  }) async {
    if (qty <= 0) {
      return const Result.err(
        ValidationFailure('qty', 'Quantity must be positive'),
      );
    }

    final product = await db.productDao.getById(productId);
    if (product == null) {
      return Result.err(NotFoundFailure('product', productId));
    }
    if (qty > product.qty) {
      return Result.err(
        BusinessRuleFailure(
          'Not enough stock: only ${product.qty} of ${product.name} available',
        ),
      );
    }

    final effectiveDate = dateAcquired ?? now;
    final asset = FixedAsset(
      id: _uuid.v7(),
      name: (name == null || name.trim().isEmpty) ? product.name : name.trim(),
      value: product.costPrice * qty,
      dateAcquired: effectiveDate,
      sourceType: FixedAssetSource.convertedFromStock,
      sourceProductId: productId,
    );

    final movementId = _uuid.v7();
    final dateIso = effectiveDate.toUtc().toIso8601String();

    await writeAndEnqueue(
      db: db,
      eventType: 'fixed_asset_converted_from_stock',
      upserts: [
        TableUpsert(table: 'fixed_assets', row: _rowFor(asset, shopId)),
        TableUpsert(
          table: 'stock_movements',
          row: {
            'id': movementId,
            'shop_id': shopId,
            'product_id': productId,
            'delta_qty': -qty,
            'source_type': 'fixed_asset',
            'source_id': asset.id,
            'date': dateIso,
          },
        ),
      ],
      localWrite: () async {
        await db.fixedAssetDao.create(asset, shopId: shopId, now: now);
        await db.productDao.adjustQty(productId, -qty, now);
        await db.ledgerDao.recordStockMovement(
          id: movementId,
          shopId: shopId,
          productId: productId,
          deltaQty: -qty,
          sourceType: 'fixed_asset',
          sourceId: asset.id,
          date: effectiveDate,
          now: now,
        );
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'insert',
      changedTableName: 'fixed_assets',
      recordId: asset.id,
      newValueJson: jsonEncode(_rowFor(asset, shopId)),
      now: now,
    );

    return const Result.ok(null);
  }

  /// Soft-deletes the asset *and* reverses whichever paired write its
  /// creation made — a negative `cash_ledger_entries` row for
  /// [FixedAssetSource.shopCashPurchase], a negative `stock_movements` row
  /// (undoing the `Products.qty` decrement too) for
  /// [FixedAssetSource.convertedFromStock]. Branches on
  /// [FixedAsset.sourceType] rather than calling both reversal builders
  /// unconditionally — `buildCashLedgerReversal`/`buildStockMovementReversal`
  /// both already no-op safely on a source with zero matching rows (see
  /// `ledger_reversal.dart`'s own doc comment), but a given asset only
  /// ever has rows in *one* of the two tables, never both, so this stays
  /// explicit about which one actually applies instead of relying on that
  /// no-op behavior to paper over calling the wrong one.
  ///
  /// No `restore` counterpart — same reasoning `ExpenseUseCases.softDelete`
  /// documents: undoing this would need to re-apply a reversal
  /// `buildCashLedgerReversal`/`buildStockMovementReversal` cannot safely
  /// run a second time on an already-reversed source.
  Future<Result<void>> delete({
    required String id,
    required String shopId,
    required DateTime now,
  }) async {
    final asset = await db.fixedAssetDao.getById(id);
    if (asset == null) {
      return Result.err(NotFoundFailure('fixedAsset', id));
    }

    final reversal = switch (asset.sourceType) {
      FixedAssetSource.shopCashPurchase => await buildCashLedgerReversal(
        db: db,
        shopId: shopId,
        sourceType: 'fixed_asset',
        sourceId: id,
        date: now,
        now: now,
      ),
      FixedAssetSource.convertedFromStock => await buildStockMovementReversal(
        db: db,
        shopId: shopId,
        sourceType: 'fixed_asset',
        sourceId: id,
        date: now,
        now: now,
      ),
    };

    await writeAndEnqueue(
      db: db,
      eventType: 'fixed_asset_deleted',
      upserts: [
        TableUpsert(
          table: 'fixed_assets',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
        ...reversal.upserts,
      ],
      localWrite: () async {
        await db.fixedAssetDao.softDelete(id, now);
        await reversal.localWrite();
      },
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'fixed_assets',
      recordId: id,
      oldValueJson: jsonEncode(_rowFor(asset, shopId)),
      now: now,
    );

    return const Result.ok(null);
  }

  Map<String, Object?> _rowFor(FixedAsset asset, String shopId) {
    return {
      'id': asset.id,
      'shop_id': shopId,
      'name': asset.name,
      'value_minor': asset.value.minorUnits,
      'date_acquired': asset.dateAcquired.toUtc().toIso8601String(),
      'source_type': asset.sourceType.name,
      'source_product_id': asset.sourceProductId,
    };
  }
}
