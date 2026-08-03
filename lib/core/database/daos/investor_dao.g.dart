// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_dao.dart';

// ignore_for_file: type=lint
mixin _$InvestorDaoMixin on DatabaseAccessor<AppDatabase> {
  $InvestorsTable get investors => attachedDatabase.investors;
  $RepaymentsTable get repayments => attachedDatabase.repayments;
  InvestorDaoManager get managers => InvestorDaoManager(this);
}

class InvestorDaoManager {
  final _$InvestorDaoMixin _db;
  InvestorDaoManager(this._db);
  $$InvestorsTableTableManager get investors =>
      $$InvestorsTableTableManager(_db.attachedDatabase, _db.investors);
  $$RepaymentsTableTableManager get repayments =>
      $$RepaymentsTableTableManager(_db.attachedDatabase, _db.repayments);
}
