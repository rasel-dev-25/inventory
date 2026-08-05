import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/investor_usecases.dart';
import '../../../data/usecases/legacy_settlement_usecases.dart';
import '../../../data/usecases/record_investor_repayment_usecase.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/investor_repayment.dart';
import '../../../domain/entities/legacy_settlement.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/investor_metrics.dart';

/// Backs the Investor screen — per-investor metrics
/// (`notes/business_logic.md` §ঙ) via [computeInvestorMetrics], plus
/// create/edit ([InvestorUseCases]) and repayment recording
/// ([RecordInvestorRepaymentUseCase]).
///
/// This is also the first place an investor can be *created* —
/// `CatalogScreen`'s and `PurchaseEntryScreen`'s investor dropdowns
/// already read from `InvestorDao.watchAll`, but nothing wrote to it
/// until this screen.
class InvestorController extends GetxController {
  final AppDatabase db;
  static const _uuid = Uuid();

  InvestorController(this.db);

  late final InvestorUseCases _investorUseCases = InvestorUseCases(db);
  late final RecordInvestorRepaymentUseCase _repaymentUseCase =
      RecordInvestorRepaymentUseCase(db);
  late final LegacySettlementUseCases _legacySettlementUseCases =
      LegacySettlementUseCases(db);

  final investors = <Investor>[].obs;
  final products = <Product>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final sales = <Sale>[].obs;
  final repayments = <InvestorRepayment>[].obs;
  final legacySettlements = <LegacySettlement>[].obs;

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.purchaseDao
          .watchAll(defaultShopId)
          .listen((rows) => purchaseTrips.assignAll(rows)),
    );
    _subscriptions.add(
      db.saleDao
          .watchAll(defaultShopId)
          .listen((rows) => sales.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAllRepayments(defaultShopId)
          .listen((rows) => repayments.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAllSettlements(defaultShopId)
          .listen((rows) => legacySettlements.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  /// [computeInvestorMetrics] for [investor] — filters every list down to
  /// this investor's fund source itself, so callers (the screen) never
  /// have to know how that filtering works.
  InvestorMetrics metricsFor(Investor investor) {
    final purchaseItems = [
      for (final trip in purchaseTrips)
        for (final item in trip.items)
          if (item.fundSource.investorId == investor.id) item,
    ];
    final theirProducts = products
        .where((p) => p.fundSource.investorId == investor.id)
        .toList();
    final theirSales = sales
        .where((s) => s.fundSource.investorId == investor.id)
        .toList();
    final capitalReturns = repayments
        .where(
          (r) =>
              r.investorId == investor.id &&
              r.type == RepaymentType.capitalReturn,
        )
        .map((r) => r.amount)
        .toList();

    return computeInvestorMetrics(
      investor: investor,
      purchaseItemsForInvestor: purchaseItems,
      productsForInvestor: theirProducts,
      salesForInvestor: theirSales,
      capitalReturnRepayments: capitalReturns,
    );
  }

  List<InvestorRepayment> repaymentsFor(String investorId) {
    return repayments.where((r) => r.investorId == investorId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns the new investor's id on success (so a caller — the screen's
  /// "has an old ledger-book account?" toggle — can immediately create a
  /// [LegacySettlement] against it), or null on failure.
  Future<String?> createInvestor({
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
    final id = _uuid.v7();
    try {
      await _investorUseCases.create(
        Investor(
          id: id,
          name: name.trim(),
          contact: contact,
          investmentType: investmentType,
          profitSharePercent: profitSharePercent,
          capitalReturnTermDays: capitalReturnTermDays,
          profitPayoutCycle: profitPayoutCycle,
          notes: notes,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return id;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    }
  }

  /// [existing] must be the investor as currently stored (from
  /// [investors]) — every field this doesn't explicitly change is carried
  /// over unchanged, same rule `CatalogController.updateProduct`/
  /// `CustomersController.updateCustomer` document.
  Future<bool> updateInvestor(
    Investor existing, {
    String? name,
    String? contact,
    InvestmentType? investmentType,
    double? profitSharePercent,
    int? capitalReturnTermDays,
    ProfitPayoutCycle? profitPayoutCycle,
    String? notes,
  }) async {
    errorMessage.value = null;
    try {
      final updated = existing.copyWith(
        name: name,
        contact: contact,
        investmentType: investmentType,
        profitSharePercent: profitSharePercent,
        capitalReturnTermDays: capitalReturnTermDays,
        profitPayoutCycle: profitPayoutCycle,
        notes: notes,
      );
      await _investorUseCases.update(
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

  Future<bool> recordRepayment({
    required String investorId,
    required Money amount,
    required RepaymentType type,
    required PaymentMethod paymentMethod,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _repaymentUseCase.call(
      investorId: investorId,
      amount: amount,
      type: type,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
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

  /// The at-most-one [LegacySettlement] on file for [investorId], per
  /// business_logic.md §৬'s "একবারই" rule — null when this investor never
  /// had an old ledger-book account to settle.
  LegacySettlement? settlementFor(String investorId) {
    for (final settlement in legacySettlements) {
      if (settlement.investorId == investorId) return settlement;
    }
    return null;
  }

  /// Only ever called right after [createInvestor] succeeds, from the
  /// "has an old ledger-book account?" toggle on the add-investor form —
  /// see `InvestorFormSheet`'s doc comment for why this never appears on
  /// the edit-investor path.
  Future<bool> createLegacySettlement({
    required String investorId,
    required Money totalHistoricalInvestment,
    required Money totalAlreadyReturned,
    required DateTime settlementDate,
    String? notes,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _legacySettlementUseCases.create(
      investorId: investorId,
      totalHistoricalInvestment: totalHistoricalInvestment,
      totalAlreadyReturned: totalAlreadyReturned,
      settlementDate: settlementDate,
      notes: notes,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
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

  Future<bool> markLegacySettlementSettled(String settlementId) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _legacySettlementUseCases.markSettled(
      settlementId: settlementId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
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
