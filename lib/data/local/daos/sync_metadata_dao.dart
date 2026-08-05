import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync.dart';

part 'sync_metadata_dao.g.dart';

/// Data access for the two local sync-bookkeeping tables: the outbox
/// queue ([SyncOutboxEntries]) and the per-table pull cursor
/// ([SyncCursors]). Kept as one DAO rather than two — unlike a business
/// aggregate, neither table has a meaningful domain entity of its own;
/// both are pure sync-engine plumbing consumed only by
/// `lib/data/sync/sync_push_service.dart` and `sync_pull_service.dart`.
@DriftAccessor(tables: [SyncOutboxEntries, SyncCursors])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  // ── Outbox ─────────────────────────────────────────────────────────

  Future<void> enqueue({
    required String id,
    required String eventType,
    required String idempotencyKey,
    required String payloadJson,
    required DateTime now,
  }) {
    return into(syncOutboxEntries).insert(
      SyncOutboxEntriesCompanion.insert(
        id: id,
        eventType: eventType,
        idempotencyKey: idempotencyKey,
        payloadJson: payloadJson,
        status: 'pending',
        createdAt: now,
      ),
    );
  }

  /// Entries ready to (re-)attempt — `pending` from a fresh enqueue, or
  /// `failed` from a previous attempt worth retrying. `inFlight` is
  /// deliberately excluded: [SyncPushService] sets that status for the
  /// duration of one push attempt so a concurrent call (e.g. a manual
  /// "sync now" tap while a background push is already running) can't
  /// double-send the same event — see `sync_push_service.dart`.
  Future<List<SyncOutboxEntryRow>> pendingEntries({int limit = 20}) {
    return (select(syncOutboxEntries)
          ..where((t) => t.status.isIn(['pending', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Live count of pending/failed entries — backs the "Sync Now" badge
  /// (`SyncController.pendingOutboxCount`) so an owner can see there's
  /// something worth syncing without opening the outbox table itself.
  Stream<int> watchPendingCount() {
    final query = select(syncOutboxEntries)
      ..where((t) => t.status.isIn(['pending', 'failed']));
    return query.watch().map((rows) => rows.length);
  }

  Future<void> markInFlight(String id, DateTime now) {
    return (update(syncOutboxEntries)..where((t) => t.id.equals(id))).write(
      SyncOutboxEntriesCompanion(
        status: const Value('inFlight'),
        lastAttemptAt: Value(now),
      ),
    );
  }

  /// A successfully-applied event is deleted outright rather than kept
  /// with a `done` status — once the server has ack'd it, there is
  /// nothing left to retry or inspect; keeping it around would only grow
  /// the outbox table forever for no benefit `processed_outbox_events`
  /// (server-side) doesn't already provide for idempotency purposes.
  Future<void> markDone(String id) {
    return (delete(syncOutboxEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markFailed(String id, String error, DateTime now) {
    return (update(syncOutboxEntries)..where((t) => t.id.equals(id))).write(
      SyncOutboxEntriesCompanion(
        status: const Value('failed'),
        lastAttemptAt: Value(now),
        lastError: Value(error),
        attemptCount: Value.absent(),
      ),
    );
  }

  /// Separate from [markFailed] so callers don't have to read-then-write
  /// just to bump a counter — increments atomically in SQL.
  Future<void> incrementAttemptCount(String id) {
    return customStatement(
      'UPDATE sync_outbox_entries SET attempt_count = attempt_count + 1 WHERE id = ?',
      [id],
    );
  }

  // ── Cursor ─────────────────────────────────────────────────────────

  Future<SyncCursorRow?> cursorFor(String table) {
    return (select(
      syncCursors,
    )..where((t) => t.syncedTableName.equals(table))).getSingleOrNull();
  }

  Future<void> upsertCursor({
    required String table,
    required DateTime lastSyncedAt,
    required String? lastSyncedId,
  }) {
    return into(syncCursors).insertOnConflictUpdate(
      SyncCursorsCompanion.insert(
        syncedTableName: table,
        lastSyncedAt: lastSyncedAt,
        lastSyncedId: Value(lastSyncedId),
      ),
    );
  }
}
