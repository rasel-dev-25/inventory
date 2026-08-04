import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../sync/outbox_event.dart';
import '../sync/sync_transport.dart';

/// [SyncTransport] backed by the real Supabase project — the only file
/// allowed to import `package:supabase_flutter` for sync, mirroring how
/// `SupabaseAuthRepository` is the one real edge for auth.
class SupabaseSyncTransport implements SyncTransport {
  final sb.SupabaseClient _client;

  SupabaseSyncTransport([sb.SupabaseClient? client])
    : _client = client ?? sb.Supabase.instance.client;

  @override
  Future<Result<void>> pushEvent({
    required String idempotencyKey,
    required List<TableUpsert> upserts,
  }) async {
    try {
      await _client.rpc(
        'apply_outbox_event',
        params: {
          'p_idempotency_key': idempotencyKey,
          'p_upserts': upserts.map((u) => u.toJson()).toList(),
        },
      );
      return const Result.ok(null);
    } on sb.PostgrestException catch (e) {
      // RLS rejection (e.g. a staff device somehow still has a
      // non-empty outbox) and the allow-list guard both surface here as
      // a plain Postgres exception — see apply_jsonb_upsert's body.
      if (e.code == '42501') {
        return Result.err(PermissionFailure(e.message));
      }
      return Result.err(UnknownFailure(e.message));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  @override
  Future<Result<RemotePage>> fetchSince({
    required String table,
    required String shopId,
    required DateTime? afterSyncedAt,
    required String? afterId,
    int limit = 200,
  }) async {
    try {
      var query = _client.from(table).select().eq('shop_id', shopId);

      // (synced_at, id) > (afterSyncedAt, afterId) as a single PostgREST
      // `or` filter — the tie-breaking id matters because two rows can
      // share the same synced_at down to the microsecond under load, and
      // a bare `synced_at.gt.X` filter would then silently skip whichever
      // of the tied rows sorts first.
      if (afterSyncedAt != null && afterId != null) {
        final iso = afterSyncedAt.toUtc().toIso8601String();
        query = query.or(
          'synced_at.gt.$iso,and(synced_at.eq.$iso,id.gt.$afterId)',
        );
      }

      final rows = await query.order('synced_at').order('id').limit(limit);
      final typedRows = rows
          .map((r) => Map<String, Object?>.from(r as Map))
          .toList();

      return Result.ok(RemotePage(rows: typedRows));
    } on sb.PostgrestException catch (e) {
      return Result.err(UnknownFailure(e.message));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }
}
