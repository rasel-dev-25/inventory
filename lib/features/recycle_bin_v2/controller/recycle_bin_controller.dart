import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/audit_log_usecases.dart';
import '../../../data/usecases/customer_usecases.dart';
import '../../../data/usecases/order_usecases.dart';
import '../../../data/usecases/product_usecases.dart';

/// Backs the v2 Recycle Bin screen — every currently soft-deletable,
/// UI-reachable entity: [Customers], [Orders], [Expenses], [Products],
/// [FixedAssets], [PurchaseTrips].
///
/// **Restore is offered for [Customers]/[Orders]/[Products]** — see
/// `CustomerDao.restore`'s own doc comment for why those are safe to
/// un-delete unconditionally (no paired cash/stock write to also undo;
/// `ProductDao.restore`'s own doc comment gives the same reasoning for
/// products). [Expenses]/[FixedAssets]/[PurchaseTrips] rows are shown
/// here too (so the owner can still see what was deleted and when) but
/// with no restore action — undoing any of those three would need to
/// re-apply a cash-ledger or stock-movement reversal
/// (`ExpenseUseCases.softDelete`/`FixedAssetUseCases.delete`/
/// `DeletePurchaseTripUseCase` respectively) that `buildCashLedgerReversal`/
/// `buildStockMovementReversal` cannot safely run a second time on an
/// already-reversed source (see `ledger_reversal.dart`'s own doc
/// comment) — a real feature this change deliberately does not attempt
/// for any of the three.
///
/// [pruneNow] is a **manual, explicit action** — deliberately not run
/// automatically on [onInit]. An automatic prune on every screen open
/// would silently hard-delete exactly the rows this screen exists to let
/// the owner review before that happens; the owner decides when "clean
/// up old items" runs, via the screen's own button. It also does not
/// touch [Products]/[FixedAssets]/[PurchaseTrips] at all — see
/// `RetentionPolicyUseCase`'s own doc comment for exactly why each of
/// those three is excluded from hard-delete.
class RecycleBinController extends GetxController {
  final AppDatabase db;

  RecycleBinController(this.db);

  late final CustomerUseCases _customerUseCases = CustomerUseCases(db);
  late final OrderUseCases _orderUseCases = OrderUseCases(db);
  late final ProductUseCases _productUseCases = ProductUseCases(db);
  late final RetentionPolicyUseCase _retentionPolicy = RetentionPolicyUseCase(
    db,
  );

  final deletedCustomers = <CustomerRow>[].obs;
  final deletedOrders = <OrderRow>[].obs;
  final deletedExpenses = <ExpenseRow>[].obs;
  final deletedProducts = <ProductRow>[].obs;
  final deletedFixedAssets = <FixedAssetRow>[].obs;
  final deletedPurchaseTrips = <PurchaseTripRow>[].obs;

  final isBusy = false.obs;
  final errorMessage = RxnString();
  final Rxn<RetentionPruneResult> lastPruneResult = Rxn<RetentionPruneResult>();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.customerDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedCustomers.assignAll(rows)),
    );
    _subscriptions.add(
      db.orderDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedOrders.assignAll(rows)),
    );
    _subscriptions.add(
      db.expenseDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedExpenses.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedProducts.assignAll(rows)),
    );
    _subscriptions.add(
      db.fixedAssetDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedFixedAssets.assignAll(rows)),
    );
    _subscriptions.add(
      db.purchaseDao
          .watchDeleted(defaultShopId)
          .listen((rows) => deletedPurchaseTrips.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Future<bool> restoreCustomer(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await _customerUseCases.restore(
        id,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> restoreOrder(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await _orderUseCases.restore(
        id,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> restoreProduct(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await _productUseCases.restore(
        id,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> pruneNow({
    int auditLogRetentionDays =
        RetentionPolicyUseCase.defaultAuditLogRetentionDays,
    int recycleBinRetentionDays =
        RetentionPolicyUseCase.defaultRecycleBinRetentionDays,
  }) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final result = await _retentionPolicy.pruneAll(
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
        auditLogRetentionDays: auditLogRetentionDays,
        recycleBinRetentionDays: recycleBinRetentionDays,
      );
      lastPruneResult.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }
}
