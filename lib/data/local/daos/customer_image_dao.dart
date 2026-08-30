import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers.dart';

part 'customer_image_dao.g.dart';

@DriftAccessor(tables: [CustomerImages, Customers])
class CustomerImageDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerImageDaoMixin {
  CustomerImageDao(super.db);

  Stream<List<CustomerImageRow>> watchForShop(String shopId) {
    final query =
        select(customerImages).join([
            innerJoin(
              customers,
              customers.id.equalsExp(customerImages.customerId),
            ),
          ])
          ..where(
            customers.shopId.equals(shopId) & customers.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.desc(customerImages.createdAt),
            OrderingTerm.asc(customerImages.sortOrder),
          ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(customerImages)).toList(),
    );
  }

  Future<CustomerImageRow?> getById(String id) {
    return (select(
      customerImages,
    )..where((image) => image.id.equals(id))).getSingleOrNull();
  }

  Future<void> create(CustomerImagesCompanion image) {
    return into(customerImages).insert(image);
  }

  Future<void> markUploaded({
    required String id,
    required String remoteUrl,
    required DateTime syncedAt,
  }) {
    return (update(
      customerImages,
    )..where((image) => image.id.equals(id))).write(
      CustomerImagesCompanion(
        remoteUrl: Value(remoteUrl),
        syncedAt: Value(syncedAt),
      ),
    );
  }
}
