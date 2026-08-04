import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/save_sale_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';

/// Backs the v2 Daily Sales screen — the "cash/due router" from
/// `notes/business_logic.md` §গ, via `SaveSaleUseCase`. See
/// `CatalogScreen`'s doc comment for why this reads/writes the v2
/// database only, separate from v1's Daily Sales tab.
class DailySalesController extends GetxController {
  final AppDatabaseV2 db;

  DailySalesController(this.db);

  late final SaveSaleUseCase _useCase = SaveSaleUseCase(db);

  final products = <Product>[].obs;
  final customers = <Customer>[].obs;
  final recentSales = <Sale>[].obs;

  final isSaving = false.obs;
  final errorMessage = RxnString();

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
      db.customerDao
          .watchAll(defaultShopId)
          .listen((rows) => customers.assignAll(rows)),
    );
    _subscriptions.add(
      db.saleDao
          .watchRecent(defaultShopId)
          .listen((rows) => recentSales.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Returns `null` on success, or a user-facing error message on
  /// failure — [SaveSaleUseCase] already validates stock/amount/customer
  /// rules via [Result], this just unwraps that into the shape the form
  /// wants without duplicating any of that logic here.
  Future<bool> logSale({
    required String productId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    String? customerId,
    int? promisedDays,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _useCase.call(
      productId: productId,
      qty: qty,
      actualSellPrice: actualSellPrice,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      customerId: customerId,
      promisedDays: promisedDays,
    );
    isSaving.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }
}
