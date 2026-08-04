import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/stock_v2/controller/stock_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late StockController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    final now = DateTime.now().toUtc();

    await db.investorDao.create(
      const Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
      ),
      shopId: defaultShopId,
      now: now,
    );

    final productUseCases = ProductUseCases(db);
    // Shop-funded, well-selling book: cost 100, sell 150, qty 8 left.
    await productUseCases.create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 8,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: now,
    );
    // Investor-funded, never sold: cost 200, sell 300, qty 5.
    await productUseCases.create(
      Product(
        id: 'book-b',
        name: 'Book B',
        category: 'Book',
        costPrice: Money.fromMinor(20000),
        suggestedSellPrice: Money.fromMinor(30000),
        qty: 5,
        fundSource: FundSource.investor('investor-1'),
      ),
      shopId: defaultShopId,
      now: now,
    );
    // Different category, shop-funded, never sold: cost 50, sell 80, qty 3.
    await productUseCases.create(
      Product(
        id: 'date-a',
        name: 'Date A',
        category: 'Date',
        costPrice: Money.fromMinor(5000),
        suggestedSellPrice: Money.fromMinor(8000),
        qty: 3,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: now,
    );

    // Two sale movements against book-a (3 + 2 units sold, all-time).
    await db.ledgerDao.recordStockMovement(
      id: 'move-1',
      shopId: defaultShopId,
      productId: 'book-a',
      deltaQty: -3,
      sourceType: 'sale',
      sourceId: 'sale-1',
      date: now,
      now: now,
    );
    await db.ledgerDao.recordStockMovement(
      id: 'move-2',
      shopId: defaultShopId,
      productId: 'book-a',
      deltaQty: -2,
      sourceType: 'sale',
      sourceId: 'sale-2',
      date: now,
      now: now,
    );
    // A non-sale movement (a purchase) must not count toward "sold qty".
    await db.ledgerDao.recordStockMovement(
      id: 'move-3',
      shopId: defaultShopId,
      productId: 'date-a',
      deltaQty: 3,
      sourceType: 'purchase',
      date: now,
      now: now,
    );

    controller = StockController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('loads products, categories, and investors', () {
    expect(controller.products.map((p) => p.id).toSet(), {
      'book-a',
      'book-b',
      'date-a',
    });
    expect(
      controller.categories.map((c) => c.name),
      containsAll(['Book', 'Date']),
    );
    expect(controller.investors.single.name, 'Uncle Karim');
  });

  test('totals sum cost/sale value across all products with no filter', () {
    // cost: 8*100 + 5*200 + 3*50 = 800+1000+150 = 1950
    expect(controller.totalCostValue, Money.fromMinor(195000));
    // sale: 8*150 + 5*300 + 3*80 = 1200+1500+240 = 2940
    expect(controller.potentialSaleValue, Money.fromMinor(294000));
    expect(controller.potentialProfit, Money.fromMinor(99000));
  });

  test('category filter narrows both the product list and the totals', () {
    controller.selectedCategory.value = 'Date';
    expect(controller.filteredProducts.map((p) => p.id).toList(), ['date-a']);
    expect(controller.totalCostValue, Money.fromMinor(15000));
  });

  test('fund-source filter distinguishes shop from a specific investor', () {
    controller.selectedFundFilter.value = shopFundFilterValue;
    expect(controller.filteredProducts.map((p) => p.id).toSet(), {
      'book-a',
      'date-a',
    });

    controller.selectedFundFilter.value = 'investor-1';
    expect(controller.filteredProducts.map((p) => p.id).toList(), ['book-b']);
  });

  test('soldQtyByProduct only counts sale-sourced movements', () {
    final sold = controller.soldQtyByProduct;
    expect(sold['book-a'], 5);
    expect(sold.containsKey('date-a'), isFalse);
    expect(sold.containsKey('book-b'), isFalse);
  });

  test(
    'topSellers surfaces products with sales, slowMovers surfaces zero-sale stock',
    () {
      expect(controller.topSellers.map((p) => p.id).toList(), ['book-a']);
      expect(controller.slowMovers.map((p) => p.id).toSet(), {
        'book-b',
        'date-a',
      });
    },
  );

  test('investorName resolves a known id and falls back to the id itself', () {
    expect(controller.investorName('investor-1'), 'Uncle Karim');
    expect(controller.investorName('does-not-exist'), 'does-not-exist');
  });
}
