import 'package:uuid/uuid.dart';

import '../../domain/entities/product_unit.dart';
import '../local/app_database.dart';
import '../local/daos/unit_dao.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create/rename/delete use cases for [Units] — writes locally and
/// enqueues the matching outbox event for Supabase cloud sync.
class UnitUseCases {
  final AppDatabase db;
  static const _uuid = Uuid();

  UnitUseCases(this.db);

  Stream<List<ProductUnit>> watchAll(String shopId) =>
      db.unitDao.watchAll(shopId);

  Future<List<ProductUnit>> getAll(String shopId) =>
      db.unitDao.getAll(shopId);

  Future<ProductUnit> create({
    required String shopId,
    required String name,
    int sortOrder = 0,
    required DateTime now,
  }) async {
    final unitId = _uuid.v7();
    final unit = ProductUnit(
      id: unitId,
      name: name.trim(),
      sortOrder: sortOrder,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'unit_created',
      upserts: [
        TableUpsert(
          table: 'units',
          row: {
            'id': unit.id,
            'shop_id': shopId,
            'name': unit.name,
            'sort_order': unit.sortOrder,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'synced_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.unitDao.create(
        id: unit.id,
        shopId: shopId,
        name: unit.name,
        sortOrder: unit.sortOrder,
        now: now,
      ),
    );

    return unit;
  }

  Future<void> rename({
    required String id,
    required String shopId,
    required String name,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'unit_renamed',
      upserts: [
        TableUpsert(
          table: 'units',
          row: {
            'id': id,
            'shop_id': shopId,
            'name': name.trim(),
            'updated_at': now.toIso8601String(),
            'synced_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.unitDao.rename(
        id: id,
        name: name.trim(),
        now: now,
      ),
    );
  }

  Future<void> delete({
    required String id,
    required String shopId,
    required DateTime now,
  }) {
    return writeAndEnqueue(
      db: db,
      eventType: 'unit_deleted',
      upserts: [
        TableUpsert(
          table: 'units',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'synced_at': now.toIso8601String(),
          },
        ),
      ],
      localWrite: () => db.unitDao.softDelete(
        id: id,
        now: now,
      ),
    );
  }

  Future<void> restoreDefaults({
    required String shopId,
    required DateTime now,
  }) async {
    for (int i = 0; i < UnitDao.defaultUnitNames.length; i++) {
      final name = UnitDao.defaultUnitNames[i];
      final existing = await db.unitDao.getByName(shopId, name);

      if (existing != null) {
        if (existing.deletedAt != null) {
          await writeAndEnqueue(
            db: db,
            eventType: 'unit_created',
            upserts: [
              TableUpsert(
                table: 'units',
                row: {
                  'id': existing.id,
                  'shop_id': shopId,
                  'name': existing.name,
                  'sort_order': existing.sortOrder,
                  'deleted_at': null,
                  'updated_at': now.toIso8601String(),
                  'synced_at': now.toIso8601String(),
                },
              ),
            ],
            localWrite: () => db.unitDao.restore(
              id: existing.id,
              now: now,
            ),
          );
        }
      } else {
        await create(
          shopId: shopId,
          name: name,
          sortOrder: i + 1,
          now: now,
        );
      }
    }
  }
}
