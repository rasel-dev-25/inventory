import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../core/settings/settings_registry.dart';
import '../../../core/time/date_range.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/expense_usecases.dart';
import '../../../domain/entities/cash_ledger_entry.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/investor_repayment.dart';
import '../../../domain/entities/legacy_settlement.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/dashboard_calculator.dart';
import '../../../domain/services/investor_metrics.dart';

class InvestorObligationDetail {
  final Investor investor;
  final Money remainingBalance;
  final Money dailyObligation;
  final int? termDays;

  const InvestorObligationDetail({
    required this.investor,
    required this.remainingBalance,
    required this.dailyObligation,
    this.termDays,
  });
}

/// Backs the Dashboard screen — `notes/business_logic.md` §ঝ's Day
/// view (default, today) vs. All-time view toggle, both served by the
/// exact same [computeDashboardTotals] call with a different [DateRange],
/// per the spec's own implementation note. Embedded directly in
/// `ShellScreen` — see that class's own doc comment.
class DashboardController extends GetxController {
  final AppDatabase db;

  DashboardController(this.db);

  final products = <Product>[].obs;
  final ledgerEntries = <CashLedgerEntry>[].obs;
  final sales = <Sale>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final stockMovements = <StockMovementRow>[].obs;
  final expenses = <Expense>[].obs;
  final dues = <Due>[].obs;
  final investors = <Investor>[].obs;
  final repayments = <InvestorRepayment>[].obs;
  final legacySettlements = <LegacySettlement>[].obs;

