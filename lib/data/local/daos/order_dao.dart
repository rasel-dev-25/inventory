import 'package:drift/drift.dart';

import '../../../domain/entities/order.dart' as domain;
import '../app_database.dart';
import '../tables/orders.dart';

part 'order_dao.g.dart';

extension _OrderRowMapping on OrderRow {
  domain.Order toDomain() {
    return domain.Order(
      id: id,
      customerId: customerId,
      itemDescription: itemDescription,
      requestedDate: requestedDate,
      neededByDate: neededByDate,
      status: status,
      fulfilledDate: fulfilledDate,
    );
  }
}

/// Data access for [Orders] — a customer pre-order, per
/// `notes/business_logic.md` §Order. Unlike most business tables in this
/// app, an order has no cash or stock impact at all, so `update` here is
/// a plain full-row write (not split into a create-only/no-update pair
/// the way `ExpenseDao`/`SaleDao` are, since there is no paired ledger
/// entry that a later edit could ever leave stale).
@DriftAccessor(tables: [Orders])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  Future<domain.Order?> getById(String id) async {
    final row = await (select(
      orders,
    )..where((o) => o.id.equals(id) & o.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Order>> watchAll(String shopId) {
    final query = select(orders)
      ..where((o) => o.shopId.equals(shopId) & o.deletedAt.isNull())
      ..orderBy([(o) => OrderingTerm.desc(o.requestedDate)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Order order, {
    required String shopId,
    required DateTime now,
  }) {
    return into(orders).insert(
      OrdersCompanion.insert(
        id: order.id,
        shopId: shopId,
        customerId: order.customerId,
        itemDescription: order.itemDescription,
        requestedDate: order.requestedDate,
        neededByDate: Value(order.neededByDate),
        status: order.status,
        fulfilledDate: Value(order.fulfilledDate),
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Writes the new [domain.Order.status] and [domain.Order.fulfilledDate]
  /// together — the one place either changes after creation.
  Future<void> updateStatus(domain.Order updated, DateTime now) {
    return (update(orders)..where((o) => o.id.equals(updated.id))).write(
      OrdersCompanion(
        status: Value(updated.status),
        fulfilledDate: Value(updated.fulfilledDate),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(orders)..where((o) => o.id.equals(id))).write(
      OrdersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// The Recycle Bin's source list for [Orders] — see `CustomerDao.
  /// watchDeleted`'s doc comment for why this returns the raw
  /// [OrderRow], not [domain.Order].
  Stream<List<OrderRow>> watchDeleted(String shopId) {
    final query = select(orders)
      ..where((o) => o.shopId.equals(shopId) & o.deletedAt.isNotNull())
      ..orderBy([(o) => OrderingTerm.desc(o.deletedAt)]);
    return query.watch();
  }

  /// Un-deletes — safe unconditionally, same reasoning as
  /// `CustomerDao.restore`: an order has no paired cash/stock write to
  /// also undo.
  Future<void> restore(String id, DateTime now) {
    return (update(orders)..where((o) => o.id.equals(id))).write(
      OrdersCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  /// [RetentionPolicyUseCase]'s half of the retention policy for this
  /// table — see `CustomerDao.hardDeleteOlderThan`'s doc comment.
  Future<int> hardDeleteOlderThan(String shopId, DateTime cutoff) {
    return (delete(orders)..where(
          (o) =>
              o.shopId.equals(shopId) &
              o.deletedAt.isNotNull() &
              o.deletedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  /// Permanently deletes a single order.
  Future<bool> hardDelete(String id) async {
    final rows = await (delete(orders)..where((o) => o.id.equals(id))).go();
    return rows > 0;
  }
}
