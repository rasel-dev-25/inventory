import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'sale_dao.g.dart';

@DriftAccessor(tables: [Sales])
class SaleDao extends DatabaseAccessor<AppDatabase> with _$SaleDaoMixin {
  SaleDao(super.db);

  Future<List<Sale>> getAll() => select(sales).get();

  Stream<List<Sale>> watchAll() => select(sales).watch();

  Future<List<Sale>> getByDate(String date) {
    return (select(sales)..where((t) => t.date.equals(date))).get();
  }

  Future<void> insertSale(SalesCompanion entry) => into(sales).insert(entry);

  Future<void> updateSale(String id, SalesCompanion entry) {
    return (update(sales)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteSale(String id) {
    return (delete(sales)..where((t) => t.id.equals(id))).go();
  }

  Future<double> totalCash() async {
    final result = await (selectOnly(
      sales,
    )..addColumns([sales.amount.sum()])).getSingle();
    return result.read(sales.amount.sum()) ?? 0.0;
  }

  Future<double> totalProfit() async {
    final result = await (selectOnly(
      sales,
    )..addColumns([sales.profit.sum()])).getSingle();
    return result.read(sales.profit.sum()) ?? 0.0;
  }
}
