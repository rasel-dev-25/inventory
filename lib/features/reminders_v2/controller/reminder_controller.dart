import 'dart:async';

import 'package:get/get.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/services/reminder_engine.dart';

/// Backs the v2 Reminders screen — the single inbox for every reminder
/// source `notes/business_logic.md` calls out (§ছ Due, §ঙ Investor, §জ
/// suspicious-customer/overdue-rent), computed via `reminder_engine.dart`
/// from live-watched data. See `CatalogScreen`'s doc comment for why
/// this reads the v2 database only.
///
/// Also the one place that decides when to push a real Android
/// notification — every time the computed inbox changes, any reminder
/// this session hasn't already notified about gets one via
/// [NotificationService.show]. [_notifiedReminderIds] is deliberately
/// in-memory only, not persisted: a fresh app session re-notifies about
/// anything still outstanding, which is the honest, simple behavior for
/// a reminder that (by definition) hasn't been resolved yet — see
/// `NotificationService`'s own doc comment for the bigger, deliberately
/// out-of-scope limitation this shares (foreground-triggered only, no
/// exact-alarm wake-the-device scheduling).
class ReminderController extends GetxController {
  final AppDatabaseV2 db;
  final NotificationService notificationService;

  ReminderController(this.db, this.notificationService);

  final dues = <Due>[].obs;
  final investors = <Investor>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final customers = <Customer>[].obs;
  final rentals = <RentTransaction>[].obs;
  final products = <Product>[].obs;

  final _notifiedReminderIds = <String>{};

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.dueDao.watchAll(defaultShopId).listen((rows) {
        dues.assignAll(rows);
        _notifyNewReminders();
      }),
    );
    _subscriptions.add(
      db.investorDao.watchAll(defaultShopId).listen((rows) {
        investors.assignAll(rows);
        _notifyNewReminders();
      }),
    );
    _subscriptions.add(
      db.purchaseDao.watchAll(defaultShopId).listen((rows) {
        purchaseTrips.assignAll(rows);
        _notifyNewReminders();
      }),
    );
    _subscriptions.add(
      db.customerDao.watchAll(defaultShopId).listen((rows) {
        customers.assignAll(rows);
        _notifyNewReminders();
      }),
    );
    _subscriptions.add(
      db.rentDao.watchAll(defaultShopId).listen((rows) {
        rentals.assignAll(rows);
        _notifyNewReminders();
      }),
    );
    _subscriptions.add(
      db.productDao.watchAll(defaultShopId).listen((rows) {
        products.assignAll(rows);
        _notifyNewReminders();
      }),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  String _customerNameOf(String id) =>
      customers.where((c) => c.id == id).firstOrNull?.name ?? id;

  String _bookNameOf(String id) =>
      products.where((p) => p.id == id).firstOrNull?.name ?? id;

  List<Reminder> get inbox {
    return buildReminderInbox(
      dues: dues,
      customerNameOf: _customerNameOf,
      investors: investors,
      purchaseTrips: purchaseTrips,
      customers: customers,
      rentals: rentals,
      bookNameOf: _bookNameOf,
      now: DateTime.now().toUtc(),
    );
  }

  List<Reminder> get overdueOnly {
    final now = DateTime.now().toUtc();
    return inbox.where((r) => r.isOverdueAsOf(now)).toList();
  }

  void _notifyNewReminders() {
    final now = DateTime.now().toUtc();
    for (final reminder in inbox) {
      if (!reminder.isOverdueAsOf(now)) continue;
      if (_notifiedReminderIds.contains(reminder.id)) continue;
      _notifiedReminderIds.add(reminder.id);
      notificationService.show(
        id: reminder.id.hashCode & 0x7fffffff,
        title: 'reminderNotificationTitle'.tr,
        body: _bodyFor(reminder),
      );
    }
  }

  String _bodyFor(Reminder reminder) {
    return switch (reminder) {
      DueBalanceReminder r =>
        '${'reminderDueBody'.tr}${r.customerName} · ${r.remaining.format()}',
      InvestorCapitalReturnReminder r =>
        '${'reminderInvestorCapitalBody'.tr}${r.investor.name}',
      InvestorProfitPayoutReminder r =>
        '${'reminderInvestorPayoutBody'.tr}${r.investor.name}',
      SuspiciousCustomerReminder r =>
        '${'reminderSuspiciousBody'.tr}${r.customer.name}',
      OverdueRentReminder r =>
        '${'reminderOverdueRentBody'.tr}${r.customerName} · ${r.bookName}',
    };
  }
}
