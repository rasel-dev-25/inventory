// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_dao.dart';

// ignore_for_file: type=lint
mixin _$InvestorDaoMixin on DatabaseAccessor<AppDatabaseV2> {
  $ShopsTable get shops => attachedDatabase.shops;
  $InvestorsTable get investors => attachedDatabase.investors;
  $InvestorRepaymentsTable get investorRepayments =>
      attachedDatabase.investorRepayments;
  $LegacySettlementsTable get legacySettlements =>
      attachedDatabase.legacySettlements;
  InvestorDaoManager get managers => InvestorDaoManager(this);
}

class InvestorDaoManager {
  final _$InvestorDaoMixin _db;
  InvestorDaoManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$InvestorsTableTableManager get investors =>
      $$InvestorsTableTableManager(_db.attachedDatabase, _db.investors);
  $$InvestorRepaymentsTableTableManager get investorRepayments =>
      $$InvestorRepaymentsTableTableManager(
        _db.attachedDatabase,
        _db.investorRepayments,
      );
  $$LegacySettlementsTableTableManager get legacySettlements =>
      $$LegacySettlementsTableTableManager(
        _db.attachedDatabase,
        _db.legacySettlements,
      );
}
