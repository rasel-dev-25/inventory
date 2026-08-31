import 'dart:convert';

import '../../domain/entities/customer.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'audit_log_usecases.dart';
import 'sync_enqueue_helper.dart';

/// Create/update/delete for [Customer] — same shape as [ProductUseCases]:
/// [CustomerDao] already builds the storage companion from a domain
/// entity, this layer additionally builds the matching outbox row from
/// the exact same [Customer]/[now] values and writes both together.
///
/// Unlike categories (see `CategoryUseCases`' own doc comment on why
/// category delete is unsupported), the remote `customers` table *does*
/// have a `deleted_at` column (`supabase/migrations/0003_core_tables.sql`),
/// so a soft-delete here is a real, syncable operation — [softDelete]
/// pushes a partial update setting only `deleted_at`, never touching the
/// customer's other columns (same partial-update reasoning as
/// `PayDueUseCase`'s `dues` upsert).
class CustomerUseCases {
  final AppDatabase db;

  CustomerUseCases(this.db);

  Future<void> create(
    Customer customer, {
    required String shopId,
    required DateTime now,
  }) async {
    await writeAndEnqueue(
      db: db,
      eventType: 'customer_created',
      upserts: [
        TableUpsert(
          table: 'customers',
          row: _rowFor(customer, shopId: shopId),
        ),
      ],
      localWrite: () =>
          db.customerDao.create(customer, shopId: shopId, now: now),
    );
    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'insert',
      changedTableName: 'customers',
      recordId: customer.id,
      now: now,
      newValueJson: jsonEncode(_rowFor(customer, shopId: shopId)),
    );
  }

  Future<void> update(
    Customer customer, {
    required String shopId,
    required DateTime now,
  }) async {
    final old = await db.customerDao.getById(customer.id);
    await writeAndEnqueue(
      db: db,
      eventType: 'customer_updated',
      upserts: [
        TableUpsert(
          table: 'customers',
          row: _rowFor(customer, shopId: shopId),
        ),
      ],
      localWrite: () =>
          db.customerDao.updateCustomer(customer, shopId: shopId, now: now),
    );
    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'update',
      changedTableName: 'customers',
      recordId: customer.id,
      now: now,
      oldValueJson: old != null ? jsonEncode(_rowFor(old, shopId: shopId)) : null,
      newValueJson: jsonEncode(_rowFor(customer, shopId: shopId)),
    );
  }

  /// Audit-logged (`action: 'delete'`, `oldValueJson` the customer as it
  /// stood before this call) — see `audit_log_usecases.dart`'s own doc
  /// comment for why this and [restore] are among the small, explicit
  /// set of call sites that write an audit entry today, not a generic
  /// hook every use case gets automatically.
  Future<void> softDelete(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    final existing = await db.customerDao.getById(id);

    await writeAndEnqueue(
      db: db,
      eventType: 'customer_deleted',
      upserts: [
        TableUpsert(
          table: 'customers',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.customerDao.softDelete(id, now),
    );

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'delete',
      changedTableName: 'customers',
      recordId: id,
      oldValueJson: existing == null
          ? null
          : jsonEncode(_rowFor(existing, shopId: shopId)),
      now: now,
    );
  }

  /// Un-deletes — see `CustomerDao.restore`'s own doc comment for why
  /// this is safe unconditionally for a customer (no paired cash/stock
  /// write to also undo). Not currently pushed to the outbox — restoring
  /// from the Recycle Bin is, like the bin itself, a local-only action
  /// today (flagged, not silently assumed to sync).
  Future<void> restore(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    await db.customerDao.restore(id, now);
    final restored = await db.customerDao.getById(id);

    await recordAuditLog(
      db: db,
      shopId: shopId,
      action: 'restore',
      changedTableName: 'customers',
      recordId: id,
      newValueJson: restored == null
          ? null
          : jsonEncode(_rowFor(restored, shopId: shopId)),
      now: now,
    );
  }

  Map<String, Object?> _rowFor(Customer customer, {required String shopId}) {
    return {
      'id': customer.id,
      'shop_id': shopId,
      'name': customer.name,
      'address': customer.address,
      'contact': customer.contact,
      'suspicion_flag': customer.suspicionFlag,
      'is_blocked': customer.isBlocked,
    };
  }
}
