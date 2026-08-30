import 'dart:io';

import 'package:drift/native.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/pending_upload_service.dart';
import 'package:inventory/data/sync/storage_upload_transport.dart';
import 'package:inventory/data/usecases/product_image_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/customer_image_usecases.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/fixed_asset_image_usecases.dart';
import 'package:inventory/data/usecases/fixed_asset_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

class _FakeStorageTransport implements StorageUploadTransport {
  Result<void> uploadResult = const Result.ok(null);
  final uploadedPaths = <String>[];

  @override
  Future<Result<void>> upload({
    required String bucketName,
    required String storagePath,
    required String localPath,
  }) async {
    uploadedPaths.add(storagePath);
    return uploadResult;
  }

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  }) async => Result.ok('https://example.test/$storagePath');
}

void main() {
  late AppDatabase db;
  late Directory tempDirectory;
  late _FakeStorageTransport transport;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = await Directory.systemTemp.createTemp('upload-test');
    transport = _FakeStorageTransport();
  });

  tearDown(() async {
    await db.close();
    await tempDirectory.delete(recursive: true);
  });

  Future<String> seedImage() async {
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
    return ProductImageUseCases(
      db,
    ).add(productId: 'product-1', localPath: photo.path, now: now);
  }

  test(
    'successful upload updates image metadata and completes the queue',
    () async {
      final imageId = await seedImage();
      final service = PendingUploadService(db, db.syncMetadataDao, transport);

      final summary = await service.uploadPending();

      expect(summary.succeeded, 1);
      expect(summary.failed, 0);
      expect(transport.uploadedPaths, hasLength(1));
      final image = await db.productImageDao.getById(imageId);
      expect(image?.remoteUrl, transport.uploadedPaths.single);
      expect(await db.syncMetadataDao.pendingUploads(), isEmpty);
      final outbox = await db.syncMetadataDao.pendingEntries();
      expect(
        outbox.any((entry) => entry.eventType == 'product_image_uploaded'),
        isTrue,
      );
    },
  );

  test('customer image upload updates remote metadata', () async {
    final now = DateTime.utc(2026, 8, 18);
    await CustomerUseCases(db).create(
      const Customer(id: 'customer-1', name: 'Karim'),
      shopId: defaultShopId,
      now: now,
    );
    final photo = File(
      '${tempDirectory.path}${Platform.pathSeparator}customer.jpg',
    );
    await photo.writeAsBytes([1, 2, 3]);
    final imageId = await CustomerImageUseCases(
      db,
    ).add(customerId: 'customer-1', localPath: photo.path, now: now);

    final service = PendingUploadService(db, db.syncMetadataDao, transport);
    final summary = await service.uploadPending();

    expect(summary.succeeded, 1);
    final image = await db.customerImageDao.getById(imageId);
    expect(image?.remoteUrl, transport.uploadedPaths.single);
    expect(await db.syncMetadataDao.pendingUploads(), isEmpty);
    final outbox = await db.syncMetadataDao.pendingEntries();
    expect(
      outbox.any((entry) => entry.eventType == 'customer_image_uploaded'),
      isTrue,
    );
  });

  test('fixed asset image upload updates remote metadata', () async {
    final now = DateTime.utc(2026, 8, 18);
    final assetId = (await FixedAssetUseCases(db).createFromCashPurchase(
      name: 'Showcase',
      value: Money.fromMinor(100000),
      dateAcquired: now,
      shopId: defaultShopId,
      now: now,
    )).unwrap();
    final photo = File(
      '${tempDirectory.path}${Platform.pathSeparator}asset.jpg',
    );
    await photo.writeAsBytes([1, 2, 3]);
    final imageId = await FixedAssetImageUseCases(
      db,
    ).add(assetId: assetId, localPath: photo.path, now: now);

    final service = PendingUploadService(db, db.syncMetadataDao, transport);
    final summary = await service.uploadPending();

    expect(summary.succeeded, 1);
    final image = await db.fixedAssetImageDao.getById(imageId);
    expect(image?.remoteUrl, transport.uploadedPaths.single);
    expect(await db.syncMetadataDao.pendingUploads(), isEmpty);
    final outbox = await db.syncMetadataDao.pendingEntries();
    expect(
      outbox.any((entry) => entry.eventType == 'fixed_asset_image_uploaded'),
      isTrue,
    );
  });
}
