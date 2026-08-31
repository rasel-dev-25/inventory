import 'dart:async';
import 'dart:io';

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

  final customerThumbnails = <String, String>{}.obs;
  final productThumbnails = <String, String>{}.obs;
  final assetThumbnails = <String, String>{}.obs;

  final searchQuery = ''.obs;
  final selectedCategory = 'all'.obs;

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

    // Watch image maps for thumbnail previews
    _subscriptions.add(
      db.select(db.customerImages).watch().listen((rows) {
        final map = <String, String>{};
        for (final r in rows) {
          final path = r.localPath ?? r.remoteUrl;
          if (path != null && path.isNotEmpty) {
            map[r.customerId] = path;
          }
        }
        customerThumbnails.assignAll(map);
      }),
    );
    _subscriptions.add(
      db.select(db.productImages).watch().listen((rows) {
        final map = <String, String>{};
        for (final r in rows) {
          final path = r.thumbnailLocalPath ??
              r.localPath ??
              r.thumbnailRemoteUrl ??
              r.remoteUrl;
          if (path != null && path.isNotEmpty) {
            map[r.productId] = path;
          }
        }
        productThumbnails.assignAll(map);
      }),
    );
    _subscriptions.add(
      db.select(db.fixedAssetImages).watch().listen((rows) {
        final map = <String, String>{};
        for (final r in rows) {
          final path = r.localPath ?? r.remoteUrl;
          if (path != null && path.isNotEmpty) {
            map[r.assetId] = path;
          }
        }
        assetThumbnails.assignAll(map);
      }),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  int get totalDeletedCount =>
      deletedCustomers.length +
      deletedOrders.length +
      deletedExpenses.length +
      deletedProducts.length +
      deletedFixedAssets.length +
      deletedPurchaseTrips.length;

  List<CustomerRow> get filteredCustomers {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return deletedCustomers;
    return deletedCustomers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.contact != null && c.contact!.toLowerCase().contains(query));
    }).toList();
  }

  List<ProductRow> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return deletedProducts;
    return deletedProducts.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(query));
    }).toList();
  }

  List<OrderRow> get filteredOrders {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return deletedOrders;
    return deletedOrders.where((o) {
      return o.itemDescription.toLowerCase().contains(query);
    }).toList();
  }

  List<ExpenseRow> get filteredExpenses {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return deletedExpenses;
    return deletedExpenses.where((e) {
      return e.description != null &&
          e.description!.toLowerCase().contains(query);
    }).toList();
  }

  List<FixedAssetRow> get filteredFixedAssets {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return deletedFixedAssets;
    return deletedFixedAssets.where((a) {
      return a.name.toLowerCase().contains(query);
    }).toList();
  }

  List<PurchaseTripRow> get filteredPurchaseTrips {
    return deletedPurchaseTrips;
  }

  // ── Restore Actions ───────────────────────────────────────────────────────
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

  // ── Permanent Deletion & Safe File Cleanup ────────────────────────────────
  Future<void> _safeDeleteLocalFile(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // Ignored for network URLs or missing files
    }
  }

  Future<void> _cleanCustomerImages(String customerId) async {
    try {
      final rows = await (db.select(db.customerImages)
            ..where((i) => i.customerId.equals(customerId)))
          .get();
      for (final row in rows) {
        await _safeDeleteLocalFile(row.localPath);
      }
    } catch (_) {}
  }

  Future<void> _cleanProductImages(String productId) async {
    try {
      final rows = await (db.select(db.productImages)
            ..where((i) => i.productId.equals(productId)))
          .get();
      for (final row in rows) {
        await _safeDeleteLocalFile(row.localPath);
        await _safeDeleteLocalFile(row.thumbnailLocalPath);
      }
    } catch (_) {}
  }

  Future<void> _cleanFixedAssetImages(String assetId) async {
    try {
      final rows = await (db.select(db.fixedAssetImages)
            ..where((i) => i.assetId.equals(assetId)))
          .get();
      for (final row in rows) {
        await _safeDeleteLocalFile(row.localPath);
      }
    } catch (_) {}
  }

  Future<bool> permanentDeleteCustomer(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final success = await db.customerDao.hardDelete(id);
      if (!success) {
        errorMessage.value = 'cannotDeleteLinkedCustomer'.tr;
        return false;
      }
      await _cleanCustomerImages(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'customers',
        recordId: id,
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

  Future<bool> permanentDeleteProduct(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final success = await db.productDao.hardDelete(id);
      if (!success) {
        errorMessage.value = 'cannotDeleteLinkedProduct'.tr;
        return false;
      }
      await _cleanProductImages(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'products',
        recordId: id,
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

  Future<bool> permanentDeleteOrder(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await db.orderDao.hardDelete(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'orders',
        recordId: id,
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

  Future<bool> permanentDeleteExpense(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await db.expenseDao.hardDelete(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'expenses',
        recordId: id,
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

  Future<bool> permanentDeleteFixedAsset(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await db.fixedAssetDao.hardDelete(id);
      await _cleanFixedAssetImages(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'fixed_assets',
        recordId: id,
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

  Future<bool> permanentDeletePurchaseTrip(String id) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await db.purchaseDao.hardDeleteTrip(id);
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'PERMANENT_DELETE',
        changedTableName: 'purchase_trips',
        recordId: id,
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

  // ── Prune & Empty Bin Action ──────────────────────────────────────────────
  Future<void> pruneNow({
    int auditLogRetentionDays =
        RetentionPolicyUseCase.defaultAuditLogRetentionDays,
    int recycleBinRetentionDays = 0,
  }) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      // Clean up files before removing database rows
      for (final c in deletedCustomers) {
        await _cleanCustomerImages(c.id);
      }
      for (final p in deletedProducts) {
        await _cleanProductImages(p.id);
      }
      for (final a in deletedFixedAssets) {
        await _cleanFixedAssetImages(a.id);
      }

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
