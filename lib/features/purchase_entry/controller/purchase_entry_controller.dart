import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/delete_purchase_trip_usecase.dart';
import '../../../data/usecases/edit_purchase_trip_usecase.dart';
import '../../../data/usecases/investor_usecases.dart';
import '../../../data/usecases/product_usecases.dart';
import '../../../data/usecases/save_purchase_trip_usecase.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/services/purchase_reconciliation.dart';

/// One row in the in-progress trip's item list — a plain, mutable
/// working-state holder for the form, not the domain [PurchaseItem]
/// itself (which is immutable and only constructed once, on save).
class DraftPurchaseItem {
  final String id;
  String? productId;
  String productName = '';
  String shopName = '';
  double qty = 1;
  Money unitPrice = Money.zero();
  FundSource fundSource = FundSource.shop();
  bool isInKind = false;

  DraftPurchaseItem({
    String? id,
    this.productId,
    this.productName = '',
    this.shopName = '',
    this.qty = 1,
    Money? unitPrice,
    FundSource? fundSource,
    this.isInKind = false,
  })  : id = id ?? const Uuid().v7(),
        unitPrice = unitPrice ?? Money.zero(),
        fundSource = fundSource ?? FundSource.shop();
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
  final AppDatabase db;

  PurchaseEntryController(this.db);

  late final SavePurchaseTripUseCase _useCase = SavePurchaseTripUseCase(db);
  late final DeletePurchaseTripUseCase _deleteUseCase =
      DeletePurchaseTripUseCase(db);
  late final EditPurchaseTripUseCase _editUseCase = EditPurchaseTripUseCase(db);
  late final ProductUseCases _productUseCases = ProductUseCases(db);
  late final InvestorUseCases _investorUseCases = InvestorUseCases(db);
  static const _uuid = Uuid();

  final tripDate = DateTime.now().obs;
  final transportCost = Money.zero().obs;
  final cashReturned = Money.zero().obs;
  final actualCashTakenOut = Rxn<Money>();
  final editingOriginalTripId = RxnString();
  String? _replacementTripId;
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
  final searchQuery = ''.obs;
  final selectedFundFilter = 'all'.obs; // 'all', 'cash', 'investor'

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<PurchaseTrip> get filteredTrips {
    final query = searchQuery.value.trim().toLowerCase();
    final fundFilter = selectedFundFilter.value;

    return recentTrips.where((trip) {
      // 1. Filter by Fund Source
      final isInvestor = trip.items.any((i) => i.fundSource.isInvestor);
      if (fundFilter == 'cash' && isInvestor) return false;
      if (fundFilter == 'investor' && !isInvestor) return false;

      // 2. Filter by Search Query
      if (query.isNotEmpty) {
        final matchesItem = trip.items.any((i) {
          final prod = products.firstWhereOrNull((p) => p.id == i.productId);
          final name = prod?.name.toLowerCase() ?? '';
          return name.contains(query) || i.productId.toLowerCase().contains(query);
        });

        final matchesOtherCost = trip.otherCosts.any((c) => c.description.toLowerCase().contains(query));

        if (!matchesItem && !matchesOtherCost) return false;
      }

      return true;
    }).toList();
  }

  Money get totalPurchasesAmount {
    return filteredTrips.fold(
      Money.zero(),
      (sum, trip) => sum + trip.items.fold(Money.zero(), (itemSum, i) => itemSum + i.lineTotal),
    );
  }

  Money get totalTransportAndOtherCosts {
    return filteredTrips.fold(
      Money.zero(),
      (sum, trip) => sum + trip.transportCost + trip.otherCostsTotal,
    );
  }

  Money get totalSpentAmount {
    return totalPurchasesAmount + totalTransportAndOtherCosts;
  }

  Money get totalRemainingCash {
    return filteredTrips.fold(
      Money.zero(),
      (sum, trip) {
        if (trip.actualCashTakenOut == null || trip.actualCashTakenOut!.minorUnits == 0) {
          return sum;
        }
        final itemsTotal = trip.items.fold(Money.zero(), (s, i) => s + i.lineTotal);
        final totalSpent = itemsTotal + trip.transportCost + trip.otherCostsTotal;
        final netUsed = trip.actualCashTakenOut! - trip.cashReturned;
        final balanceDiff = netUsed.minorUnits - totalSpent.minorUnits;
        return balanceDiff > 0 ? sum + Money.fromMinor(balanceDiff) : sum;
      },
    );
  }

  int get totalItemsCount {
    return filteredTrips.fold(
      0,
      (sum, trip) => sum + trip.items.length,
    );
  }

  void setSearchQuery(String q) => searchQuery.value = q;
  void setFundFilter(String f) => selectedFundFilter.value = f;
  void resetFilters() {
    searchQuery.value = '';
    selectedFundFilter.value = 'all';
  }

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

