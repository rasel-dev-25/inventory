import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';

/// Backs the v2 Audit Log screen — a read-only view over
/// [AuditLogEntries], per that table's own doc comment ("who changed the
/// selling price?"). See `audit_log_usecases.dart`'s own doc comment for
/// exactly which actions are recorded today (delete/restore on
/// Customers/Orders/Expenses, delete on PurchaseTrips) — not yet every
/// create/update across the app.
class AuditLogController extends GetxController {
  final AppDatabaseV2 db;

  AuditLogController(this.db);

  final entries = <AuditLogEntryRow>[].obs;

  StreamSubscription<Object?>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = db.auditLogDao
        .watchAll(defaultShopId)
        .listen((rows) => entries.assignAll(rows));
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
