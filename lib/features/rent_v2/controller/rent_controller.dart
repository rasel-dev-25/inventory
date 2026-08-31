import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/issue_rent_usecase.dart';
import '../../../data/usecases/mark_rent_stolen_usecase.dart';
import '../../../data/usecases/return_rent_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/services/rent_lifecycle.dart';

/// Backs the Rent screen — issue, return, and stolen-escalation for
/// book rentals, per `notes/business_logic.md` §জ.
class RentController extends GetxController {
  final AppDatabase db;

  RentController(this.db);

  late final IssueRentUseCase _issueUseCase = IssueRentUseCase(db);
  late final ReturnRentUseCase _returnUseCase = ReturnRentUseCase(db);
  late final MarkRentStolenUseCase _stolenUseCase = MarkRentStolenUseCase(db);

  final products = <Product>[].obs;
  final customers = <Customer>[].obs;
  final rentals = <RentTransaction>[].obs;
  final tiers = <RentPricingTierRow>[].obs;

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
      db.rentDao
          .watchAll(defaultShopId)
          .listen((rows) => rentals.assignAll(rows)),
    );
    _subscriptions.add(
      db.rentDao
          .watchTiers(defaultShopId)
          .listen((rows) => tiers.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  List<Product> get rentableProducts =>
      products.where((p) => p.isRentable).toList();

  List<RentTransaction> get activeRentals =>
      rentals.where((r) => r.status == RentStatus.active).toList();

  List<RentTransaction> get overdueRentals =>
      activeRentals.where((r) => rentIsOverdue(r)).toList();

  List<RentTransaction> get history =>
      rentals.where((r) => r.status != RentStatus.active).toList();

  int get activeCount => activeRentals.length;
  int get overdueCount => overdueRentals.length;
  int get historyCount => history.length;

  Money get totalActiveDeposits =>
      activeRentals.fold(Money.zeroBdt, (sum, r) => sum + r.deposit);

  Money get totalRentRevenue => rentals
      .where((r) => r.status == RentStatus.returned)
      .fold(
        Money.zeroBdt,
        (sum, r) =>
            sum +
            r.rentPrice +
            (r.extraDayCharge ?? Money.zeroBdt) +
            (r.damageCharge ?? Money.zeroBdt),
      );

  /// How many copies of [product] are free to rent right now —
  /// `product.qty` minus how many of *this shop's* rentals of it are
  /// still active. See `RentDao`/`tables/rent.dart` for why this is
  /// computed here rather than cached anywhere.
  int availableCopiesFor(Product product) {
    final activeCount = rentals
        .where(
          (r) => r.bookProductId == product.id && r.status == RentStatus.active,
        )
        .length;
    return product.qty.toInt() - activeCount;
  }

  /// The tier that would be suggested for [product], or `null` when the
  /// book has no `pageCount` set or no tier covers it — see
  /// `rent_lifecycle.dart`'s `suggestTierFor` for why `null` means
  /// "manual entry required", not an error.
  ({int days, Money price})? suggestedTierFor(Product product) {
    if (product.pageCount == null) return null;
    return suggestTierFor(
      product.pageCount!,
      tiers
          .map(
            (t) =>
                (maxPages: t.maxPages, days: t.days, priceMinor: t.priceMinor),
          )
          .toList(),
    );
  }

  /// The extra-day charge suggestion the return dialog pre-fills, per
  /// `notes/business_logic.md` §জ step 4: "extraDayCharge প্রতি-দিন রেট
  /// (Settings-এ কনফিগারযোগ্য) দিয়ে অটো-সাজেস্ট". No Settings screen for a
  /// configurable per-day rate exists yet in v2, so this derives a
  /// per-day rate *from the rental's own agreed price and duration*
  /// (`rentPrice ÷ originally-agreed days`) rather than inventing a fake
  /// global default — a book rented for ৳20/15 days extends at ~৳1.33/day,
  /// proportional to what was actually agreed. Always just a suggestion;
  /// the return dialog lets the owner override it, per the spec.
  Money suggestedExtraDayChargeFor(
    RentTransaction rent,
    DateTime actualReturnDate,
  ) {
    final extraDays = computeExtraDays(
      dueDate: rent.dueDate,
      actualReturnDate: actualReturnDate,
    );
    final originalDays = rent.dueDate.difference(rent.startDate).inDays;
    final perDayRate = originalDays > 0
        ? rent.rentPrice / originalDays
        : rent.rentPrice;
    return suggestExtraDayCharge(extraDays: extraDays, perDayRate: perDayRate);
  }

  String customerName(String id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool rentIsOverdue(RentTransaction rent) => isOverdue(rent, DateTime.now());

  Future<bool> issueRent({
    required String bookProductId,
    required String customerId,
    required Money deposit,
    int? days,
    Money? rentPrice,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _issueUseCase.call(
      bookProductId: bookProductId,
      customerId: customerId,
      deposit: deposit,
      days: days,
      rentPrice: rentPrice,
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

  Future<bool> returnRent({
    required String rentId,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    Money? extraDayCharge,
    Money? damageCharge,
    int? promisedDays,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _returnUseCase.call(
      rentId: rentId,
      actualReturnDate: DateTime.now(),
      amountReceivedNow: amountReceivedNow,
      paymentMethod: paymentMethod,
      extraDayCharge: extraDayCharge,
      damageCharge: damageCharge,
      promisedDays: promisedDays,
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

  Future<bool> markStolen(String rentId) async {
    errorMessage.value = null;
    final result = await _stolenUseCase.call(
      rentId: rentId,
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
