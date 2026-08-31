import '../local/daos/sync_metadata_dao.dart';
import 'enum_case_bridge.dart';
import 'outbox_event.dart';
import 'shop_id_bridge.dart';
import 'sync_transport.dart';

class SyncPushSummary {
  final int succeeded;
  final int failed;

  const SyncPushSummary({required this.succeeded, required this.failed});

  SyncPushSummary operator +(SyncPushSummary other) => SyncPushSummary(
    succeeded: succeeded + other.succeeded,
    failed: failed + other.failed,
  );
}

/// The outbox pusher: drains [SyncMetadataDao.pendingEntries] one at a
/// time, substituting this device's local shop id for the real backend
/// one (see [ShopIdBridge]) before each push, and records the outcome
/// back onto the same row so a failed event is retried on the next call
/// rather than lost.
///
/// Deliberately processes entries strictly in `createdAt` order and
/// waits for each push to finish before starting the next — a purchase
/// trip's outbox event and a later due-payment event on the same
/// customer are not safe to reorder, and `apply_outbox_event`'s
/// idempotency ledger only protects against *retrying* an event, not
/// against applying two different events out of order.
class SyncPushService {
  final SyncMetadataDao _dao;
  final SyncTransport _transport;

  SyncPushService(this._dao, this._transport);

  Future<SyncPushSummary> pushPending({required String remoteShopId}) async {
    final entries = await _dao.pendingEntries();
    var succeeded = 0;
    var failed = 0;

    for (final entry in entries) {
      await _dao.markInFlight(entry.id, DateTime.now().toUtc());

      final localUpserts = OutboxEvent.decodePayload(entry.payloadJson);
      final remoteUpserts = localUpserts.map((u) {
        final sanitizedRow = _sanitizeUuidFields(u.row);
        final withRemoteShopId = ShopIdBridge.toRemote(
          sanitizedRow,
          localKey: 'shop_id',
          remoteShopId: remoteShopId,
        );
        // Order matters only in that both must happen before the row
        // leaves the device — shop_id substitution and enum
        // case-conversion touch disjoint columns, so they don't interact.
        final withRemoteEnums = EnumCaseBridge.toRemote(
          u.table,
          withRemoteShopId,
        );
        return TableUpsert(table: u.table, row: withRemoteEnums);
      }).toList();

      final result = await _transport.pushEvent(
        idempotencyKey: entry.idempotencyKey,
        upserts: remoteUpserts,
      );

      await result.fold(
        onOk: (_) async {
          await _dao.markDone(entry.id);
          succeeded++;
        },
        onErr: (failure) async {
          await _dao.incrementAttemptCount(entry.id);
          await _dao.markFailed(
            entry.id,
            failure.message,
            DateTime.now().toUtc(),
          );
          failed++;
        },
      );
    }

    return SyncPushSummary(succeeded: succeeded, failed: failed);
  }

  static Map<String, Object?> _sanitizeUuidFields(Map<String, Object?> row) {
    final sanitized = <String, Object?>{};
    for (final entry in row.entries) {
      final val = entry.value;
      if (val is String && val.startsWith('sm-')) {
        sanitized[entry.key] = val.substring(3);
      } else {
        sanitized[entry.key] = val;
      }
    }
    return sanitized;
  }
}
