import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../sync/outbox_event.dart';
import '../sync/sync_transport.dart';

/// [SyncTransport] backed by the real Supabase project — the only file
/// allowed to import `package:supabase_flutter` for sync, mirroring how
/// `SupabaseAuthRepository` is the one real edge for auth.
class SupabaseSyncTransport implements SyncTransport {
  static const _tag = 'SyncTransport';

  final sb.SupabaseClient _client;

  SupabaseSyncTransport([sb.SupabaseClient? client])
    : _client = client ?? sb.Supabase.instance.client;

  // ── Push ────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> pushEvent({
    required String idempotencyKey,
    required List<TableUpsert> upserts,
  }) async {
    AppLogger.d(_tag, 'push  key=$idempotencyKey  tables=${upserts.map((u) => u.table).toList()}');
    try {
      await _client.rpc(
        'apply_outbox_event',
        params: {
          'p_idempotency_key': idempotencyKey,
          'p_upserts': upserts.map((u) => u.toJson()).toList(),
        },
      );
      AppLogger.i(_tag, 'push OK  key=$idempotencyKey');
      return const Result.ok(null);
    } on sb.PostgrestException catch (e) {
      AppLogger.e(_tag, 'push FAILED  key=$idempotencyKey  code=${e.code}  msg=${e.message}');
      // RLS rejection (e.g. a staff device somehow still has a
      // non-empty outbox) and the allow-list guard both surface here as
      // a plain Postgres exception — see apply_jsonb_upsert's body.
      if (e.code == '42501') {
        return Result.err(PermissionFailure(e.message));
      }
      return Result.err(UnknownFailure(e.message));
    } catch (e, st) {
      AppLogger.e(_tag, 'push FAILED  key=$idempotencyKey', error: e, stackTrace: st);
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  // ── Pull ────────────────────────────────────────────────────────────────

  /// Tables that have no direct `shop_id` column and instead scope to a shop
  /// through a parent table. Each entry maps the table name to:
  ///   - `parent`: the parent table name used in the join
  ///   - `fk`: the FK column on this table that references the parent
  ///   - `parentPk`: the parent's PK column (always `id`)
  ///   - `joinField`: the field on the embedded result to strip before upsert
  ///
  /// Migration reference:
  ///   - product_images   → products       (0003_core_tables.sql)
  ///   - purchase_items   → purchase_trips  (0004_transactional_tables.sql)
  ///   - purchase_other_costs → purchase_trips (0004_transactional_tables.sql)
  ///   - due_payments     → dues            (0005_ledger_and_audit.sql)
  static const _indirectShopId = <String, _IndirectTable>{
    'product_images': _IndirectTable(
      parent: 'products',
      fk: 'product_id',
      joinField: 'products',
    ),
    'purchase_items': _IndirectTable(
      parent: 'purchase_trips',
      fk: 'purchase_trip_id',
      joinField: 'purchase_trips',
    ),
    'purchase_other_costs': _IndirectTable(
      parent: 'purchase_trips',
      fk: 'purchase_trip_id',
      joinField: 'purchase_trips',
    ),
    'due_payments': _IndirectTable(
      parent: 'dues',
      fk: 'due_id',
      joinField: 'dues',
    ),
  };

  @override
  Future<Result<RemotePage>> fetchSince({
    required String table,
    required String shopId,
    required DateTime? afterSyncedAt,
    required String? afterId,
    int limit = 200,
  }) async {
    AppLogger.d(
      _tag,
      'pull  table=$table  after=${afterSyncedAt?.toIso8601String() ?? 'start'}  id=${afterId ?? '-'}',
    );

    try {
      final indirect = _indirectShopId[table];

      // Build the cursor filter string once — reused in both branches.
      // (synced_at, id) > (afterSyncedAt, afterId) as a single PostgREST
      // `or` — tie-breaking on id matters because two rows can share the
      // same synced_at under load; a bare synced_at.gt. would skip them.
      final String? cursorFilter =
          (afterSyncedAt != null && afterId != null)
          ? 'synced_at.gt.${afterSyncedAt.toUtc().toIso8601String()},'
            'and(synced_at.eq.${afterSyncedAt.toUtc().toIso8601String()},'
            'id.gt.$afterId)'
          : null;

      final List rawRows;

      if (indirect != null) {
        // Tables without a direct shop_id are scoped through a parent via
        // an embedded-resource join (PostgREST: parent!inner(shop_id)).
        // The nested parent object is stripped from the result before upsert.
        AppLogger.d(_tag, 'pull  $table uses indirect shop_id via ${indirect.parent}');
        var q = _client
            .from(table)
            .select('*, ${indirect.parent}!inner(shop_id)')
            .eq('${indirect.parent}.shop_id', shopId);
        if (cursorFilter != null) q = q.or(cursorFilter);
        rawRows = await q.order('synced_at').order('id').limit(limit);
      } else {
        var q = _client.from(table).select().eq('shop_id', shopId);
        if (cursorFilter != null) q = q.or(cursorFilter);
        rawRows = await q.order('synced_at').order('id').limit(limit);
      }

      // For indirect tables, remove the nested parent join object that
      // PostgREST adds — the local upserter expects a flat row.
      final List<Map<String, Object?>> typedRows;
      if (indirect != null) {
        typedRows = rawRows.map((r) {
          final m = Map<String, Object?>.from(r as Map);
          m.remove(indirect.joinField);
          return m;
        }).toList();
      } else {
        typedRows = rawRows
            .map((r) => Map<String, Object?>.from(r as Map))
            .toList();
      }


      AppLogger.d(_tag, 'pull  table=$table  got ${typedRows.length} rows');
      return Result.ok(RemotePage(rows: typedRows));
    } on sb.PostgrestException catch (e) {
      AppLogger.e(_tag, 'pull FAILED  table=$table  code=${e.code}  msg=${e.message}');
      return Result.err(UnknownFailure(e.message));
    } catch (e, st) {
      AppLogger.e(_tag, 'pull FAILED  table=$table', error: e, stackTrace: st);
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }
}

/// Metadata for a syncable table that reaches its shop via a parent FK.
class _IndirectTable {
  final String parent;    // parent table name
  final String fk;        // FK column on this table pointing at parent.id
  final String joinField; // key PostgREST adds to the row (same as parent)

  const _IndirectTable({
    required this.parent,
    required this.fk,
    required this.joinField,
  });
}
