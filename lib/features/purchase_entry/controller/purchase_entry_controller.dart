import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/delete_purchase_trip_usecase.dart';
import '../../../data/usecases/save_purchase_trip_usecase.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/services/purchase_reconciliation.dart';

/// One row in the in-progress trip's item list — a plain, mutable
/// working-state holder for the form, not the domain [PurchaseItem]
/// itself (which is immutable and only constructed once, on save).
class DraftPurchaseItem {
  final String id = const Uuid().v7();
  String? productId;
  String shopName = '';
  double qty = 1;
  Money unitPrice = Money.zero();
  FundSource fundSource = FundSource.shop();
  bool isInKind = false;
}

class DraftOtherCost {
  String description = '';
  Money amount = Money.zero();
}

/// Backs `lib/features/purchase_entry/view/purchase_entry_screen.dart`.
/// Holds the in-progress trip's draft state (items/other costs are built
/// up interactively before a single [save] call), and exposes a live
/// [reconciliationPreview] so the form can show the same total-cash-out
/// figure the spec's own "sanity check" describes, before committing.
class PurchaseEntryController extends GetxController {
  final AppDatabaseV2 db;

  PurchaseEntryController(this.db);

  late final SavePurchaseTripUseCase _useCase = SavePurchaseTripUseCase(db);
  late final DeletePurchaseTripUseCase _deleteUseCase =
      DeletePurchaseTripUseCase(db);
  static const _uuid = Uuid();

  final tripDate = DateTime.now().obs;
  final transportCost = Money.zero().obs;
  final cashReturned = Money.zero().obs;
  final otherCosts = <DraftOtherCost>[].obs;
  final items = <DraftPurchaseItem>[].obs;

  final products = <Product>[].obs;
  final investors = <Investor>[].obs;

  /// Backs the screen's "Recent Trips" list — the first real UI trigger
  /// for [DeletePurchaseTripUseCase] (previously dead code with no
  /// reachable delete action anywhere, per that use case's own doc
  /// comment). Capped the same way `PurchaseDao.watchRecent`'s own doc
  /// comment explains: right for a scrolling list, wrong for a total.
  final recentTrips = <PurchaseTrip>[].obs;

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    // See CatalogController.onClose()'s doc comment for why these must
    // be cancelled explicitly.
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
    _subscriptions.add(
      db.purchaseDao
          .watchRecent(defaultShopId, limit: 20)
          .listen((rows) => recentTrips.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  void addItem() => items.add(DraftPurchaseItem());

  void removeItem(DraftPurchaseItem item) => items.remove(item);

  void addOtherCost() => otherCosts.add(DraftOtherCost());

  void removeOtherCost(DraftOtherCost cost) => otherCosts.remove(cost);

  /// A live preview of `reconcilePurchaseTrip`'s result over the current
  /// draft — built from the exact same domain entities [save] will
  /// construct, so what the form shows and what actually gets recorded
  /// can never disagree. Returns null while the draft has no valid items
  /// yet (an empty trip isn't a meaningful reconciliation).
  PurchaseTripReconciliation? get reconciliationPreview {
    final trip = _buildTrip();
    if (trip == null) return null;
    return reconcilePurchaseTrip(trip);
  }

  PurchaseTrip? _buildTrip() {
    final validItems = items.where((i) => i.productId != null).toList();
    if (validItems.isEmpty) return null;

    return PurchaseTrip(
      id: _uuid.v7(),
      date: tripDate.value,
      transportCost: transportCost.value,
      otherCosts: [
        for (final c in otherCosts)
          if (c.description.trim().isNotEmpty)
            OtherCost(description: c.description, amount: c.amount),
      ],
      cashReturned: cashReturned.value,
      items: [
        for (final i in validItems)
          PurchaseItem(
            id: i.id,
            shopName: i.shopName,
            productId: i.productId!,
            qty: i.qty,
            unitPrice: i.unitPrice,
            fundSource: i.fundSource,
            isInKind: i.isInKind,
          ),
      ],
    );
  }

  Future<bool> save() async {
    errorMessage.value = null;
    final trip = _buildTrip();
    if (trip == null) {
      errorMessage.value = 'itemsRequired'.tr;
      return false;
    }

    isSaving.value = true;
    try {
      await _useCase.call(
        trip,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      _resetDraft();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _resetDraft() {
    tripDate.value = DateTime.now();
    transportCost.value = Money.zero();
    cashReturned.value = Money.zero();
    otherCosts.clear();
    items.clear();
  }

  /// See `DeletePurchaseTripUseCase`'s own doc comment for exactly what
  /// this reverses (every stock movement and cash-ledger entry the
  /// original save wrote) and why there is no matching "restore" —
  /// deleting a trip is a one-way trip, same as an expense.
  Future<bool> deleteTrip(String id) async {
    errorMessage.value = null;
    final result = await _deleteUseCase.call(
      tripId: id,
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
