import 'package:drift/drift.dart';

/// The hand-rolled outbox queue — see the working plan's SYNC design.
/// One row per business *event* (not per table row): [payload] carries the
/// already-resolved row-level mutations for that event as JSON, computed
/// once on the client, so the server applies them atomically without
/// needing to re-derive any business rule. [idempotencyKey] is generated
/// once per event and reused across every retry, so a flaky connection can
/// never cause the same event to apply twice server-side.
class SyncOutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get payloadJson => text()();

  TextColumn get status =>
      text()(); // 'pending' | 'inFlight' | 'failed' | 'done'
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A queued image upload — separate from [SyncOutboxEntries] because
/// images upload as raw bytes to Storage, not as a JSON mutation through
/// the same RPC. [priority] lets thumbnails jump ahead of full-size images
/// so lists populate quickly on a slow connection.
class SyncPendingUploads extends Table {
  TextColumn get id => text()();
  TextColumn get localPath => text()();
  TextColumn get storagePath => text()();
  TextColumn get bucketName => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The incremental-pull cursor per remote table — see the working plan's
/// SYNC design for why this uses `(lastSyncedAt, lastSyncedId)` rather
/// than a bare timestamp (ties at the same millisecond need a tie-breaker).
class SyncCursors extends Table {
  // Named syncedTableName, not tableName: see the identical note on
  // AuditLogEntries.changedTableName in audit.dart — `tableName` collides
  // with Drift's own table-name-override convention.
  TextColumn get syncedTableName => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get lastSyncedId => text().nullable()();

  @override
  Set<Column> get primaryKey => {syncedTableName};
}
