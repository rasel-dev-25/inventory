import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/local/local_row_upserter.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:test/test.dart';

void main() {
  test('pulling customer image metadata preserves its local path', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 18);
    await CustomerUseCases(db).create(
      const Customer(id: 'customer-1', name: 'Karim'),
      shopId: defaultShopId,
      now: now,
    );
    await db.customerImageDao.create(
      CustomerImagesCompanion.insert(
        id: 'image-1',
        customerId: 'customer-1',
        localPath: const Value('customer_images/local.jpg'),
        createdAt: now,
        syncedAt: now,
      ),
    );

    await LocalRowUpserter(db).upsert('customer_images', {
      'id': 'image-1',
      'customer_id': 'customer-1',
      'local_path': null,
      'remote_url': 'customer-1/image-1.jpg',
      'sort_order': 0,
      'created_at': now.toIso8601String(),
      'synced_at': now.add(const Duration(minutes: 1)).toIso8601String(),
    });

    final image = await db.customerImageDao.getById('image-1');
    expect(image?.localPath, 'customer_images/local.jpg');
    expect(image?.remoteUrl, 'customer-1/image-1.jpg');
  });
}
