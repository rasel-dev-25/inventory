import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../domain/entities/customer.dart' as domain;
import '../tables/customers.dart';
import '../tables/dues.dart';
import '../tables/orders.dart';
import '../tables/rent.dart';
import '../tables/sales.dart';

part 'customer_dao.g.dart';

extension _CustomerRowMapping on CustomerRow {
  domain.Customer toDomain() {
    return domain.Customer(
      id: id,
      name: name,
      address: address,
      contact: contact,
      suspicionFlag: suspicionFlag,
      isBlocked: isBlocked,
    );
  }
}

/// Data access for [Customers]. Deliberately has no `type`/category
/// parameter anywhere on this DAO — see `tables/customers.dart`'s doc
/// comment: "buyer/order-giver/renter/due-taker" is a query joining this
/// table with Sales/Orders/RentTransactions/Dues, not a stored column, so
/// there is nothing here to filter by directly.
/// [Dues]/[Orders]/[RentTransactions]/[Sales] are declared here too, on
/// top of [Customers] — not because this DAO owns them (their own
/// DAOs do), but because [hardDeleteOlderThan] needs to check whether a
/// customer has any row in them before actually deleting, and `select()`
/// on a table only works once that table is declared on this
/// `@DriftAccessor`. Multiple DAOs declaring the same table is normal in
/// Drift — each gets its own independent mixin.
@DriftAccessor(tables: [Customers, Dues, Orders, RentTransactions, Sales])
class CustomerDao extends DatabaseAccessor<AppDatabaseV2>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Future<domain.Customer?> getById(String id) async {
    final row = await (select(
      customers,
    )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Customer>> watchAll(String shopId) {
    final query = select(customers)
      ..where((c) => c.shopId.equals(shopId) & c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Customers with [domain.Customer.isBlocked] or [domain.Customer.suspicionFlag]
  /// set — the spec's repeated-reminder list (§জ).
  Stream<List<domain.Customer>> watchFlagged(String shopId) {
    final query = select(customers)
      ..where(
        (c) =>
            c.shopId.equals(shopId) &
            c.deletedAt.isNull() &
            (c.suspicionFlag.equals(true) | c.isBlocked.equals(true)),
      );
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Customer customer, {
    required String shopId,
    required DateTime now,
  }) {
    return into(
      customers,
    ).insert(_companionFor(customer, shopId: shopId, now: now));
  }

  Future<void> updateCustomer(
    domain.Customer customer, {
    required String shopId,
    required DateTime now,
  }) {
    final companion = _companionFor(
      customer,
      shopId: shopId,
      now: now,
    ).copyWith(updatedAt: Value(now));
    return (update(
      customers,
    )..where((c) => c.id.equals(customer.id))).write(companion);
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Every soft-deleted [Customers] row for [shopId] — the Recycle Bin's
  /// source list. Returns the raw generated row (not [domain.Customer])
  /// since [CustomerRow.deletedAt] is exactly the field the bin needs to
  /// show "deleted 3 days ago" and the domain entity deliberately doesn't
  /// carry that column at all (nothing in normal business logic needs
  /// it) — same shortcut `dashboard_v2` already takes with
  /// `StockMovementRow` for a screen-specific need the domain layer has
  /// no reason to model.
  Stream<List<CustomerRow>> watchDeleted(String shopId) {
    final query = select(customers)
      ..where((c) => c.shopId.equals(shopId) & c.deletedAt.isNotNull())
      ..orderBy([(c) => OrderingTerm.desc(c.deletedAt)]);
    return query.watch();
  }

  /// Un-deletes — clears `deletedAt` and nothing else. Safe to offer
  /// unconditionally for a [Customers] row: unlike `Expenses`/
  /// `PurchaseTrips`, deleting a customer never wrote a paired cash-ledger
  /// or stock-movement reversal to also undo (see `CustomerUseCases`'
  /// own doc comment — a customer has no such side effect).
  Future<void> restore(String id, DateTime now) {
    return (update(customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  /// A real `DELETE`, not another soft-delete — [RetentionPolicyUseCase]'s
  /// half of the retention policy for this table. Only ever touches rows
  /// already past [cutoff] in `deletedAt`; a customer that was never
  /// deleted at all is untouched regardless of how old it is.
  ///
  /// **FK-safety fix**: `Customers.id` is a foreign-key target for
  /// [Dues]/[Orders]/[RentTransactions]/[Sales] (`customerId` columns) —
  /// unlike a plain soft-delete, a real `DELETE` here would violate those
  /// constraints for any customer with actual order/due/rent/sale
  /// history. This used to run unconditionally regardless (a
  /// pre-existing gap from the PR that first added this policy,
  /// undetected because its own test only ever pruned a customer with no
  /// linked history — see that test's own comment). [_hasLinkedHistory]
  /// now checks each candidate first and skips any that have real
  /// history, leaving them soft-deleted (visible in the Recycle Bin,
  /// past its normal retention window) rather than throwing or silently
  /// corrupting the delete. Same reasoning `ProductDao`'s own doc comment
  /// gives for never hard-deleting products at all — the difference here
  /// is that *most* customers never accumulate this kind of history, so
  /// skipping only the ones that do is the right fix rather than
  /// excluding the whole table from retention.
  Future<int> hardDeleteOlderThan(String shopId, DateTime cutoff) async {
    final candidates =
        await (select(customers)..where(
              (c) =>
                  c.shopId.equals(shopId) &
                  c.deletedAt.isNotNull() &
                  c.deletedAt.isSmallerThanValue(cutoff),
            ))
            .get();

    var deletedCount = 0;
    for (final candidate in candidates) {
      if (await _hasLinkedHistory(candidate.id)) continue;
      await (delete(customers)..where((c) => c.id.equals(candidate.id))).go();
      deletedCount++;
    }
    return deletedCount;
  }

  /// True if [customerId] has any row in [Dues]/[Orders]/
  /// [RentTransactions]/[Sales] — the exact set of tables whose
  /// `customerId` column references [Customers.id]. Checked one table at
  /// a time with `limit(1)`, short-circuiting on the first hit, rather
  /// than one combined query — this only ever runs over a handful of
  /// already-soft-deleted, already-past-retention candidates, not the
  /// live customer list, so the extra round-trips are not a real cost
  /// here.
  Future<bool> _hasLinkedHistory(String customerId) async {
    final due =
        await (select(dues)
              ..where((d) => d.customerId.equals(customerId))
              ..limit(1))
            .getSingleOrNull();
    if (due != null) return true;

    final order =
        await (select(orders)
              ..where((o) => o.customerId.equals(customerId))
              ..limit(1))
            .getSingleOrNull();
    if (order != null) return true;

    final rentTransaction =
        await (select(rentTransactions)
              ..where((r) => r.customerId.equals(customerId))
              ..limit(1))
            .getSingleOrNull();
    if (rentTransaction != null) return true;

    final sale =
        await (select(sales)
              ..where((s) => s.customerId.equals(customerId))
              ..limit(1))
            .getSingleOrNull();
    if (sale != null) return true;

    return false;
  }

  CustomersCompanion _companionFor(
    domain.Customer customer, {
    required String shopId,
    required DateTime now,
  }) {
    return CustomersCompanion.insert(
      id: customer.id,
      shopId: shopId,
      name: customer.name,
      address: Value(customer.address),
      contact: Value(customer.contact),
      suspicionFlag: Value(customer.suspicionFlag),
      isBlocked: Value(customer.isBlocked),
      createdAt: now,
      updatedAt: now,
      syncedAt: now,
    );
  }
}
