import 'dart:async';

import 'package:get/get.dart';

import '../../../core/money/money.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/pay_due_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/due_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/services/due_lifecycle.dart';

/// Grouping of all active dues for a specific customer.
class CustomerDueGroup {
  final Customer? customer;
  final String customerId;
  final String customerName;
  final String? customerContact;
  final List<Due> dues;
  final Money totalOriginalAmount;
  final Money totalRemainingAmount;
  final bool hasOverdue;
  final DateTime? latestPromisedDate;
  final int dueCount;

  const CustomerDueGroup({
    required this.customer,
    required this.customerId,
    required this.customerName,
    required this.customerContact,
    required this.dues,
    required this.totalOriginalAmount,
    required this.totalRemainingAmount,
    required this.hasOverdue,
    required this.latestPromisedDate,
    required this.dueCount,
  });
}

/// Backs the Dues screen — customer-grouped outstanding balance tracking,
/// individual and cascading batch payments, via [PayDueUseCase].
class DuesController extends GetxController {
  final AppDatabase db;

  DuesController(this.db);

  late final PayDueUseCase _useCase = PayDueUseCase(db);

  final dues = <Due>[].obs;
  final customers = <Customer>[].obs;
  final duePayments = <DuePayment>[].obs;

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
    _subscriptions.add(
      db.dueDao
          .watchAllPayments()
          .listen((rows) => duePayments.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  /// Unsettled dues only (pending/partially_paid), most recently created first.
  List<Due> get outstandingDues {
    final open = dues.where((d) => d.status != DueStatus.paid).toList();
    open.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return open;
  }

  Customer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  String customerName(String id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  Money remainingOf(Due due) => remainingBalance(due);

  bool dueIsOverdue(Due due) => isOverdue(due, DateTime.now());

  Money get totalDuesAmount {
    return outstandingDues.fold(
      Money.zero(),
      (acc, due) => acc + remainingBalance(due),
    );
  }

  int get totalDueCustomersCount => customerDueGroups.length;

  int get totalOverdueCount {
    final now = DateTime.now();
    return outstandingDues.where((d) => isOverdue(d, now)).length;
  }

  /// Total payments collected against dues across all time.
  Money get totalCollectedAmount {
    return duePayments.fold(
      Money.zero(),
      (acc, p) => acc + p.amount,
    );
  }

  /// Returns all payments made towards a specific due, newest first.
  List<DuePayment> paymentsForDue(String dueId) {
    final list = duePayments.where((p) => p.dueId == dueId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Returns all payments made by a customer across all their dues, newest first.
  List<DuePayment> paymentsForCustomer(String customerId) {
    final customerDueIds = dues
        .where((d) => d.customerId == customerId)
        .map((d) => d.id)
        .toSet();
    final list = duePayments
        .where((p) => customerDueIds.contains(p.dueId))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Total money received from a specific customer across all their dues.
  Money totalCollectedForCustomer(String customerId) {
    return paymentsForCustomer(customerId).fold(
      Money.zero(),
      (acc, p) => acc + p.amount,
    );
  }

  /// Groups all active dues by Customer so a single customer never appears
  /// multiple times in the list, but rather has one consolidated card.
  List<CustomerDueGroup> get customerDueGroups {
    final open = outstandingDues;
    final Map<String, List<Due>> map = {};
    for (final due in open) {
      map.putIfAbsent(due.customerId, () => []).add(due);
    }

    final now = DateTime.now();
    final groups = <CustomerDueGroup>[];

    map.forEach((customerId, customerDues) {
      // Sort oldest first so cascading payments resolve the oldest debt first
      customerDues.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final customer = customerById(customerId);
      final totalOriginal = customerDues.fold(
        Money.zero(),
        (acc, d) => acc + d.originalAmount,
      );
      final totalRemaining = customerDues.fold(
        Money.zero(),
        (acc, d) => acc + remainingBalance(d),
      );
      final hasOverdue = customerDues.any((d) => isOverdue(d, now));

      DateTime? latestDate;
      for (final d in customerDues) {
        final p = promisedByDate(d);
        if (p != null) {
          if (latestDate == null || p.isAfter(latestDate)) {
            latestDate = p;
          }
        }
      }

      groups.add(
        CustomerDueGroup(
          customer: customer,
          customerId: customerId,
          customerName: customer?.name ?? customerId,
          customerContact: customer?.contact,
          dues: customerDues,
          totalOriginalAmount: totalOriginal,
          totalRemainingAmount: totalRemaining,
          hasOverdue: hasOverdue,
          latestPromisedDate: latestDate,
          dueCount: customerDues.length,
        ),
      );
    });

    // Sort: Overdue customers first, then highest remaining balance
    groups.sort((a, b) {
      if (a.hasOverdue && !b.hasOverdue) return -1;
      if (!a.hasOverdue && b.hasOverdue) return 1;
      return b.totalRemainingAmount.compareTo(a.totalRemainingAmount);
    });

    return groups;
  }

  /// Pay against an individual single [Due].
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

  /// Pay against a customer's total outstanding balance across all their dues.
  /// Applies the payment to the oldest unpaid due first (FIFO).
  Future<bool> payCustomerBalance({
    required String customerId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;

    final customerDues = outstandingDues
        .where((d) => d.customerId == customerId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (customerDues.isEmpty) {
      isSaving.value = false;
      errorMessage.value = 'No outstanding dues for this customer';
      return false;
    }

    var remainingToPay = paymentAmount;
    final now = DateTime.now().toUtc();
    final today = DateTime.now();

    for (final due in customerDues) {
      if (remainingToPay <= Money.zero()) break;

      final dueRemaining = remainingBalance(due);
      final payThis = remainingToPay <= dueRemaining ? remainingToPay : dueRemaining;

      final result = await _useCase.call(
        dueId: due.id,
        paymentAmount: payThis,
        paymentMethod: paymentMethod,
        shopId: defaultShopId,
        date: today,
        now: now,
      );

      if (result.isErr) {
        isSaving.value = false;
        errorMessage.value = result.failureOrNull?.message;
        return false;
      }

      remainingToPay = remainingToPay - payThis;
    }

    isSaving.value = false;
    return true;
  }
}
