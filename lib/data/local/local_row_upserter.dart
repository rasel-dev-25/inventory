import '../sync/sync_table_registry.dart';
import 'app_database.dart';

/// Applies one row pulled from Supabase to the matching local SQLite
/// table via a parameterized raw upsert, mirroring
/// `apply_jsonb_upsert`'s server-side dynamic-SQL approach
/// (`supabase/migrations/0008_outbox_sync_rpc.sql`) rather than needing a
/// hand-written typed DAO method per one of the 22 syncable tables.
///
/// Safe against SQL injection the same way a typed Drift query is:
/// column names come only from [SyncTableRegistry]'s fixed allow-list
/// checked against the row's own keys (never interpolated from anything
/// externally supplied beyond "is this key present"), and every value is
/// bound as a `?` parameter, never string-interpolated.
///
/// Relies on the local Drift schema's column names matching the remote
/// Postgres column names byte-for-byte where both sides do have the
/// column — true today because Drift's default Dart-camelCase-to-SQL-
/// snake_case naming (`lib/data/local/app_database.g.dart` — e.g.
/// `shopId` → `shop_id`) happens to line up exactly with Postgres's own
/// snake_case convention; see ARCHITECTURE.md's note that the two
/// schemas are deliberately kept mirrored for this reason.
///
/// That mirroring is not total, though: some tables track more on the
/// server than locally. `categories`, for instance, has
/// `created_at`/`updated_at`/`synced_at` remotely (every mutable table
/// gets them, for RLS/sync bookkeeping) but the local `Categories` table
/// has none of the three — nothing local ever reads them, so there was
/// no reason to carry them. A pulled row is filtered down to the columns
/// [_localColumnTypes] finds via `PRAGMA table_info`, rather than assumed
/// to match 1:1, so a remote-only column like that doesn't blow up the
/// generated INSERT.
///
/// Two value formats also need converting before they can be bound
/// as-is, both caught by writing a real round-trip test against a real
/// in-memory database rather than assumed to just work:
///
/// - **Dates.** This project doesn't configure Drift's
///   `storeDateTimesAsText` option, so `DateTimeColumn` stores dates
///   locally as SQLite `INTEGER` (whole seconds since the Unix epoch —
///   see `SqlTypes._readDateTime` in drift's source). PostgREST returns
///   `timestamptz` columns as ISO-8601 strings. Left unconverted, a
///   pulled date would insert as a raw ISO-8601 *string* into an
///   `INTEGER` column — SQLite's type affinity happily stores it without
///   complaint, but the next attempt to read that row through Drift's
///   typed accessor throws (`int.parse` on an ISO-8601 string).
/// - **Booleans.** SQLite has no native boolean type; Drift's
///   `BoolColumn` also stores as `INTEGER` (0/1). PostgREST returns
///   `boolean` columns as native JSON `true`/`false`, which the
///   underlying `sqlite3` FFI bindings do not accept directly as a bound
///   parameter.
///
/// Both conversions are driven by the column's actual declared SQLite
/// type (`PRAGMA table_info`'s `type` field), not by guessing from the
/// incoming value alone — an `INTEGER` column holding a `String` value
/// is unambiguous in this schema (only a date/time column can disagree
/// like that; every other `INTEGER` column receives a JSON number or
/// JSON boolean from PostgREST, never a string).
class LocalRowUpserter {
  final AppDatabaseV2 db;
  final Map<String, Map<String, String>> _columnTypeCache = {};

  LocalRowUpserter(this.db);

  Future<void> upsert(String table, Map<String, Object?> row) async {
    if (!SyncTableRegistry.isSyncable(table)) {
      throw ArgumentError('table "$table" is not sync-eligible');
    }
    if (row.isEmpty) {
      throw ArgumentError('cannot upsert an empty row into "$table"');
    }

    final localColumnTypes = await _localColumnTypes(table);
    final columns = row.keys.where(localColumnTypes.containsKey).toList();
    if (columns.isEmpty) {
      throw ArgumentError(
        'none of row keys ${row.keys} match any local column of "$table" '
        '(local columns: ${localColumnTypes.keys}) — check for a table/column rename',
      );
    }

    final placeholders = List.filled(columns.length, '?').join(', ');
    final columnList = columns.join(', ');
    final values = columns
        .map((c) => _coerce(value: row[c], sqliteType: localColumnTypes[c]!))
        .toList();

    final conflictClause = SyncTableRegistry.isAppendOnly(table)
        ? 'ON CONFLICT(id) DO NOTHING'
        : 'ON CONFLICT(id) DO UPDATE SET '
              '${columns.where((c) => c != 'id').map((c) => '$c = excluded.$c').join(', ')}';

    await db.customStatement(
      'INSERT INTO $table ($columnList) VALUES ($placeholders) $conflictClause',
      values,
    );
  }

  Object? _coerce({required Object? value, required String sqliteType}) {
    if (value is bool) return value ? 1 : 0;
    if (value is String && sqliteType == 'INTEGER') {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
      }
    }
    return value;
  }

  Future<Map<String, String>> _localColumnTypes(String table) async {
    final cached = _columnTypeCache[table];
    if (cached != null) return cached;

    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    final columnTypes = {
      for (final r in rows) r.data['name'] as String: r.data['type'] as String,
    };
    _columnTypeCache[table] = columnTypes;
    return columnTypes;
  }
}
