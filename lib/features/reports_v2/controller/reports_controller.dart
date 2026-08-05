import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../core/time/date_range.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/cash_ledger_entry.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/dashboard_calculator.dart';
import '../../../domain/services/period_report.dart';

/// The period a report covers — [ReportsController] recomputes every
/// figure for whichever one of these is currently selected. [custom]
/// carries its own `DateRange` (from a date-range picker); the other
/// three are always relative to "now" at read time so a report opened
/// yesterday and one opened today both mean "today" correctly.
enum ReportPeriod { today, thisWeek, thisMonth, custom }

/// Backs the Reports screen — a period-selectable accounting summary
/// building on the exact same [computeDashboardTotals] the Dashboard
/// screen already uses (it's already `DateRange`-agnostic — see its own
/// doc comment), plus the two period-specific breakdowns in
/// `period_report.dart` the Dashboard has no need for.
class ReportsController extends GetxController {
  final AppDatabase db;

  ReportsController(this.db);

  final products = <Product>[].obs;
  final ledgerEntries = <CashLedgerEntry>[].obs;
  final sales = <Sale>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final stockMovements = <StockMovementRow>[].obs;
  final expenses = <Expense>[].obs;
  final investors = <Investor>[].obs;

  final period = ReportPeriod.today.obs;

  /// Only meaningful when [period] is [ReportPeriod.custom] — set via
  /// [setCustomRange].
  final Rxn<DateRange> customRange = Rxn<DateRange>();

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
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  void selectPeriod(ReportPeriod value) => period.value = value;

  /// Switches to [ReportPeriod.custom] and sets its range in one call —
  /// a caller never has to sequence `selectPeriod(custom)` before this
  /// and risk a frame where `custom` is selected but [customRange] is
  /// still null.
  void setCustomRange(DateTime start, DateTime end) {
    customRange.value = DateRange(start: start, end: end);
    period.value = ReportPeriod.custom;
  }

  DateRange get range {
    final now = DateTime.now().toUtc();
    switch (period.value) {
      case ReportPeriod.today:
        return DateRange.dayContaining(now);
      case ReportPeriod.thisWeek:
        return DateRange.weekContaining(now);
      case ReportPeriod.thisMonth:
        return DateRange.monthContaining(now);
      case ReportPeriod.custom:
        return customRange.value ?? DateRange.dayContaining(now);
    }
  }

  List<Sale> get _salesInRange =>
      sales.whereInRange(range, (s) => s.date).toList();

  DashboardTotals get totals {
    final r = range;
    final byId = {for (final p in products) p.id: p};

    return computeDashboardTotals(
      ledgerEntriesInRange: ledgerEntries
          .whereInRange(r, (e) => e.date)
          .toList(),
      salesInRange: _salesInRange,
      purchaseTripsInRange: purchaseTrips
          .whereInRange(r, (t) => t.date)
          .toList(),
      stockMovementsInRange: stockMovements
          .whereInRange(r, (m) => m.date)
          .where((m) => byId.containsKey(m.productId))
          .map(
            (m) => ValuedStockMovement(
              deltaQty: m.deltaQty,
              costPriceNow: byId[m.productId]!.costPrice,
            ),
          )
          .toList(),
      expensesInRange: expenses
          .whereInRange(r, (e) => e.date)
          .map((e) => e.amount)
          .toList(),
    );
  }

  /// [DashboardTotals] has no standalone expenses figure (`netProfit`
  /// already nets it against gross profit) — a report showing "how much
  /// did I spend" as its own line needs this summed separately, straight
  /// from the same [expenses] list [totals] itself filters.
  Money get totalExpenses {
    final r = range;
    return expenses
        .whereInRange(r, (e) => e.date)
        .map((e) => e.amount)
        .fold(Money.zero(), (sum, amount) => sum + amount);
  }

  List<InvestorPeriodShare> get investorShares {
    return computeInvestorProfitShareReport(
      investors: investors,
      salesInRange: _salesInRange,
    );
  }

  List<ProductPeriodSales> get productSales {
    return computeProductSalesSummary(salesInRange: _salesInRange);
  }
}