  Future<Investor?> createInvestor({
    required String name,
    required InvestmentType investmentType,
    required double profitSharePercent,
    required ProfitPayoutCycle profitPayoutCycle,
    String? contact,
    int? capitalReturnTermDays,
    String? notes,
  }) async {
    errorMessage.value = null;
    if (name.trim().isEmpty) {
      errorMessage.value = 'nameRequired'.tr;
      return null;
    }
    final investor = Investor(
      id: _uuid.v7(),
      name: name.trim(),
      contact: contact,
      investmentType: investmentType,
      profitSharePercent: investmentType == InvestmentType.cashLoan
          ? 0
          : profitSharePercent,
      capitalReturnTermDays: capitalReturnTermDays,
      profitPayoutCycle: profitPayoutCycle,
      notes: notes,
    );
    try {
      await _investorUseCases.create(
        investor,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      if (!investors.any((existing) => existing.id == investor.id)) {
        investors.add(investor);
      }
      return investor;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    }
  }

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
    final validItems = items
        .where(
          (i) =>
              (i.productId != null || i.productName.trim().isNotEmpty) &&
              i.qty > 0,
        )
        .toList();
    if (validItems.isEmpty) return null;

    return PurchaseTrip(
      id: _replacementTripId ??= _uuid.v7(),
      date: tripDate.value,
      transportCost: transportCost.value,
      otherCosts: [
        for (final c in otherCosts)
          if (c.description.trim().isNotEmpty)
            OtherCost(description: c.description, amount: c.amount),
      ],
      cashReturned: cashReturned.value,
      actualCashTakenOut: actualCashTakenOut.value,
      items: [
        for (final i in validItems)
          PurchaseItem(
            id: i.id,
            shopName: i.shopName,
            productId: i.productId ?? i.productName.trim(),
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
    final validItems = items
        .where(
          (i) =>
              (i.productId != null || i.productName.trim().isNotEmpty) &&
              i.qty > 0,
        )
        .toList();
    if (validItems.isEmpty) {
      errorMessage.value = 'itemsRequired'.tr;
      return false;
    }

    isSaving.value = true;
    try {
      final now = DateTime.now().toUtc();

      // Ensure every item has a valid registered productId. If the product
      // doesn't exist in the catalog yet, automatically create it on the fly!
      for (final item in validItems) {
        if (item.productId == null || item.productId!.isEmpty) {
          final trimmedName = item.productName.trim();
          final existing = products.firstWhereOrNull(
            (p) => p.name.trim().toLowerCase() == trimmedName.toLowerCase(),
          );
          if (existing != null) {
            item.productId = existing.id;
          } else {
            final newProduct = Product(
              id: _uuid.v7(),
              name: trimmedName,
              category: 'General',
              costPrice: item.unitPrice,
              suggestedSellPrice: item.unitPrice,
              qty: 0,
              fundSource: item.fundSource,
            );
            await _productUseCases.create(
              newProduct,
              shopId: defaultShopId,
              now: now,
            );
            item.productId = newProduct.id;
            if (!products.any((p) => p.id == newProduct.id)) {
              products.add(newProduct);
            }
          }
        }
      }

      final trip = _buildTrip();
      if (trip == null) {
        errorMessage.value = 'itemsRequired'.tr;
        return false;
      }

      if (editingOriginalTripId.value == null) {
        await _useCase.call(trip, shopId: defaultShopId, now: now);
      } else {
        final result = await _editUseCase.call(
          originalTripId: editingOriginalTripId.value!,
          replacement: trip,
          shopId: defaultShopId,
          now: now,
        );
        if (result.isErr) {
          errorMessage.value = result.failureOrNull!.message;
          return false;
        }
      }
      resetDraft();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void resetDraft() {
    tripDate.value = DateTime.now();
    transportCost.value = Money.zero();
    cashReturned.value = Money.zero();
    actualCashTakenOut.value = null;
    otherCosts.clear();
    items.clear();
    editingOriginalTripId.value = null;
    _replacementTripId = null;
  }

  void editTrip(PurchaseTrip trip) {
    errorMessage.value = null;
    editingOriginalTripId.value = trip.id;
    _replacementTripId = _uuid.v7();
    tripDate.value = trip.date;
    transportCost.value = trip.transportCost;
    cashReturned.value = trip.cashReturned;
    actualCashTakenOut.value = trip.actualCashTakenOut;
    otherCosts.assignAll([
      for (final cost in trip.otherCosts)
        (DraftOtherCost()
          ..description = cost.description
          ..amount = cost.amount),
    ]);
    items.assignAll([
      for (final item in trip.items)
        DraftPurchaseItem(
          productId: item.productId,
          productName:
              products.firstWhereOrNull((p) => p.id == item.productId)?.name ??
              '',
          shopName: item.shopName,
          qty: item.qty,
          unitPrice: item.unitPrice,
          fundSource: item.fundSource,
          isInKind: item.isInKind,
        ),
    ]);
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