  /// `true` = Day view (today), `false` = All-time — matches the spec's
  /// stated default of Day view.
  final isDayView = true.obs;
  final selectedDay = Rxn<DateTime>();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.ledgerDao
          .watchAll(defaultShopId)
          .listen((rows) => ledgerEntries.assignAll(rows)),
    );
    _subscriptions.add(
      db.saleDao
          .watchAll(defaultShopId)
          .listen((rows) => sales.assignAll(rows)),
    );
    _subscriptions.add(
      db.purchaseDao
          .watchAll(defaultShopId)
          .listen((rows) => purchaseTrips.assignAll(rows)),
    );
    _subscriptions.add(
      db.ledgerDao
          .watchAllStockMovements(defaultShopId)
          .listen((rows) => stockMovements.assignAll(rows)),
    );
    _subscriptions.add(
      db.expenseDao
          .watchAll(defaultShopId)
          .listen((rows) => expenses.assignAll(rows)),
    );
    _subscriptions.add(
      db.dueDao
          .watchAll(defaultShopId)
          .listen((rows) => dues.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAllRepayments(defaultShopId)
          .listen((rows) => repayments.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAllSettlements(defaultShopId)
          .listen((rows) => legacySettlements.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  DateRange get _range => isDayView.value
      ? DateRange.dayContaining(selectedDay.value ?? DateTime.now())
      : DateRange.allTime();

  void toggleView() => isDayView.value = !isDayView.value;

  void selectDay(DateTime day) {
    selectedDay.value = day;
    isDayView.value = true;
  }

  Money get monthlyShopRent {
    try {
      if (Get.isRegistered<SettingsRegistry>()) {
        return Get.find<SettingsRegistry>().get(
          SettingKey.money(
            'pricing.monthlyShopRent',
            defaultValue: Money.zero(),
          ),
        );
      }
    } catch (_) {}
    return Money.zero();
  }

  List<InvestorObligationDetail> get investorObligationDetails {
    final list = <InvestorObligationDetail>[];
    for (final inv in investors) {
      final purchaseItems = [
        for (final trip in purchaseTrips)
          for (final item in trip.items)
            if (item.fundSource.investorId == inv.id) item,
      ];
      final theirProducts =
          products.where((p) => p.fundSource.investorId == inv.id).toList();
      final theirSales =
          sales.where((s) => s.fundSource.investorId == inv.id).toList();
      final capitalReturns = repayments
          .where(
            (r) =>
                r.investorId == inv.id &&
                r.type == RepaymentType.capitalReturn,
          )
          .map((r) => r.amount)
          .toList();

      final metrics = computeInvestorMetrics(
        investor: inv,
        purchaseItemsForInvestor: purchaseItems,
        productsForInvestor: theirProducts,
        salesForInvestor: theirSales,
        capitalReturnRepayments: capitalReturns,
      );

      if (metrics.remainingBalance.isPositive) {
        final termDays = inv.capitalReturnTermDays;
        final dailyMinor = termDays != null && termDays > 0
            ? (metrics.remainingBalance.minorUnits / termDays).round()
            : (metrics.remainingBalance.minorUnits / 30.0).round();
        final daily = Money.fromMinor(
          dailyMinor,
          currency: metrics.remainingBalance.currency,
        );

        list.add(
          InvestorObligationDetail(
            investor: inv,
            remainingBalance: metrics.remainingBalance,
            dailyObligation: daily,
            termDays: termDays,
          ),
        );
      }
    }
    return list;
  }

  DashboardTotals get totals {
    final range = _range;
    final byId = {for (final p in products) p.id: p};

    final duesInRange = isDayView.value
        ? dues.where((d) => range.contains(d.createdAt)).toList()
        : dues.where((d) => d.status != DueStatus.paid).toList();

    var totalInvestorRemaining = Money.zero();
    var dailyInvestorObligation = Money.zero();

    for (final detail in investorObligationDetails) {
      totalInvestorRemaining =
          totalInvestorRemaining + detail.remainingBalance;
      dailyInvestorObligation =
          dailyInvestorObligation + detail.dailyObligation;
    }

    final targetMonth = selectedDay.value ?? DateTime.now();
    final rentPaidThisMonth = expenses
        .where(
          (e) =>
              e.category == ExpenseCategory.monthlyRent &&
              e.date.year == targetMonth.year &&
              e.date.month == targetMonth.month,
        )
        .fold(Money.zero(), (sum, e) => sum + e.amount);

    final configuredRent = monthlyShopRent;
    final rentRemainingThisMonth = configuredRent > rentPaidThisMonth
        ? (configuredRent - rentPaidThisMonth)
        : Money.zero();

    final dailyRentObligation = configuredRent.isPositive
        ? Money.fromMinor(
            (configuredRent.minorUnits / 30.0).round(),
            currency: configuredRent.currency,
          )
        : Money.zero();

    return computeDashboardTotals(
      ledgerEntriesInRange: ledgerEntries
          .where((e) => range.contains(e.date))
          .toList(),
      salesInRange: sales.where((s) => range.contains(s.date)).toList(),
      purchaseTripsInRange: purchaseTrips
          .where((t) => range.contains(t.date))
          .toList(),
      stockMovementsInRange: stockMovements
          .where((m) => range.contains(m.date))
          .where((m) => byId.containsKey(m.productId))
          .map(
            (m) => ValuedStockMovement(
              deltaQty: m.deltaQty,
              costPriceNow: byId[m.productId]!.costPrice,
            ),
          )
          .toList(),
      expensesInRange: expenses
          .where((e) => range.contains(e.date))
          .map((e) => e.amount)
          .toList(),
      duesInRange: duesInRange,
      totalInvestorRemaining: totalInvestorRemaining,
      dailyInvestorObligation: dailyInvestorObligation,
      monthlyShopRent: configuredRent,
      rentPaidThisMonth: rentPaidThisMonth,
      rentRemainingThisMonth: rentRemainingThisMonth,
      dailyRentObligation: dailyRentObligation,
    );
  }

  Future<bool> payRent({
    required Money amount,
    required PaymentMethod paymentMethod,
    String? note,
  }) async {
    final useCases = ExpenseUseCases(db);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final result = await useCases.create(
      Expense(
        id: const Uuid().v7(),
        category: ExpenseCategory.monthlyRent,
        amount: amount,
        date: now,
        paymentMethod: paymentMethod,
        description: note ?? 'দোকান ভাড়া - $monthName',
      ),
      shopId: defaultShopId,
      now: now.toUtc(),
    );
    return result.isOk;
  }
}
