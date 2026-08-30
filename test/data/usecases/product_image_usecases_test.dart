import 'dart:io';

import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/product_image_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDirectory;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = await Directory.systemTemp.createTemp('product-image-test');
  });

  tearDown(() async {
    await db.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'add stores the local image and queues metadata plus binary upload',
    () async {
      final now = DateTime.utc(2026, 8, 18);
      await ProductUseCases(db).create(
        Product(
          id: 'product-1',
          name: 'Notebook',
          category: 'Book',
          costPrice: Money.fromMinor(5000),
          suggestedSellPrice: Money.fromMinor(7000),
          qty: 0,
          fundSource: FundSource.shop(),
        ),
        shopId: defaultShopId,
        now: now,
      );
      final photo = File(
        '${tempDirectory.path}${Platform.pathSeparator}photo.jpg',
      );
      await photo.writeAsBytes([1, 2, 3]);

      final imageId = await ProductImageUseCases(
        db,
      ).add(productId: 'product-1', localPath: photo.path, now: now);

      final image = await db.productImageDao.getById(imageId);
      expect(image?.localPath, photo.path);
      expect(image?.remoteUrl, isNull);

      final uploads = await db.syncMetadataDao.pendingUploads();
      expect(uploads, hasLength(1));
      expect(uploads.single.entityId, imageId);
      expect(uploads.single.bucketName, ProductImageUseCases.bucketName);
      expect(uploads.single.storagePath, startsWith('product-1/$imageId'));

      final outbox = await db.syncMetadataDao.pendingEntries();
      final imageEvent = outbox.firstWhere(
        (entry) => entry.eventType == 'product_image_created',
      );
      final row = OutboxEvent.decodePayload(imageEvent.payloadJson).single.row;
      expect(row['product_id'], 'product-1');
      expect(row.containsKey('local_path'), isFalse);
    },
  );
}
