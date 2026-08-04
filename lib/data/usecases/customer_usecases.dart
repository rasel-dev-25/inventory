import '../../domain/entities/customer.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
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
  final AppDatabaseV2 db;

  CustomerUseCases(this.db);

  Future<void> create(
    Customer customer, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
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
  }

  Future<void> update(
    Customer customer, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
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
  }

  Future<void> softDelete(
    String id, {
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
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
