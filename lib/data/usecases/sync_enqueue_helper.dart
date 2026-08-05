import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../sync/outbox_event.dart';

const _uuid = Uuid();

/// Writes locally and enqueues the matching outbox event in the same
/// Drift transaction, so the two can never disagree — if the app crashes
/// between them, either both happened or neither did.
///
/// [localWrite] is expected to already be wrapped in whatever nested
/// transaction its own DAO method opens (e.g. `PurchaseDao.saveTrip`) —
/// Drift nests a `transaction()` called from inside another one as a
/// savepoint automatically, so calling an existing DAO method here does
/// not lose atomicity, it just joins this outer transaction.
///
/// [upserts] must describe exactly the rows [localWrite] wrote, in the
/// shape `apply_outbox_event` expects (`supabase/migrations/
/// 0008_outbox_sync_rpc.sql`) — see each use case in this directory for
/// how that's built alongside the typed DAO call so the two can't drift
/// apart from having been computed independently.
Future<void> writeAndEnqueue({
  required AppDatabase db,
  required String eventType,
  required List<TableUpsert> upserts,
  required Future<void> Function() localWrite,
}) async {
  final idempotencyKey = _uuid.v7();
  await db.transaction(() async {
    await localWrite();
    await db.syncMetadataDao.enqueue(
      id: _uuid.v7(),
      eventType: eventType,
      // Same key used both as the outbox row's own idempotency column
      // (what SyncPushService actually sends to apply_outbox_event) and
      // inside the encoded payload — the two must never diverge, even
      // though only the column is consulted by the pusher today.
      idempotencyKey: idempotencyKey,
      payloadJson: OutboxEvent(
        idempotencyKey: idempotencyKey,
        upserts: upserts,
      ).encodePayload(),
      now: DateTime.now().toUtc(),
    );
  });
}
