import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/customer_image_usecases.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:test/test.dart';

void main() {
  test('add stores customer image metadata and queues its upload', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 18);
    await CustomerUseCases(db).create(
      const Customer(id: 'customer-1', name: 'Karim'),
      shopId: defaultShopId,
      now: now,
    );

    final imageId = await CustomerImageUseCases(db).add(
      customerId: 'customer-1',
      localPath: 'customer_images/karim.jpg',
      now: now,
    );

    final image = await db.customerImageDao.getById(imageId);
    expect(image?.customerId, 'customer-1');
    expect(image?.localPath, 'customer_images/karim.jpg');
    final uploads = await db.syncMetadataDao.pendingUploads();
    expect(uploads, hasLength(1));
    expect(uploads.single.bucketName, CustomerImageUseCases.bucketName);
    expect(uploads.single.entityType, 'customer_image');
    expect(uploads.single.storagePath, startsWith('customer-1/$imageId'));

    final outbox = await db.syncMetadataDao.pendingEntries();
    final event = outbox.firstWhere(
      (entry) => entry.eventType == 'customer_image_created',
    );
    final upserts = OutboxEvent.decodePayload(event.payloadJson);
    expect(upserts.single.table, 'customer_images');
    expect(upserts.single.row['customer_id'], 'customer-1');
  });
}
