import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/services/reminder_engine.dart';

/// Backs the v2 Reminders screen — the single inbox for every reminder
/// source `notes/business_logic.md` calls out (§ছ Due, §ঙ Investor, §জ
/// suspicious-customer/overdue-rent), computed via `reminder_engine.dart`
/// with support for user acknowledgement / ticking / resolving alerts.
class ReminderController extends GetxController {
  final AppDatabase db;
  final NotificationService notificationService;
  static const _resolvedSettingsKey = 'resolved_reminder_ids_v1';

  ReminderController(this.db, this.notificationService);

  final dues = <Due>[].obs;
  final investors = <Investor>[].obs;
  final purchaseTrips = <PurchaseTrip>[].obs;
  final customers = <Customer>[].obs;
  final rentals = <RentTransaction>[].obs;
  final products = <Product>[].obs;
  final orders = <Order>[].obs;

  final resolvedReminderIds = <String>{}.obs;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.dueDao.watchAll(defaultShopId).listen((rows) {
        dues.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.investorDao.watchAll(defaultShopId).listen((rows) {
        investors.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.purchaseDao.watchAll(defaultShopId).listen((rows) {
        purchaseTrips.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.customerDao.watchAll(defaultShopId).listen((rows) {
        customers.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.rentDao.watchAll(defaultShopId).listen((rows) {
        rentals.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.productDao.watchAll(defaultShopId).listen((rows) {
        products.assignAll(rows);
      }),
    );
    _subscriptions.add(
      db.orderDao.watchAll(defaultShopId).listen((rows) {
        orders.assignAll(rows);
      }),
    );
    loadResolvedReminders();
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  // ── Resolution / Ticking Logic ──────────────────────────────────────────

  Future<void> loadResolvedReminders() async {
    try {
      final raw = await db.appSettingsDao.get(_resolvedSettingsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
        resolvedReminderIds.assignAll(list);
      }
    } catch (_) {}
  }

  Future<void> _persistResolvedReminders() async {
    final raw = jsonEncode(resolvedReminderIds.toList());
    await db.appSettingsDao.upsert(_resolvedSettingsKey, raw);
  }

  bool isResolved(String id) => resolvedReminderIds.contains(id);

  void toggleResolved(String id) {
    if (resolvedReminderIds.contains(id)) {
      resolvedReminderIds.remove(id);
    } else {
      resolvedReminderIds.add(id);
    }
    _persistResolvedReminders();
  }

  void markAllResolved() {
    for (final r in inbox) {
      resolvedReminderIds.add(r.id);
    }
    _persistResolvedReminders();
  }

  void markAllLowStockResolved() {
    for (final r in inbox.whereType<LowStockReminder>()) {
      resolvedReminderIds.add(r.id);
    }
    _persistResolvedReminders();
  }

  void unresolveAll() {
    resolvedReminderIds.clear();
    _persistResolvedReminders();
  }

  // ── Inbox Computed Data ─────────────────────────────────────────────────

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
      orders: orders,
      products: products,
      now: DateTime.now().toUtc(),
    );
  }

  List<Reminder> get overdueOnly {
    final now = DateTime.now().toUtc();
    return inbox.where((r) => r.isOverdueAsOf(now)).toList();
  }

  List<Reminder> get activeInbox =>
      inbox.where((r) => !isResolved(r.id)).toList();

  List<Reminder> get resolvedInbox =>
      inbox.where((r) => isResolved(r.id)).toList();

  int get totalCount => inbox.length;
  int get activeCount => activeInbox.length;
  int get resolvedCount => resolvedInbox.length;

  int get overdueCount => overdueOnly.length;
  int get activeOverdueCount =>
      overdueOnly.where((r) => !isResolved(r.id)).length;

  int get lowStockCount => inbox.whereType<LowStockReminder>().length;
  int get activeLowStockCount => inbox
      .whereType<LowStockReminder>()
      .where((r) => !isResolved(r.id))
      .length;

  int get dueCount => inbox.whereType<DueBalanceReminder>().length;
  int get activeDueCount => inbox
      .whereType<DueBalanceReminder>()
      .where((r) => !isResolved(r.id))
      .length;

  int get orderCount => inbox.whereType<OrderDeadlineReminder>().length;
  int get suspiciousCount =>
      inbox.whereType<SuspiciousCustomerReminder>().length;

  bool get hasAnyActiveAlerts => activeCount > 0;
  bool get allResolvedToday => inbox.isNotEmpty && activeCount == 0;

  String get activeAlertSummaryText {
    final parts = <String>[];
    if (activeLowStockCount > 0) {
      parts.add('$activeLowStockCountটি পণ্যের স্টক কম');
    }
    if (activeDueCount > 0) {
      parts.add('$activeDueCountটি বকেয়া রিমাইন্ডার');
    }
    final activeOrders = inbox
        .whereType<OrderDeadlineReminder>()
        .where((r) => !isResolved(r.id))
        .length;
    if (activeOrders > 0) {
      parts.add('$activeOrdersটি অর্ডার ডেলিভারি');
    }
    if (parts.isEmpty && activeOverdueCount > 0) {
      parts.add('$activeOverdueCountটি জরুরি রিমাইন্ডার');
    }
    return parts.join(' এবং ');
  }

  String get alertSummaryText => activeAlertSummaryText;
}
