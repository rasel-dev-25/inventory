import '../../core/error/result.dart';
import 'outbox_event.dart';

/// One page of rows pulled for a single table, ordered ascending by
/// `(synced_at, id)` — see `SyncCursors` for why a pull cursor needs
/// both a timestamp and a tie-breaking id.
///
/// Deliberately does *not* carry the next cursor position as separate
/// fields: an earlier version did, and a test fixture that populated
/// `rows` without also populating those fields crashed
/// [SyncPullService] on a null check — two pieces of state that must
/// always agree, tracked in two places, is exactly the kind of bug this
/// project's `Money`/`Result` types exist to make impossible elsewhere.
/// [SyncPullService] instead reads `synced_at`/`id` directly off
/// `rows.last`, which are guaranteed present on every syncable table's
/// row and can never disagree with `rows` itself because they come from
/// the exact same object.
class RemotePage {
  final List<Map<String, Object?>> rows;

  const RemotePage({required this.rows});

  bool get isEmpty => rows.isEmpty;
}

/// The network boundary [SyncPushService]/[SyncPullService] depend on —
/// pure Dart, no Supabase import, so both services are testable with a
/// fake transport and a real in-memory local database, the same
/// fake-the-edge-keep-the-logic-real pattern `AuthController`'s tests use
/// for [AuthRepository].
abstract class SyncTransport {
  /// Calls `apply_outbox_event` with an already shop_id-substituted
  /// batch of upserts (see `ShopIdBridge`) — idempotent server-side on
  /// [idempotencyKey], so a retried call after a dropped response is
  /// always safe.
  Future<Result<void>> pushEvent({
    required String idempotencyKey,
    required List<TableUpsert> upserts,
  });

  /// Rows for [table] belonging to [shopId] with a sync position after
  /// ([afterSyncedAt], [afterId]) — both null means "from the
  /// beginning". Ordered by (synced_at, id) ascending, capped at
  /// [limit] so one call can never try to pull an entire table's history
  /// into memory at once.
  Future<Result<RemotePage>> fetchSince({
    required String table,
    required String shopId,
    required DateTime? afterSyncedAt,
    required String? afterId,
    int limit = 200,
  });
}
