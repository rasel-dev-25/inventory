// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopsTable get shops => attachedDatabase.shops;
  $AuditLogEntriesTable get auditLogEntries => attachedDatabase.auditLogEntries;
  AuditLogDaoManager get managers => AuditLogDaoManager(this);
}

class AuditLogDaoManager {
  final _$AuditLogDaoMixin _db;
  AuditLogDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$AuditLogEntriesTableTableManager get auditLogEntries =>
      $$AuditLogEntriesTableTableManager(
        _db.attachedDatabase,
        _db.auditLogEntries,
      );
}
