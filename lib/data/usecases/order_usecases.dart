import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/order.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'sync_enqueue_helper.dart';

/// Create/status-transition/delete for [Order] — per
/// `notes/business_logic.md` §Order. No cash or stock impact anywhere in
/// this file, unlike almost everything else in this directory — an order
/// is a request to track, not a transaction to reconcile.
class OrderUseCases {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  OrderUseCases(this.db);

  Future<Result<void>> create({
    required String customerId,
    required String itemDescription,
    required DateTime requestedDate,
    required String shopId,
    required DateTime now,
    DateTime? neededByDate,
  }) async {
    if (itemDescription.trim().isEmpty) {
      return const Result.err(
        ValidationFailure(
          'itemDescription',
          'Describe what the customer wants',
        ),
      );
    }

    final order = Order(
      id: _uuid.v7(),
      customerId: customerId,
      itemDescription: itemDescription.trim(),
      requestedDate: requestedDate,
      neededByDate: neededByDate,
      status: OrderStatus.pending,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'order_created',
      upserts: [TableUpsert(table: 'orders', row: _rowFor(order, shopId))],
      localWrite: () => db.orderDao.create(order, shopId: shopId, now: now),
    );

    return const Result.ok(null);
  }

  /// [status] must be [OrderStatus.fulfilled] or [OrderStatus.cancelled] —
  /// see `notes/business_logic.md` §Order's `fulfilledDate`: "শেষ পর্যন্ত
  /// নিয়েছেন কিনা তার প্রমাণ" (proof of whether they actually took it in
  /// the end), so it is only ever set on the fulfilled transition, never
  /// on cancellation.
  Future<Result<void>> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String shopId,
    required DateTime now,
  }) async {
    if (status == OrderStatus.pending) {
      return const Result.err(
        ValidationFailure('status', 'An order cannot be moved back to pending'),
      );
    }

    final order = await db.orderDao.getById(orderId);
    if (order == null) {
      return Result.err(NotFoundFailure('order', orderId));
    }
    if (order.status != OrderStatus.pending) {
      return const Result.err(
        BusinessRuleFailure('This order has already been settled'),
      );
    }

    final updated = order.copyWith(
      status: status,
      fulfilledDate: status == OrderStatus.fulfilled ? now : null,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'order_status_updated',
      upserts: [TableUpsert(table: 'orders', row: _rowFor(updated, shopId))],
      localWrite: () => db.orderDao.updateStatus(updated, now),
    );

    return const Result.ok(null);
  }

  /// Audit-logged — see `CustomerUseCases.softDelete`'s own doc comment
  /// for why this and [restore] are among the small, explicit set of
  /// call sites that write an audit entry today.
  Future<void> softDelete(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    final existing = await db.orderDao.getById(id);

    await writeAndEnqueue(
      db: db,
      eventType: 'order_deleted',
      upserts: [
        TableUpsert(
          table: 'orders',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.orderDao.softDelete(id, now),
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'orders',
      recordId: id,
      oldValueJson: existing == null
          ? null
          : jsonEncode(_rowFor(existing, shopId)),
      now: now,
    );
  }

  /// Un-deletes — safe unconditionally, see `OrderDao.restore`'s own doc
  /// comment. Local-only, same as `CustomerUseCases.restore`.
  Future<void> restore(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    await db.orderDao.restore(id, now);
    final restored = await db.orderDao.getById(id);

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'restore',
      changedTableName: 'orders',
      recordId: id,
      newValueJson: restored == null
          ? null
          : jsonEncode(_rowFor(restored, shopId)),
      now: now,
    );
  }

  Map<String, Object?> _rowFor(Order order, String shopId) {
    return {
      'id': order.id,
      'shop_id': shopId,
      'customer_id': order.customerId,
      'item_description': order.itemDescription,
      'requested_date': order.requestedDate.toUtc().toIso8601String(),
      'needed_by_date': order.neededByDate?.toUtc().toIso8601String(),
      'status': order.status.name,
      'fulfilled_date': order.fulfilledDate?.toUtc().toIso8601String(),
    };
  }
}
