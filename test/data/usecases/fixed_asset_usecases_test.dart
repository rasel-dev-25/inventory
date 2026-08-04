import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/fixed_asset_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late FixedAssetUseCases useCases;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCases = FixedAssetUseCases(db);

    await ProductUseCases(db).create(
      Product(
        id: 'attar-bottle',
        name: 'Attar Showpiece Bottle',
        category: 'Attar',
        costPrice: Money.fromMinor(50000),
        suggestedSellPrice: Money.fromMinor(80000),
        qty: 5,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('createFromCashPurchase', () {
    test(
      'writes the asset and a matching negative cash ledger entry',
      () async {
        final result = await useCases.createFromCashPurchase(
          name: 'Display Showcase',
          value: Money.fromMinor(1500000),
          dateAcquired: DateTime.utc(2026, 1, 1),
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );

        expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

        final assets = await (db.select(db.fixedAssets)).get();
        expect(assets, hasLength(1));
        expect(assets.single.sourceType, FixedAssetSource.shopCashPurchase);
        expect(assets.single.sourceProductId, isNull);
        expect(assets.single.valueMinor, 1500000);

        final ledgerEntries = await (db.select(
          db.cashLedgerEntries,
        )..where((l) => l.sourceType.equals('fixed_asset'))).get();
        expect(ledgerEntries, hasLength(1));
        expect(ledgerEntries.single.amountMinor, -1500000);

        final pending = await db.syncMetadataDao.pendingEntries();
        final entry = pending.firstWhere(
          (e) => e.eventType == 'fixed_asset_purchased',
        );
        final upserts = OutboxEvent.decodePayload(entry.payloadJson);
        expect(upserts.map((u) => u.table).toList(), [
          'fixed_assets',
          'cash_ledger_entries',
        ]);
      },
    );

    test('rejects an empty name', () async {
      final result = await useCases.createFromCashPurchase(
        name: '  ',
        value: Money.fromMinor(1000),
        dateAcquired: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects a zero or negative value', () async {
      final result = await useCases.createFromCashPurchase(
        name: 'Fan',
        value: Money.zero(),
        dateAcquired: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await (db.select(db.fixedAssets)).get(), isEmpty);
    });
  });

  group('createFromStock', () {
    test(
      'decreases product qty, writes a negative stock movement, and no cash entry',
      () async {
        final result = await useCases.createFromStock(
          productId: 'attar-bottle',
          qty: 1,
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );

        expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

        final product = await db.productDao.getById('attar-bottle');
        expect(product!.qty, 4);

        final assets = await (db.select(db.fixedAssets)).get();
        expect(assets, hasLength(1));
        expect(assets.single.sourceType, FixedAssetSource.convertedFromStock);
        expect(assets.single.sourceProductId, 'attar-bottle');
        expect(
          assets.single.valueMinor,
          50000,
          reason: 'costPrice (500) * qty (1) = 500 = 50000 paisa',
        );
        expect(
          assets.single.name,
          'Attar Showpiece Bottle',
          reason: 'defaults to the product name when none is given',
        );

        final movements = await (db.select(
          db.stockMovements,
        )..where((m) => m.sourceType.equals('fixed_asset'))).get();
        expect(movements, hasLength(1));
        expect(movements.single.deltaQty, -1);

        expect(
          await (db.select(db.cashLedgerEntries)).get(),
          isEmpty,
          reason: 'converting from stock has zero cash impact',
        );

        final pending = await db.syncMetadataDao.pendingEntries();
        final entry = pending.firstWhere(
          (e) => e.eventType == 'fixed_asset_converted_from_stock',
        );
        final upserts = OutboxEvent.decodePayload(entry.payloadJson);
        expect(upserts.map((u) => u.table).toList(), [
          'fixed_assets',
          'stock_movements',
        ]);
      },
    );

    test('an explicit name overrides the product-name default', () async {
      final result = await useCases.createFromStock(
        productId: 'attar-bottle',
        qty: 1,
        name: 'Decorative Bottle',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue);
      final asset = (await (db.select(db.fixedAssets)).get()).single;
      expect(asset.name, 'Decorative Bottle');
    });

    test('rejects converting more than the available stock', () async {
      final result = await useCases.createFromStock(
        productId: 'attar-bottle',
        qty: 999,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<BusinessRuleFailure>());
      expect(await (db.select(db.fixedAssets)).get(), isEmpty);
    });

    test('rejects a zero or negative quantity', () async {
      final result = await useCases.createFromStock(
        productId: 'attar-bottle',
        qty: 0,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects a nonexistent product', () async {
      final result = await useCases.createFromStock(
        productId: 'does-not-exist',
        qty: 1,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
