import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/sync/storage_upload_transport.dart';
import '../../../data/usecases/customer_image_usecases.dart';
import '../../../data/usecases/order_usecases.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';

/// Backs the Order screen — customer pre-orders, per
/// `notes/business_logic.md` §Order.
class OrderController extends GetxController {
  final AppDatabase db;
  final StorageUploadTransport? imageStorage;

  OrderController(this.db, {this.imageStorage});

  late final OrderUseCases _useCases = OrderUseCases(db);

  final orders = <Order>[].obs;
  final customers = <Customer>[].obs;
  final customerImages = <CustomerImageRow>[].obs;
  final signedImageUrls = <String, String>{}.obs;

  /// `null` = all statuses.
  final selectedStatus = Rxn<OrderStatus>();

  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.orderDao
          .watchAll(defaultShopId)
          .listen((rows) => orders.assignAll(rows)),
    );
    _subscriptions.add(
      db.customerDao
          .watchAll(defaultShopId)
          .listen((rows) => customers.assignAll(rows)),
    );
    _subscriptions.add(
      db.customerImageDao.watchForShop(defaultShopId).listen((rows) {
        customerImages.assignAll(rows);
        _resolveRemoteImages(rows);
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

  List<Order> get visibleOrders {
    final status = selectedStatus.value;
    final list = status == null
        ? orders.toList()
        : orders.where((o) => o.status == status).toList();
    // Sort pending first, then by neededByDate / requestedDate descending
    list.sort((a, b) {
      if (a.status == OrderStatus.pending && b.status != OrderStatus.pending) {
        return -1;
      }
      if (b.status == OrderStatus.pending && a.status != OrderStatus.pending) {
        return 1;
      }
      final dateA = a.neededByDate ?? a.requestedDate;
      final dateB = b.neededByDate ?? b.requestedDate;
      return dateA.compareTo(dateB);
    });
    return list;
  }

  int get allCount => orders.length;
  int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;
  int get fulfilledCount =>
      orders.where((o) => o.status == OrderStatus.fulfilled).length;
  int get cancelledCount =>
      orders.where((o) => o.status == OrderStatus.cancelled).length;

  Customer? customerFor(String id) =>
      customers.firstWhereOrNull((c) => c.id == id);

  String customerName(String id) {
    final c = customerFor(id);
    return c?.name ?? id;
  }

  CustomerImageRow? primaryImageFor(String customerId) {
    return customerImages
        .where((image) => image.customerId == customerId)
        .firstOrNull;
  }

  String? imageSourceFor(CustomerImageRow image) {
    final localPath = image.localPath;
    if (localPath != null && File(localPath).existsSync()) return localPath;
    return signedImageUrls[image.id];
  }

  Future<void> _resolveRemoteImages(List<CustomerImageRow> rows) async {
    final storage = imageStorage;
    if (storage == null) return;
    for (final image in rows) {
      if (image.remoteUrl == null || signedImageUrls.containsKey(image.id)) {
        continue;
      }
      final result = await storage.createSignedUrl(
        bucketName: CustomerImageUseCases.bucketName,
        storagePath: image.remoteUrl!,
      );
      result.fold(
        onOk: (url) => signedImageUrls[image.id] = url,
        onErr: (_) {},
      );
    }
  }

  Future<bool> createOrder({
    required String customerId,
    required String itemDescription,
    required DateTime requestedDate,
    DateTime? neededByDate,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.create(
      customerId: customerId,
      itemDescription: itemDescription,
      requestedDate: requestedDate,
      neededByDate: neededByDate,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> markFulfilled(String orderId) =>
      _updateStatus(orderId, OrderStatus.fulfilled);

  Future<bool> markCancelled(String orderId) =>
      _updateStatus(orderId, OrderStatus.cancelled);

  Future<bool> _updateStatus(String orderId, OrderStatus status) async {
    errorMessage.value = null;
    final result = await _useCases.updateStatus(
      orderId: orderId,
      status: status,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<void> deleteOrder(String id) {
    return _useCases.softDelete(
      id,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  }
}
