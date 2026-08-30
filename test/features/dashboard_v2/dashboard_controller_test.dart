import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/features/dashboard_v2/controller/dashboard_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late DashboardController controller;

  final today = DateTime.now().toUtc();
  final twoDaysAgo = today.subtract(const Duration(days: 2));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 0,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: today,
    );

    // A purchase trip today: +10 units @ ৳100, all shop-funded — cash out
    // ৳1000, stock +10.
    await SavePurchaseTripUseCase(db).call(
      PurchaseTrip(
        id: 'trip-1',
        date: today,
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: 'item-1',
            shopName: 'Mokam',
            productId: 'book-a',
            qty: 10,
            unitPrice: Money.fromMinor(10000),
            fundSource: FundSource.shop(),
          ),
        ],
      ),
      shopId: defaultShopId,
      now: today,
    );

    // A full-cash sale today: 4 units @ ৳150 — revenue ৳600, gross profit
    // ৳200 ((150-100)*4), cash in ৳600, stock -4.
    await SaveSaleUseCase(db).call(
      productId: 'book-a',
      qty: 4,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(60000),
      paymentMethod: PaymentMethod.cash,
      date: today,
      shopId: defaultShopId,
      now: today,
    );

    // A full-cash sale two days ago: 1 unit @ ৳150 — revenue ৳150, gross
    // profit ৳50, cash in ৳150, stock -1. Day view must exclude this;
    // All-time view must include it.
    await SaveSaleUseCase(db).call(
      productId: 'book-a',
      qty: 1,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(15000),
      paymentMethod: PaymentMethod.cash,
      date: twoDaysAgo,
      shopId: defaultShopId,
      now: twoDaysAgo,
    );

    // An expense today: ৳100 monthly rent — cash out ৳100, reduces
    // netProfit by the same amount now that the Expense module exists.
    await ExpenseUseCases(db).create(
      Expense(
        id: 'expense-1',
        category: ExpenseCategory.monthlyRent,
        amount: Money.fromMinor(10000),
        date: today,
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: today,
    );

    controller = DashboardController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('defaults to Day view', () {
    expect(controller.isDayView.value, isTrue);
  });

  test(
    'Day view only counts today\'s trip, sale, and expense, not the older sale',
    () {
      final totals = controller.totals;
      // cash: -1000 (purchase) + 600 (today's sale) - 100 (expense) = -500.
      expect(totals.totalCash, Money.fromMinor(-50000));
      expect(totals.totalSaleRevenue, Money.fromMinor(60000));
      expect(totals.totalPurchaseCashOut, Money.fromMinor(100000));
      // netProfit = grossProfit(200) - expenses(100) = 100 — now real net
      // profit, not gross-profit-only, since the Expense module exists.
      expect(totals.netProfit, Money.fromMinor(10000));
      // net movement today: +10 - 4 = 6 units at current cost 100 = 600.
      expect(totals.stockValue, Money.fromMinor(60000));
    },
  );

  test('selectDay shows the selected historical day and keeps day mode', () {
    controller.selectDay(twoDaysAgo);

    expect(controller.isDayView.value, isTrue);
    expect(controller.selectedDay.value, twoDaysAgo);
    expect(controller.totals.totalSaleRevenue, Money.fromMinor(15000));
    expect(controller.totals.netProfit, Money.fromMinor(5000));
  });

  test('All-time view folds in the older sale too, expense unaffected', () {
    controller.toggleView();
    expect(controller.isDayView.value, isFalse);

    final totals = controller.totals;
    // cash: -1000 + 600 + 150 - 100 = -350.
    expect(totals.totalCash, Money.fromMinor(-35000));
    expect(totals.totalSaleRevenue, Money.fromMinor(75000));
    expect(totals.totalPurchaseCashOut, Money.fromMinor(100000));
    // netProfit = grossProfit(200+50=250) - expenses(100) = 150.
    expect(totals.netProfit, Money.fromMinor(15000));
    // all-time net movement (+10-4-1=5) at current cost 100 = 500 — exactly
    // today's on-hand qty (5) * cost price, confirming the identity
    // dashboard_calculator.dart's doc comment describes.
    expect(totals.stockValue, Money.fromMinor(50000));

    final product = controller.products.firstWhere((p) => p.id == 'book-a');
    expect(product.qty, 5);
  });
}
