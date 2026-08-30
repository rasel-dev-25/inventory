import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/local/local_row_upserter.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pulling product image metadata preserves its device-local path',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
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
      await db.productImageDao.create(
        ProductImagesCompanion.insert(
          id: 'image-1',
          productId: 'product-1',
          localPath: const Value('product_images/local.jpg'),
          createdAt: now,
          syncedAt: now,
        ),
      );

      await LocalRowUpserter(db).upsert('product_images', {
        'id': 'image-1',
        'product_id': 'product-1',
        'local_path': null,
        'remote_url': 'product-1/image-1.jpg',
        'sort_order': 0,
        'created_at': now.toIso8601String(),
        'synced_at': now.add(const Duration(minutes: 1)).toIso8601String(),
      });

      final image = await db.productImageDao.getById('image-1');
      expect(image?.localPath, 'product_images/local.jpg');
      expect(image?.remoteUrl, 'product-1/image-1.jpg');
    },
  );
}
