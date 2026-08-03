// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_capture_dao.dart';

// ignore_for_file: type=lint
mixin _$QuickCaptureDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuickCapturesTable get quickCaptures => attachedDatabase.quickCaptures;
  QuickCaptureDaoManager get managers => QuickCaptureDaoManager(this);
}

class QuickCaptureDaoManager {
  final _$QuickCaptureDaoMixin _db;
  QuickCaptureDaoManager(this._db);
  $$QuickCapturesTableTableManager get quickCaptures =>
      $$QuickCapturesTableTableManager(_db.attachedDatabase, _db.quickCaptures);
}
