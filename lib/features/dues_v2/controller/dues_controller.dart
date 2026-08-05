import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/pay_due_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/services/due_lifecycle.dart';

/// Backs the Dues screen — outstanding-balance tracking and paydown, via
/// [PayDueUseCase]. Embedded directly in `ShellScreen` — see that
/// class's own doc comment.
class DuesController extends GetxController {
  final AppDatabase db;

  DuesController(this.db);

  late final PayDueUseCase _useCase = PayDueUseCase(db);

  final dues = <Due>[].obs;
  final customers = <Customer>[].obs;

  final isSaving = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.dueDao.watchAll(defaultShopId).listen((rows) => dues.assignAll(rows)),
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

  /// Unsettled dues only (pending/partially_paid), most recently created
  /// first — a fully paid due has nothing left for this screen to show.
  List<Due> get outstandingDues {
    final open = dues.where((d) => d.status != DueStatus.paid).toList();
    open.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return open;
  }

  String customerName(String id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  Money remainingOf(Due due) => remainingBalance(due);

  bool dueIsOverdue(Due due) => isOverdue(due, DateTime.now());

  /// Returns `null` on success, or a user-facing error message on failure —
  /// [PayDueUseCase] already validates the overpay/already-settled rules
  /// via [Result], this just unwraps that into the shape the dialog wants.
  Future<bool> payDue({
    required String dueId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    final result = await _useCase.call(
      dueId: dueId,
      paymentAmount: paymentAmount,
      paymentMethod: paymentMethod,
      shopId: defaultShopId,
      date: DateTime.now(),
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
