import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<Product>> getAll() => select(products).get();

  Stream<List<Product>> watchAll() => select(products).watch();

  Future<List<Product>> getByCategory(String category) {
    return (select(products)..where((t) => t.category.equals(category))).get();
  }

  Future<List<Product>> getByInvestor(String investor) {
    return (select(products)..where((t) => t.investor.equals(investor))).get();
  }

  Future<Product?> getById(String id) {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<void> updateProduct(String id, ProductsCompanion entry) {
    return (update(products)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteProduct(String id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateQty(String id, double newQty) {
    return (update(products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(qty: Value(newQty)),
    );
  }

  // Categories
  Future<List<Category>> getCategories() => select(categories).get();

  Future<void> addCategory(String name) =>
      into(categories).insert(CategoriesCompanion.insert(name: name));

  Future<void> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }
}
