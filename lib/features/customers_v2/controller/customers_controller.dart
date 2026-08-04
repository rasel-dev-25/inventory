import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/customer_usecases.dart';
import '../../../domain/entities/customer.dart';

/// Backs the v2 Customers screen — list/create/edit/soft-delete plus the
/// flagged (suspicion/blocked) filter view from `notes/business_logic.md`
/// §জ, via [CustomerUseCases]. See `CatalogScreen`'s doc comment for why
/// this reads/writes the v2 database only, separate from v1's Customers
/// tab.
class CustomersController extends GetxController {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  CustomersController(this.db);

  late final CustomerUseCases _useCases = CustomerUseCases(db);

  final customers = <Customer>[].obs;
  final searchQuery = ''.obs;
  final showFlaggedOnly = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
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

  /// Applies the search query (name/contact, case-insensitive) and the
  /// flagged-only toggle together — a customer must satisfy both to show,
  /// same combinable-filter approach `InventoryController`'s filter bar
  /// uses.
  List<Customer> get visibleCustomers {
    final query = searchQuery.value.trim().toLowerCase();
    return customers.where((c) {
      if (showFlaggedOnly.value && !c.suspicionFlag && !c.isBlocked) {
        return false;
      }
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          (c.contact?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<bool> createCustomer({
    required String name,
    String? address,
    String? contact,
    bool suspicionFlag = false,
    bool isBlocked = false,
  }) async {
    errorMessage.value = null;
    if (name.trim().isEmpty) {
      errorMessage.value = 'nameRequired'.tr;
      return false;
    }
    try {
      await _useCases.create(
        Customer(
          id: _uuid.v7(),
          name: name.trim(),
          address: address,
          contact: contact,
          suspicionFlag: suspicionFlag,
          isBlocked: isBlocked,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  /// [existing] must be the customer as currently stored (from
  /// [customers]) — every field this doesn't explicitly change is carried
  /// over unchanged, same rule `CatalogController.updateProduct`
  /// documents for products.
  Future<bool> updateCustomer(
    Customer existing, {
    String? name,
    String? address,
    String? contact,
    bool? suspicionFlag,
    bool? isBlocked,
  }) async {
    errorMessage.value = null;
    try {
      final updated = existing.copyWith(
        name: name,
        address: address,
        contact: contact,
        suspicionFlag: suspicionFlag,
        isBlocked: isBlocked,
      );
      await _useCases.update(
        updated,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    errorMessage.value = null;
    try {
      await _useCases.softDelete(
        id,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }
}
