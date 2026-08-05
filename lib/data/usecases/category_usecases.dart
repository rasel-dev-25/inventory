import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create/rename/reorder for [Categories] — writes locally and enqueues
/// the matching outbox event together. See `CategoryDao`'s doc comment
/// for why there is no delete here.
class CategoryUseCases {
  final AppDatabase db;

  CategoryUseCases(this.db);

  Future<void> create({
    required String id,
    required String shopId,
    required String name,
    required int sortOrder,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'category_created',
      upserts: [
        TableUpsert(
          table: 'categories',
          row: {
            'id': id,
            'shop_id': shopId,
            'name': name,
            'sort_order': sortOrder,
          },
        ),
      ],
      localWrite: () => db.categoryDao.create(
        id: id,
        shopId: shopId,
        name: name,
        sortOrder: sortOrder,
      ),
    );
  }

  Future<void> rename({
    required String id,
    required String shopId,
    required String name,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'category_renamed',
      // apply_jsonb_upsert's UPDATE SET clause only touches the columns
      // actually present in this payload (see its jsonb_object_keys
      // loop) — omitting sort_order here correctly leaves the remote
      // row's sort_order untouched, it does not reset it to a default.
      upserts: [
        TableUpsert(
          table: 'categories',
          row: {'id': id, 'shop_id': shopId, 'name': name},
        ),
      ],
      localWrite: () => db.categoryDao.rename(id, name),
    );
  }

  Future<void> reorder({
    required String id,
    required String shopId,
    required int sortOrder,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'category_reordered',
      upserts: [
        TableUpsert(
          table: 'categories',
          row: {'id': id, 'shop_id': shopId, 'sort_order': sortOrder},
        ),
      ],
      localWrite: () => db.categoryDao.reorder(id, sortOrder),
    );
  }
}
