import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../domain/entities/customer.dart' as domain;
import '../tables/customers.dart';

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
@DriftAccessor(tables: [Customers])
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
