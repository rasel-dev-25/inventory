import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/fixed_asset_usecases.dart';
import '../../../domain/entities/fixed_asset.dart';
import '../../../domain/entities/product.dart';

/// Backs the v2 Fixed Asset screen — the two creation paths per
/// `notes/business_logic.md`'s "দুইভাবে যোগ করার ব্যবস্থা", via
/// [FixedAssetUseCases]. No v1 name collision: v1's equivalent is
/// `AssetsController`/`AssetsScreen` (plural), a different name from this
/// screen's singular `FixedAssetController`/`FixedAssetScreen`.
class FixedAssetController extends GetxController {
  final AppDatabaseV2 db;

  FixedAssetController(this.db);

  late final FixedAssetUseCases _useCases = FixedAssetUseCases(db);

  final assets = <FixedAsset>[].obs;
  final products = <Product>[].obs;

  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.fixedAssetDao
          .watchAll(defaultShopId)
          .listen((rows) => assets.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
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

  Future<bool> createFromCashPurchase({
    required String name,
    required Money value,
    required DateTime dateAcquired,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.createFromCashPurchase(
      name: name,
      value: value,
      dateAcquired: dateAcquired,
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

  Future<bool> createFromStock({
    required String productId,
    required double qty,
    String? name,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.createFromStock(
      productId: productId,
      qty: qty,
      name: name,
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
}
