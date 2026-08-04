import 'dart:convert';

/// One row's worth of a batched upsert inside an [OutboxEvent] — mirrors
/// the `{"table": "...", "row": {...}}` shape `apply_outbox_event`
/// expects (`supabase/migrations/0008_outbox_sync_rpc.sql`).
class TableUpsert {
  final String table;
  final Map<String, Object?> row;

  const TableUpsert({required this.table, required this.row});

  Map<String, Object?> toJson() => {'table': table, 'row': row};

  static TableUpsert fromJson(Map<String, Object?> json) => TableUpsert(
    table: json['table'] as String,
    row: Map<String, Object?>.from(json['row'] as Map),
  );
}

/// The decoded form of one [SyncOutboxEntries] row's `payloadJson` — one
/// local business event, expressed as the set of table upserts it
/// resolves to. See `lib/data/local/tables/sync.dart`'s doc comment on
/// why this is computed once by the caller (a use case, once those land)
/// rather than re-derived from the event type server-side.
class OutboxEvent {
  final String idempotencyKey;
  final List<TableUpsert> upserts;

  const OutboxEvent({required this.idempotencyKey, required this.upserts});

  String encodePayload() => jsonEncode(upserts.map((u) => u.toJson()).toList());

  static List<TableUpsert> decodePayload(String payloadJson) {
    final decoded = jsonDecode(payloadJson) as List<Object?>;
    return decoded
        .map(
          (entry) =>
              TableUpsert.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList();
  }
}
