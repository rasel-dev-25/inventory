import '../../core/error/result.dart';
import '../local/daos/sync_metadata_dao.dart';
import '../local/local_row_upserter.dart';
import 'enum_case_bridge.dart';
import 'shop_id_bridge.dart';
import 'sync_table_registry.dart';
import 'sync_transport.dart';

/// The cursor-based puller: for each syncable table, resumes from
/// [SyncMetadataDao]'s stored `(lastSyncedAt, lastSyncedId)` cursor,
/// applies every row Supabase returns to the local database via
/// [LocalRowUpserter] (substituting the real backend shop id back to
/// this device's local one — see [ShopIdBridge]), then advances the
/// cursor to the last row actually applied.
///
/// Conflict policy, stated explicitly rather than left implicit: pulled
/// data always overwrites local data for mutable tables (`ON CONFLICT
/// DO UPDATE`) — the server's `updated_at` is already
/// clock-authoritative (`clock_timestamp()`, not client-supplied; see
/// `0001_foundations.sql`), so "the server's copy wins" is not a
/// heuristic here, it is simply which copy is allowed to be newer.
/// Append-only tables use `ON CONFLICT DO NOTHING` both here and
/// server-side, so a row already present locally (e.g. this exact device
/// pushed it) is left untouched rather than re-applied.
class SyncPullService {
  static const _pageSize = 200;

  final SyncMetadataDao _dao;
  final SyncTransport _transport;
  final LocalRowUpserter _upserter;

  SyncPullService(this._dao, this._transport, this._upserter);

  /// Pulls every syncable table in turn. Order doesn't matter for
  /// correctness — local FK constraints are enforced by SQLite same as
  /// Postgres, but every table's own rows are independently upserted by
  /// id, and this app doesn't defer FK checks — so a child row for a
  /// parent this device hasn't pulled yet would fail its own insert. In
  /// practice this is a non-issue for now (single-owner-device MVP,
  /// nothing else writes rows this device doesn't already have), flagged
  /// here as the thing to revisit if a genuine multi-device conflict
  /// shows up before real dependency-ordering is worth building.
  Future<Result<int>> pullAll({required String remoteShopId}) async {
    var total = 0;
    for (final table in SyncTableRegistry.syncableTables) {
      final result = await pullTable(table, remoteShopId: remoteShopId);
      if (result.isErr) return result;
      total += result.valueOrNull!;
    }
    return Result.ok(total);
  }

  Future<Result<int>> pullTable(
    String table, {
    required String remoteShopId,
  }) async {
    var applied = 0;

    while (true) {
      final cursor = await _dao.cursorFor(table);
      final pageResult = await _transport.fetchSince(
        table: table,
        shopId: remoteShopId,
        afterSyncedAt: cursor?.lastSyncedAt,
        afterId: cursor?.lastSyncedId,
        limit: _pageSize,
      );

      if (pageResult.isErr) return Result.err(pageResult.failureOrNull!);
      final page = pageResult.valueOrNull!;
      if (page.isEmpty) break;

      for (final remoteRow in page.rows) {
        final withLocalShopId = ShopIdBridge.toLocal(
          remoteRow,
          remoteKey: 'shop_id',
          remoteShopId: remoteShopId,
        );
        final localRow = EnumCaseBridge.toLocal(table, withLocalShopId);
        await _upserter.upsert(table, localRow);
        applied++;
      }

      // Read straight off the raw remote row, not the local/enum-
      // substituted copy: synced_at/id are untouched by either bridge,
      // but this keeps the cursor unambiguously "the last row Supabase
      // actually returned", independent of what ShopIdBridge/
      // EnumCaseBridge do to other columns.
      final lastRemoteRow = page.rows.last;
      await _dao.upsertCursor(
        table: table,
        lastSyncedAt: DateTime.parse(
          lastRemoteRow['synced_at'] as String,
        ).toUtc(),
        lastSyncedId: lastRemoteRow['id'] as String,
      );

      if (page.rows.length < _pageSize) break;
    }

    return Result.ok(applied);
  }
}
