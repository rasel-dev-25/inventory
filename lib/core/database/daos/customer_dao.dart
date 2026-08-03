import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers, LedgerEntries, CustomerPurchases, CustomerOrders, CustomerTypes])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Future<List<Customer>> getAll() => select(customers).get();

  Stream<List<Customer>> watchAll() => select(customers).watch();

  Future<List<Customer>> getByType(String type) {
    return (select(customers)..where((t) => t.type.equals(type))).get();
  }

  Future<Customer?> getById(String id) {
    return (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertCustomer(CustomersCompanion entry) => into(customers).insert(entry);

  Future<void> updateCustomer(String id, CustomersCompanion entry) {
    return (update(customers)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteCustomer(String id) async {
    await (delete(ledgerEntries)..where((t) => t.customerId.equals(id))).go();
    await (delete(customerPurchases)..where((t) => t.customerId.equals(id))).go();
    await (delete(customerOrders)..where((t) => t.customerId.equals(id))).go();
    await (delete(customers)..where((t) => t.id.equals(id))).go();
  }

  // Ledger
  Future<List<LedgerEntry>> getLedger(String customerId) {
    return (select(ledgerEntries)..where((t) => t.customerId.equals(customerId))).get();
  }

  Future<void> addLedgerEntry(LedgerEntriesCompanion entry) =>
      into(ledgerEntries).insert(entry);

  // Purchases
  Future<List<CustomerPurchase>> getPurchases(String customerId) {
    return (select(customerPurchases)..where((t) => t.customerId.equals(customerId))).get();
  }

  Future<void> addPurchase(CustomerPurchasesCompanion entry) =>
      into(customerPurchases).insert(entry);

  // Orders
  Future<List<CustomerOrder>> getOrders(String customerId) {
    return (select(customerOrders)..where((t) => t.customerId.equals(customerId))).get();
  }

  Future<void> addOrder(CustomerOrdersCompanion entry) =>
      into(customerOrders).insert(entry);

  Future<void> updateOrder(String id, CustomerOrdersCompanion entry) {
    return (update(customerOrders)..where((t) => t.id.equals(id))).write(entry);
  }

  // Customer Types
  Future<List<CustomerType>> getTypes() => select(customerTypes).get();

  Future<void> addType(CustomerTypesCompanion entry) =>
      into(customerTypes).insert(entry);

  Future<void> deleteType(String id) {
    return (delete(customerTypes)..where((t) => t.id.equals(id))).go();
  }
}
