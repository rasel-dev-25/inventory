import 'dart:async';

import 'package:get/get.dart';

import '../../../core/time/date_range.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/cash_ledger_entry.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/dashboard_calculator.dart';

/// Backs the v2 Dashboard screen — `notes/business_logic.md` §ঝ's Day
/// view (default, today) vs. All-time view toggle, both served by the
/// exact same [computeDashboardTotals] call with a different [DateRange],
/// per the spec's own implementation note. See `CatalogScreen`'s doc
/// comment for why this reads the v2 database only, separate from v1's
/// Dashboard tab.
///
/// **Known simplification, flagged rather than hidden:** the spec's
/// per-card tap-to-see-all-time interaction (each card independently
/// toggles) is not implemented — this is a single Day/All-time switch
/// for the whole screen. Revisit once there's a concrete need for
/// per-card granularity; the underlying calculation already supports it
/// (it's just called once per card instead of once for the screen).
class DashboardController extends GetxController {
  final AppDatabaseV2 db;

  DashboardController(this.db);

  final products = <Product>[].obs;
  final ledgerEntries = <CashLedgerEntry>[].obs;
  final sales = <Sale>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final stockMovements = <StockMovementRow>[].obs;

  /// `true` = Day view (today), `false` = All-time — matches the spec's
  /// stated default of Day view.
  final isDayView = true.obs;

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
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  DateRange get _range => isDayView.value
      ? DateRange.dayContaining(DateTime.now())
      : DateRange.allTime();

  void toggleView() => isDayView.value = !isDayView.value;

  DashboardTotals get totals {
    final range = _range;
    final byId = {for (final p in products) p.id: p};

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
      // Expense v2 doesn't exist yet — see DashboardTotals.netProfit's own
      // doc comment for why this is a flagged gap, not a silent omission.
      expensesInRange: const [],
    );
  }
}
