import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'purchase_dao.g.dart';

@DriftAccessor(tables: [Purchases, PurchaseItems, TransportCosts, OtherCosts])
class PurchaseDao extends DatabaseAccessor<AppDatabase> with _$PurchaseDaoMixin {
  PurchaseDao(super.db);

  Future<List<Purchase>> getAll() => select(purchases).get();

  Stream<List<Purchase>> watchAll() => select(purchases).watch();

  Future<Purchase?> getById(String id) {
    return (select(purchases)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertPurchase(PurchasesCompanion entry) => into(purchases).insert(entry);

  Future<void> updatePurchase(String id, PurchasesCompanion entry) {
    return (update(purchases)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deletePurchase(String id) async {
    await (delete(purchaseItems)..where((t) => t.purchaseId.equals(id))).go();
    await (delete(transportCosts)..where((t) => t.purchaseId.equals(id))).go();
    await (delete(otherCosts)..where((t) => t.purchaseId.equals(id))).go();
    await (delete(purchases)..where((t) => t.id.equals(id))).go();
  }

  // Items
  Future<List<PurchaseItem>> getItems(String purchaseId) {
    return (select(purchaseItems)..where((t) => t.purchaseId.equals(purchaseId))).get();
  }

  Future<void> addItem(PurchaseItemsCompanion entry) => into(purchaseItems).insert(entry);

  // Transport
  Future<List<TransportCost>> getTransport(String purchaseId) {
    return (select(transportCosts)..where((t) => t.purchaseId.equals(purchaseId))).get();
  }

  Future<void> addTransport(TransportCostsCompanion entry) => into(transportCosts).insert(entry);

  // Other costs
  Future<List<OtherCost>> getOtherCosts(String purchaseId) {
    return (select(otherCosts)..where((t) => t.purchaseId.equals(purchaseId))).get();
  }

  Future<void> addOtherCost(OtherCostsCompanion entry) => into(otherCosts).insert(entry);
}
