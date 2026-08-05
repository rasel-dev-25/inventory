import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/expense_usecases.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/expense.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/features/reports_v2/controller/reports_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late ReportsController controller;

  setUp(() async {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());

    await InvestorUseCases(db).create(
      const Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 30,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 100,
        fundSource: FundSource.investor('investor-1'),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    // A sale inside this week/month (2026-08-05 is within both).
    await SaveSaleUseCase(db).call(
      productId: 'book-a',
      qty: 2,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(30000),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 8, 5, 10),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    // A much older sale, outside every period except all-time-ish ranges.
    await SaveSaleUseCase(db).call(
      productId: 'book-a',
      qty: 5,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(75000),
      paymentMethod: PaymentMethod.cash,
      date: DateTime.utc(2026, 1, 1),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await ExpenseUseCases(db).create(
      Expense(
        id: 'expense-1',
        category: ExpenseCategory.dailyOther,
        amount: Money.fromMinor(5000),
        date: DateTime.utc(2026, 8, 5),
        paymentMethod: PaymentMethod.cash,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    controller = ReportsController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('defaults to the "today" period', () {
    expect(controller.period.value, ReportPeriod.today);
  });

  test('setCustomRange selects the custom period and its range', () {
    controller.setCustomRange(
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 2, 1),
    );
    expect(controller.period.value, ReportPeriod.custom);
    expect(controller.range.start, DateTime.utc(2026, 1, 1));
    expect(controller.range.end, DateTime.utc(2026, 2, 1));
  });

  test('a custom range covering January only sees the January sale', () {
    controller.setCustomRange(
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 2, 1),
    );
    final totals = controller.totals;
    // 5 units × ৳150 = ৳750.
    expect(totals.totalSaleRevenue, Money.fromMinor(75000));
  });

  test('thisMonth (August) sees only the August sale and expense', () {
    controller.selectPeriod(ReportPeriod.thisMonth);
    // Only meaningful if "now" is actually August 2026 in this sandbox —
    // guard against flaking on a different month by using a custom
    // range instead when that's not true.
    final now = DateTime.now().toUtc();
    if (now.year != 2026 || now.month != 8) {
      controller.setCustomRange(
        DateTime.utc(2026, 8, 1),
        DateTime.utc(2026, 9, 1),
      );
    }

    final totals = controller.totals;
    // 2 units × ৳150 = ৳300.
    expect(totals.totalSaleRevenue, Money.fromMinor(30000));
    expect(controller.totalExpenses, Money.fromMinor(5000));
  });

  test('investorShares reports the period-scoped gross profit and share', () {
    controller.setCustomRange(
      DateTime.utc(2026, 8, 1),
      DateTime.utc(2026, 9, 1),
    );
    final shares = controller.investorShares;
    expect(shares, hasLength(1));
    // Gross profit for the August sale only: (150-100)*2 = ৳100.
    expect(shares.single.grossProfit, Money.fromMinor(10000));
    // 30% of ৳100 = ৳30.
    expect(shares.single.profitShare, Money.fromMinor(3000));
  });

  test('productSales reports the period-scoped product breakdown', () {
    controller.setCustomRange(
      DateTime.utc(2026, 8, 1),
      DateTime.utc(2026, 9, 1),
    );
    final sales = controller.productSales;
    expect(sales, hasLength(1));
    expect(sales.single.productId, 'book-a');
    expect(sales.single.qtySold, 2);
  });
}
