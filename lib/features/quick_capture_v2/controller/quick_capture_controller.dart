import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/expense_usecases.dart';
import '../../../data/usecases/quick_capture_usecases.dart';
import '../../../data/usecases/save_purchase_trip_usecase.dart';
import '../../../data/usecases/save_sale_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/quick_capture.dart';

/// Backs the v2 Quick Capture screen — jot now, formalize later, per
/// `notes/business_logic.md`'s QuickCapture addition.
///
/// The conversion methods ([convertToExpense]/[convertToSale]/
/// [convertToPurchase]) each do two things in sequence, never one
/// without the other: first create a *real* record via the exact same
/// use case the dedicated v2 screens use ([ExpenseUseCases],
/// [SaveSaleUseCase], [SavePurchaseTripUseCase]) — so a converted
/// capture produces a genuinely correct Sale/PurchaseTrip/Expense, not a
/// shortcut version — then, only once that succeeds,
/// [QuickCaptureUseCases.markConverted] links the capture to it. If the
/// first step fails, the capture stays pending and nothing is marked
/// converted.
///
/// The Sale/Purchase forms here are deliberately smaller than the
/// dedicated `daily_sales_v2`/`purchase_entry_v2` screens (a single
/// product/item, no autosuggest) — a quick-capture conversion is a fast
/// "formalize this one thing" action, not a replacement for those full
/// entry flows. See `QuickCapture`'s own doc comment for the same
/// reasoning applied to capture creation itself (a free-text note
/// standing in for a real voice/photo file until native capture exists).
class QuickCaptureController extends GetxController {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  QuickCaptureController(this.db);

  late final QuickCaptureUseCases _captureUseCases = QuickCaptureUseCases(db);
  late final SaveSaleUseCase _saleUseCase = SaveSaleUseCase(db);
  late final SavePurchaseTripUseCase _purchaseUseCase = SavePurchaseTripUseCase(
    db,
  );
  late final ExpenseUseCases _expenseUseCases = ExpenseUseCases(db);

  final captures = <QuickCapture>[].obs;
  final products = <Product>[].obs;
  final customers = <Customer>[].obs;
  final investors = <Investor>[].obs;

  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.quickCaptureDao
          .watchAll(defaultShopId)
          .listen((rows) => captures.assignAll(rows)),
    );
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
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  List<QuickCapture> get pending =>
      captures.where((c) => c.status == QuickCaptureStatus.pending).toList();

  List<QuickCapture> get converted =>
      captures.where((c) => c.status == QuickCaptureStatus.converted).toList();

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> createCapture({
    required QuickCaptureType type,
    required String note,
  }) async {
    errorMessage.value = null;
    final result = await _captureUseCases.create(
      type: type,
      note: note,
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

  Future<bool> convertToExpense({
    required String captureId,
    required ExpenseCategory category,
    required Money amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    errorMessage.value = null;
    final expense = Expense(
      id: _uuid.v7(),
      category: category,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      description: description,
    );
    final result = await _expenseUseCases.create(
      expense,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    if (result.isErr) {
      errorMessage.value = result.failureOrNull!.message;
      return false;
    }
    return _markConverted(captureId, 'expense', expense.id);
  }

  Future<bool> convertToSale({
    required String captureId,
    required String productId,
    required double qty,
    required Money actualSellPrice,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    String? customerId,
  }) async {
    errorMessage.value = null;
    final result = await _saleUseCase.call(
      productId: productId,
      qty: qty,
      actualSellPrice: actualSellPrice,
      amountReceivedNow: amountReceivedNow,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      customerId: customerId,
    );
    if (result.isErr) {
      errorMessage.value = result.failureOrNull!.message;
      return false;
    }
    return _markConverted(captureId, 'sale', result.valueOrNull!);
  }

  Future<bool> convertToPurchase({
    required String captureId,
    required String shopName,
    required String productId,
    required double qty,
    required Money unitPrice,
    required FundSource fundSource,
    bool isInKind = false,
  }) async {
    errorMessage.value = null;
    final tripId = _uuid.v7();
    await _purchaseUseCase.call(
      PurchaseTrip(
        id: tripId,
        date: DateTime.now(),
        transportCost: Money.zero(),
        cashReturned: Money.zero(),
        items: [
          PurchaseItem(
            id: _uuid.v7(),
            shopName: shopName,
            productId: productId,
            qty: qty,
            unitPrice: unitPrice,
            fundSource: fundSource,
            isInKind: isInKind,
          ),
        ],
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    return _markConverted(captureId, 'purchase', tripId);
  }

  Future<bool> _markConverted(
    String captureId,
    String convertedToType,
    String convertedToId,
  ) async {
    final result = await _captureUseCases.markConverted(
      captureId: captureId,
      convertedToType: convertedToType,
      convertedToId: convertedToId,
      shopId: defaultShopId,
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
