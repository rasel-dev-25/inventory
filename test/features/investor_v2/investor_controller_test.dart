import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_purchase_trip_usecase.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/features/investor_v2/controller/investor_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late InvestorController controller;

  final now = DateTime.now().toUtc();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await InvestorUseCases(db).create(
      const Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 30,
      ),
      shopId: defaultShopId,
      now: now,
    );

    await ProductUseCases(db).create(
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

    // Investor-1 funds 10 units @ ৳100 — total investment ৳1000, all cash.
    await SavePurchaseTripUseCase(db).call(
      PurchaseTrip(
        id: 'trip-1',
        date: now,
        transportCost: Money.zero(),
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

    // Sell 4 units @ ৳150 — revenue ৳600, gross profit ৳200, so a 30%
    // share is ৳60.
    await SaveSaleUseCase(db).call(
      productId: 'book-a',
      qty: 4,
      actualSellPrice: Money.fromMinor(15000),
      amountReceivedNow: Money.fromMinor(60000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );

    controller = InvestorController(db);
    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    // Repay ৳300 of capital.
    final ok = await controller.recordRepayment(
      investorId: 'investor-1',
      amount: Money.fromMinor(30000),
      type: RepaymentType.capitalReturn,
      paymentMethod: PaymentMethod.cash,
    );
    expect(ok, isTrue);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('metricsFor computes every figure for the investor', () {
    final investor = controller.investors.single;
    final metrics = controller.metricsFor(investor);

    expect(metrics.totalInvestment, Money.fromMinor(100000));
    // (10 - 4) units left at cost ৳100 = ৳600.
    expect(metrics.currentStockValue, Money.fromMinor(60000));
    expect(metrics.totalPurchasedCash, Money.fromMinor(100000));
    expect(metrics.totalSoldRevenue, Money.fromMinor(60000));
    expect(metrics.profitShare, Money.fromMinor(6000));
    expect(metrics.totalRepaidCapital, Money.fromMinor(30000));
    expect(metrics.remainingBalance, Money.fromMinor(70000));
  });

  test('repaymentsFor lists the recorded repayment', () {
    final history = controller.repaymentsFor('investor-1');
    expect(history, hasLength(1));
    expect(history.single.amount, Money.fromMinor(30000));
    expect(history.single.type, RepaymentType.capitalReturn);
  });

  test('createInvestor adds a new investor visible to the list', () async {
    final newId = await controller.createInvestor(
      name: 'Auntie Rina',
      investmentType: InvestmentType.cashLoan,
      profitSharePercent: 0,
      profitPayoutCycle: ProfitPayoutCycle.monthly,
    );
    expect(newId, isNotNull);
    await Future<void>.delayed(Duration.zero);

    expect(controller.investors.map((i) => i.name), contains('Auntie Rina'));
  });

  group('legacy settlement (business_logic.md §৬)', () {
    test('settlementFor is null before any settlement is created', () {
      expect(controller.settlementFor('investor-1'), isNull);
    });

    test('createLegacySettlement makes it visible via settlementFor', () async {
      final ok = await controller.createLegacySettlement(
        investorId: 'investor-1',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.fromMinor(10000000),
        settlementDate: DateTime.utc(2026, 1, 1),
        notes: 'Old ledger book',
      );
      expect(ok, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      final settlement = controller.settlementFor('investor-1');
      expect(settlement, isNotNull);
      expect(settlement!.status, LegacySettlementStatus.pending);
      expect(settlement.netSettlementAmount, Money.fromMinor(40000000));
    });

    test('recordLegacySettlementPayment partially pays and updates remaining amount', () async {
      await controller.createLegacySettlement(
        investorId: 'investor-1',
        totalHistoricalInvestment: Money.fromMinor(5000000), // ৳50,000
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
        notes: 'Initial ledger balance',
      );
      await Future<void>.delayed(Duration.zero);
      final settlementId = controller.settlementFor('investor-1')!.id;

      // Partial payment of ৳20,000
      final ok = await controller.recordLegacySettlementPayment(
        settlementId: settlementId,
        paymentAmount: Money.fromMinor(2000000),
        note: 'Installment 1',
      );
      expect(ok, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      final updated = controller.settlementFor('investor-1')!;
      expect(updated.status, LegacySettlementStatus.pending);
      expect(updated.totalAlreadyReturned, Money.fromMinor(2000000));
      expect(updated.netSettlementAmount, Money.fromMinor(3000000)); // ৳30,000 left
      expect(updated.notes, contains('Installment 1'));

      // Pay remaining ৳30,000 -> Should automatically mark as settled!
      final ok2 = await controller.recordLegacySettlementPayment(
        settlementId: settlementId,
        paymentAmount: Money.fromMinor(3000000),
        note: 'Final settlement',
      );
      expect(ok2, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      final finalSettlement = controller.settlementFor('investor-1')!;
      expect(finalSettlement.status, LegacySettlementStatus.settled);
      expect(finalSettlement.netSettlementAmount, Money.zero());
      expect(finalSettlement.notes, contains('Final settlement'));
    });

    test('investorById and productsForInvestor return expected data', () {
      final inv = controller.investorById('investor-1');
      expect(inv, isNotNull);
      expect(inv!.name, 'Uncle Karim');

      final prods = controller.productsForInvestor('investor-1');
      expect(prods, hasLength(1));
      expect(prods.first.id, 'book-a');
    });

    test('markLegacySettlementSettled flips it to settled', () async {
      await controller.createLegacySettlement(
        investorId: 'investor-1',
        totalHistoricalInvestment: Money.fromMinor(50000000),
        totalAlreadyReturned: Money.zero(),
        settlementDate: DateTime.utc(2026, 1, 1),
      );
      await Future<void>.delayed(Duration.zero);
      final settlementId = controller.settlementFor('investor-1')!.id;

      final ok = await controller.markLegacySettlementSettled(settlementId);
      expect(ok, isTrue, reason: controller.errorMessage.value);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.settlementFor('investor-1')!.status,
        LegacySettlementStatus.settled,
      );
    });

    test('initialCashInvestment and addCashInvestment properly update investor capital', () async {
      final id = await controller.createInvestor(
        name: 'Sunny bhai',
        investmentType: InvestmentType.cashMudaraba,
        profitSharePercent: 40,
        profitPayoutCycle: ProfitPayoutCycle.monthly,
        initialCashInvestment: Money.fromMinor(10000000), // ৳100,000
      );
      expect(id, isNotNull);
      await Future<void>.delayed(Duration.zero);

      var inv = controller.investorById(id!)!;
      expect(inv.initialCashInvestment, Money.fromMinor(10000000));

      var metrics = controller.metricsFor(inv);
      expect(metrics.totalInvestment, Money.fromMinor(10000000));
      expect(metrics.remainingBalance, Money.fromMinor(10000000));

      // Add additional cash investment
      final added = await controller.addCashInvestment(
        investorId: id,
        amount: Money.fromMinor(2000000), // ৳20,000
        note: 'অতিরিক্ত মূলধন',
      );
      expect(added, isTrue);
      await Future<void>.delayed(Duration.zero);

      inv = controller.investorById(id)!;
      expect(inv.initialCashInvestment, Money.fromMinor(12000000)); // ৳120,000
      expect(inv.notes, contains('অতিরিক্ত মূলধন'));

      metrics = controller.metricsFor(inv);
      expect(metrics.totalInvestment, Money.fromMinor(12000000));
      expect(metrics.remainingBalance, Money.fromMinor(12000000));
    });
  });
}
