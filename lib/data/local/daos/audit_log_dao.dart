import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/audit.dart';

part 'audit_log_dao.g.dart';

/// Data access for [AuditLogEntries] — see that table's own doc comment
/// for the retention warning this DAO's [deleteOlderThan] exists to
/// address ("needs a retention policy before this ships to real users").
///
/// Deliberately append-only from this DAO's perspective too: there is no
/// `update`, only [create] and the bulk [deleteOlderThan] prune — an
/// audit entry that could itself be edited after the fact would defeat
/// the entire point of an audit log.
@DriftAccessor(tables: [AuditLogEntries])
class AuditLogDao extends DatabaseAccessor<AppDatabaseV2>
    with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Stream<List<AuditLogEntryRow>> watchAll(String shopId, {int limit = 200}) {
    final query = select(auditLogEntries)
      ..where((a) => a.shopId.equals(shopId))
      ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
      ..limit(limit);
    return query.watch();
  }

  Future<void> create({
    required String id,
    required String shopId,
    required String action,
    required String changedTableName,
    required String recordId,
    required DateTime now,
    String? oldValueJson,
    String? newValueJson,
    String? userId,
    String? deviceId,
  }) {
    return into(auditLogEntries).insert(
      AuditLogEntriesCompanion.insert(
        id: id,
        shopId: shopId,
        userId: Value(userId),
        deviceId: Value(deviceId),
        action: action,
        changedTableName: changedTableName,
        recordId: recordId,
        oldValueJson: Value(oldValueJson),
        newValueJson: Value(newValueJson),
        timestamp: now,
        syncedAt: now,
      ),
    );
  }

  /// Deletes every entry timestamped before [cutoff] — the retention
  /// policy's audit-log half. A real `DELETE`, not a soft-delete: an
  /// audit log entry that has aged out of the retention window has no
  /// "undo" concept of its own (unlike the business rows it once
  /// described), so hard-deleting it is correct, not a shortcut.
  Future<int> deleteOlderThan(String shopId, DateTime cutoff) {
    return (delete(auditLogEntries)..where(
          (a) =>
              a.shopId.equals(shopId) & a.timestamp.isSmallerThanValue(cutoff),
        ))
        .go();
  }
}
