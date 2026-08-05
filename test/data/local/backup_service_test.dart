import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/backup_service.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:test/test.dart';

void main() {
  // This file deliberately opens two independent in-memory `AppDatabaseV2`
  // instances at once (a source and a restore target) to prove a backup
  // genuinely round-trips across separate databases, not just within one
  // — exactly the case drift's own "opened multiple times" warning
  // suggests silencing when it's intentional.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabaseV2 sourceDb;
  final now = DateTime.now().toUtc();

  setUp(() async {
    sourceDb = AppDatabaseV2.forTesting(NativeDatabase.memory());

    await InvestorUseCases(sourceDb).create(
      const Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 30,
      ),
      shopId: defaultShopId,
      now: now,
    );

    await ProductUseCases(sourceDb).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 0,
        fundSource: FundSource.investor('investor-1'),
      ),
      shopId: defaultShopId,
      now: now,
    );

    await SavePurchaseTripUseCase(sourceDb).call(
      PurchaseTrip(
        id: 'trip-1',
        date: now,
        transportCost: Money.fromMinor(5000),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Mokam',
            productId: 'book-a',
            qty: 10,
            unitPrice: Money.fromMinor(10000),
            fundSource: FundSource.investor('investor-1'),
          ),
        ],
      ),
      shopId: defaultShopId,
      now: now,
    );

    await SaveSaleUseCase(sourceDb).call(
      productId: 'book-a',
      qty: 3,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(45000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );

    await ExpenseUseCases(sourceDb).create(
      Expense(
        id: 'expense-1',
        category: ExpenseCategory.dailyOther,
        amount: Money.fromMinor(20000),
        date: now,
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: now,
    );
  });

  tearDown(() async {
    await sourceDb.close();
  });

  test(
    'buildBackupPayload includes every seeded table with real rows',
    () async {
      final payload = await BackupService(sourceDb).buildBackupPayload();

      expect(payload['version'], BackupService.currentVersion);
      final tables = payload['tables'] as Map<String, dynamic>;
      expect((tables['investors'] as List), hasLength(1));
      expect((tables['products'] as List), hasLength(1));
      expect((tables['purchase_trips'] as List), hasLength(1));
      expect((tables['purchase_items'] as List), hasLength(1));
      expect((tables['sales'] as List), hasLength(1));
      expect((tables['expenses'] as List), hasLength(1));
      expect((tables['cash_ledger_entries'] as List), isNotEmpty);
      expect((tables['stock_movements'] as List), isNotEmpty);
    },
  );

  test(
    'restoring a backup onto a completely different, fresh database reproduces every row',
    () async {
      final payload = await BackupService(sourceDb).buildBackupPayload();
      final targetDb = AppDatabaseV2.forTesting(NativeDatabase.memory());

      final result = await BackupService(targetDb).restoreFromBackup(payload);

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final product = await targetDb.productDao.getById('book-a');
      expect(product, isNotNull);
      expect(product!.name, 'Book A');
      // 10 bought, 3 sold — both stock movements must have restored.
      expect(product.qty, 7);

      final investor = await targetDb.investorDao.getById('investor-1');
      expect(investor, isNotNull);
      expect(investor!.name, 'Uncle Karim');

      final sales = await targetDb.saleDao.watchAll(defaultShopId).first;
      expect(sales, hasLength(1));
      expect(sales.single.qty, 3);

      final expenses = await targetDb.expenseDao.watchAll(defaultShopId).first;
      expect(expenses, hasLength(1));

      await targetDb.close();
    },
  );

  test(
    'restoring replaces existing data rather than merging with it',
    () async {
      final payload = await BackupService(sourceDb).buildBackupPayload();
      final targetDb = AppDatabaseV2.forTesting(NativeDatabase.memory());

      // The target already has its own, completely different investor
      // before the restore.
      await InvestorUseCases(targetDb).create(
        const Investor(
          id: 'pre-existing-investor',
          name: 'Should Be Gone After Restore',
          investmentType: InvestmentType.cashLoan,
        ),
        shopId: defaultShopId,
        now: now,
      );

      final result = await BackupService(targetDb).restoreFromBackup(payload);
      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

      final preExisting = await targetDb.investorDao.getById(
        'pre-existing-investor',
      );
      expect(preExisting, isNull);
      final restored = await targetDb.investorDao.getById('investor-1');
      expect(restored, isNotNull);

      await targetDb.close();
    },
  );

  test('rejects a payload with an unrecognized version', () async {
    final targetDb = AppDatabaseV2.forTesting(NativeDatabase.memory());
    final result = await BackupService(
      targetDb,
    ).restoreFromBackup({'version': 999, 'tables': <String, dynamic>{}});

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    await targetDb.close();
  });

  test('rejects a payload with no "tables" map', () async {
    final targetDb = AppDatabaseV2.forTesting(NativeDatabase.memory());
    final result = await BackupService(
      targetDb,
    ).restoreFromBackup({'version': BackupService.currentVersion});

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    await targetDb.close();
  });

  test(
    'a failure partway through leaves the target database completely unchanged (crash-safety)',
    () async {
      final payload = await BackupService(sourceDb).buildBackupPayload();
      final targetDb = AppDatabaseV2.forTesting(NativeDatabase.memory());

      // The target starts with its own investor already in place.
      await InvestorUseCases(targetDb).create(
        const Investor(
          id: 'original-investor',
          name: 'Original Investor',
          investmentType: InvestmentType.cashLoan,
        ),
        shopId: defaultShopId,
        now: now,
      );

      // Corrupt a table that's restored *after* investors/products in
      // the topological order (sales), so if the transaction were not
      // atomic, investors/products would already show the new data by
      // the time this failure happens.
      final corrupted = Map<String, dynamic>.from(payload);
      final tables = Map<String, dynamic>.from(
        corrupted['tables'] as Map<String, dynamic>,
      );
      tables['sales'] = [
        {'not': 'a valid sale row'},
      ];
      corrupted['tables'] = tables;

      final result = await BackupService(targetDb).restoreFromBackup(corrupted);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());

      // The whole transaction must have rolled back — the original
      // investor is still there, and the backup's investor never landed.
      final original = await targetDb.investorDao.getById('original-investor');
      expect(original, isNotNull);
      final fromBackup = await targetDb.investorDao.getById('investor-1');
      expect(fromBackup, isNull);

      await targetDb.close();
    },
  );
}
