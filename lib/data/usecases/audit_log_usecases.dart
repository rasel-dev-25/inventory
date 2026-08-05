import 'package:uuid/uuid.dart';

import '../local/app_database.dart';

const _uuid = Uuid();

/// Records one [AuditLogEntries] row — called explicitly by the specific
/// use cases that create/delete/restore a row, not auto-hooked into
/// [writeAndEnqueue] generically for every write in the app.
///
/// **Deliberately scoped down, flagged rather than oversold**: this
/// covers delete/restore on `CustomerUseCases`, `OrderUseCases`,
/// `ExpenseUseCases.softDelete`, `DeletePurchaseTripUseCase`,
/// `ProductUseCases.softDelete`/`restore`, and `FixedAssetUseCases.delete`
/// — plus create/update on `ProductUseCases` (the spec's own "who changed
/// the selling price" example) and the two `FixedAssetUseCases` create
/// paths. It does **not** cover every create/update across all ~20 use
/// cases in this app — `CustomerUseCases.create`/`update`,
/// `OrderUseCases.create`, and `ExpenseUseCases.create` remain unaudited,
/// for one. Extending coverage further is a matter of adding one more
/// call site each time, not a redesign.
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
  required AppDatabase db,
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
/// **[Products]/[FixedAssets]/[PurchaseTrips] are deliberately not
/// pruned here**, even though all three are now soft-deletable and
/// visible in the Recycle Bin:
/// - [Products] — `Products.id` is a foreign-key target for
///   `StockMovements`/`SaleItems`/`PurchaseItems`/`RentTiers`; a real
///   `DELETE` on a product with any real usage history would violate
///   those constraints. See `ProductDao`'s own doc comment.
/// - [PurchaseTrips] — hard-deleting a trip would need to cascade its
///   `PurchaseItems`/`PurchaseOtherCosts` too, which this scoped-down v1
///   doesn't attempt.
/// - [FixedAssets] — has no incoming foreign key today, so this one
///   could safely be added; left out to keep this change to what was
///   actually asked for (Recycle Bin visibility + delete UI triggers),
///   not a retention-policy expansion. A real gap, not a silent one.
///
/// **[Customers] — fixed, not just flagged, as of this change**:
/// [Customers] *does* have incoming foreign keys (`Dues`/`Orders`/
/// `RentTransactions`/`Sales` all reference `Customers.id`), and
/// [CustomerDao.hardDeleteOlderThan] used to run against every candidate
/// unconditionally — a customer with real order/sale/due/rent history
/// that sat soft-deleted past the retention window would have hit the
/// exact same FK-violation risk described above for [Products]. That was
/// a pre-existing gap (from the PR that first added this policy),
/// undetected because its own test only ever pruned a customer with no
/// linked history. `CustomerDao.hardDeleteOlderThan` now checks each
/// candidate for linked history first and skips any that have some,
/// leaving them soft-deleted rather than risking that violation — see
/// its own doc comment for the full reasoning.
///
/// Not a real cron — same honest limitation `PricingSettingsController`'s
/// month-end refresh documents: this runs whenever a caller (today,
/// `AuditLogController`'s `onInit`) decides to call it, not on a fixed
/// schedule the app can guarantee while closed.
class RetentionPolicyUseCase {
  final AppDatabase db;

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
