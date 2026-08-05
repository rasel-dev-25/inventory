import 'package:uuid/uuid.dart';

import '../local/app_database.dart';

const _uuid = Uuid();

/// Records one [AuditLogEntries] row — called explicitly by the specific
/// use cases that create/delete/restore a row, not auto-hooked into
/// [writeAndEnqueue] generically for every write in the app.
///
/// **Deliberately scoped down, flagged rather than oversold**: today this
/// only covers the delete/restore paths this PR touches
/// (`CustomerUseCases`, `OrderUseCases`, `ExpenseUseCases.softDelete`,
/// `DeletePurchaseTripUseCase`) — not every create/update across all
/// ~20 use cases in this app. Auditing "who changed the selling price"
/// (the spec's own example) would need this called from
/// `ProductUseCases.update` too, and isn't yet. Extending coverage is a
/// matter of adding one more call site each time, not a redesign.
///
/// [oldValueJson]/[newValueJson] are whatever the caller already has in
/// hand (e.g. a domain entity's own JSON-ish map) — this function does
/// no row-fetching of its own, matching every other lightweight write
/// helper in this directory.
///
/// **Local-only, like `AppSettings`/pricing settings** — this does not
/// enqueue an outbox event. `audit_log_entries` *is* in
/// `SyncTableRegistry.syncableTables` (so a future PR could push these),
/// but nothing here does yet; flagged, not silently assumed handled
/// elsewhere.
Future<void> recordAuditLog({
  required AppDatabaseV2 db,
  required String shopId,
  required String action,
  required String changedTableName,
  required String recordId,
  required DateTime now,
  String? oldValueJson,
  String? newValueJson,
}) {
  return db.auditLogDao.create(
    id: _uuid.v7(),
    shopId: shopId,
    action: action,
    changedTableName: changedTableName,
    recordId: recordId,
    oldValueJson: oldValueJson,
    newValueJson: newValueJson,
    now: now,
  );
}

/// The retention policy `lib/data/local/tables/audit.dart`'s own doc
/// comment flags as needed: on a phone, an unbounded audit log (and an
/// unbounded pile of soft-deleted rows nobody ever prunes) is the
/// fastest-growing thing in the database. [pruneAll] hard-deletes:
///
/// - Every [AuditLogEntries] row older than [auditLogRetentionDays].
/// - Every already-soft-deleted [Customers]/[Orders]/[Expenses] row
///   whose `deletedAt` is older than [recycleBinRetentionDays] — a real
///   `DELETE`, not another soft-delete; past this window there is no
///   more "restore" to protect.
///
/// [Expenses] rows past the window are hard-deleted here too even though
/// the recycle bin never offers a restore action for them (see
/// `RecycleBinController`'s own doc comment for why) — the retention
/// policy's job is freeing space, not deciding what's restorable; those
/// are independent concerns that happen to both apply to the same rows.
///
/// **PurchaseTrips is deliberately not pruned here** — see
/// `DeletePurchaseTripUseCase`'s own doc comment: nothing in the UI can
/// trigger that deletion yet, so there is nothing real to prune, and
/// hard-deleting a trip would need to cascade its `PurchaseItems`/
/// `PurchaseOtherCosts` too, which this scoped-down v1 doesn't attempt.
///
/// Not a real cron — same honest limitation `PricingSettingsController`'s
/// month-end refresh documents: this runs whenever a caller (today,
/// `AuditLogController`'s `onInit`) decides to call it, not on a fixed
/// schedule the app can guarantee while closed.
class RetentionPolicyUseCase {
  final AppDatabaseV2 db;

  RetentionPolicyUseCase(this.db);

  static const defaultAuditLogRetentionDays = 180;
  static const defaultRecycleBinRetentionDays = 90;

  Future<RetentionPruneResult> pruneAll({
    required String shopId,
    required DateTime now,
    int auditLogRetentionDays = defaultAuditLogRetentionDays,
    int recycleBinRetentionDays = defaultRecycleBinRetentionDays,
  }) async {
    final auditCutoff = now.subtract(Duration(days: auditLogRetentionDays));
    final binCutoff = now.subtract(Duration(days: recycleBinRetentionDays));

    final auditLogRowsDeleted = await db.auditLogDao.deleteOlderThan(
      shopId,
      auditCutoff,
    );
    final customersDeleted = await db.customerDao.hardDeleteOlderThan(
      shopId,
      binCutoff,
    );
    final ordersDeleted = await db.orderDao.hardDeleteOlderThan(
      shopId,
      binCutoff,
    );
    final expensesDeleted = await db.expenseDao.hardDeleteOlderThan(
      shopId,
      binCutoff,
    );

    return RetentionPruneResult(
      auditLogRowsDeleted: auditLogRowsDeleted,
      customersDeleted: customersDeleted,
      ordersDeleted: ordersDeleted,
      expensesDeleted: expensesDeleted,
    );
  }
}

class RetentionPruneResult {
  final int auditLogRowsDeleted;
  final int customersDeleted;
  final int ordersDeleted;
  final int expensesDeleted;

  const RetentionPruneResult({
    required this.auditLogRowsDeleted,
    required this.customersDeleted,
    required this.ordersDeleted,
    required this.expensesDeleted,
  });

  int get totalDeleted =>
      auditLogRowsDeleted + customersDeleted + ordersDeleted + expensesDeleted;
}
