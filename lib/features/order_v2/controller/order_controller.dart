import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/order_usecases.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';

/// Backs the Order screen — customer pre-orders, per
/// `notes/business_logic.md` §Order. A dedicated screen rather than a
/// tab embedded inside Customers, matching every other module's
/// one-feature-per-screen split.
class OrderController extends GetxController {
  final AppDatabase db;

  OrderController(this.db);

  late final OrderUseCases _useCases = OrderUseCases(db);

  final orders = <Order>[].obs;
  final customers = <Customer>[].obs;

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
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  String customerName(String id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return id;
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
