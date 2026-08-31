import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import '../../../domain/entities/quick_capture.dart' as domain;
import '../app_database.dart';
import '../tables/quick_capture.dart';

part 'quick_capture_dao.g.dart';

extension _QuickCaptureRowMapping on QuickCaptureRow {
  domain.QuickCapture toDomain() {
    return domain.QuickCapture(
      id: id,
      type: type,
      fileLocalPath: fileLocalPath,
      status: status,
      createdAt: createdAt,
      convertedToType: convertedToType,
      convertedToId: convertedToId,
    );
  }
}

/// Data access for [QuickCaptures]. No `softDelete` — this table has no
/// `deletedAt` column (same gap `CategoryDao`'s own doc comment already
/// flags for [Categories]: hard deletes aren't yet syncable via
/// `apply_jsonb_upsert`, which only supports insert/update). A pending
/// capture that turns out to be junk stays in the pending list until
/// converted; not fixed here, tracked alongside the same gap for
/// categories.
@DriftAccessor(tables: [QuickCaptures])
class QuickCaptureDao extends DatabaseAccessor<AppDatabase>
    with _$QuickCaptureDaoMixin {
  QuickCaptureDao(super.db);

  Future<domain.QuickCapture?> getById(String id) async {
    final row = await (select(
      quickCaptures,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.QuickCapture>> watchAll(String shopId) {
    final query = select(quickCaptures)
      ..where((c) => c.shopId.equals(shopId))
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.QuickCapture capture, {
    required String shopId,
    required DateTime now,
  }) {
    return into(quickCaptures).insert(
      QuickCapturesCompanion.insert(
        id: capture.id,
        shopId: shopId,
        type: capture.type,
        fileLocalPath: capture.fileLocalPath,
        status: capture.status,
        createdAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Writes [QuickCaptureStatus.converted] and both `convertedTo*` fields
  /// together — the one place any of the three change after creation.
  Future<void> markConverted({
    required String id,
    required String convertedToType,
    required String convertedToId,
  }) {
    return (update(quickCaptures)..where((c) => c.id.equals(id))).write(
      QuickCapturesCompanion(
        status: const Value(QuickCaptureStatus.converted),
        convertedToType: Value(convertedToType),
        convertedToId: Value(convertedToId),
      ),
    );
  }

  Future<void> updateCapture({
    required String id,
    required String fileLocalPath,
    required DateTime now,
  }) {
    return (update(quickCaptures)..where((c) => c.id.equals(id))).write(
      QuickCapturesCompanion(
        fileLocalPath: Value(fileLocalPath),
        syncedAt: Value(now),
      ),
    );
  }

  Future<void> deleteCapture(String id) {
    return (delete(quickCaptures)..where((c) => c.id.equals(id))).go();
  }
}
