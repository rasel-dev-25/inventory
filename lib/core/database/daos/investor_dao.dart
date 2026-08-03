import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'investor_dao.g.dart';

@DriftAccessor(tables: [Investors, Repayments])
class InvestorDao extends DatabaseAccessor<AppDatabase> with _$InvestorDaoMixin {
  InvestorDao(super.db);

  Future<List<Investor>> getAll() => select(investors).get();

  Stream<List<Investor>> watchAll() => select(investors).watch();

  Future<List<Investor>> getActive() {
    return (select(investors)..where((t) => t.isActive.equals(true))).get();
  }

  Future<Investor?> getById(String id) {
    return (select(investors)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Investor?> getByName(String name) {
    return (select(investors)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<void> insertInvestor(InvestorsCompanion entry) => into(investors).insert(entry);

  Future<void> updateInvestor(String id, InvestorsCompanion entry) {
    return (update(investors)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteInvestor(String id) async {
    await (delete(repayments)..where((t) => t.investorId.equals(id))).go();
    await (delete(investors)..where((t) => t.id.equals(id))).go();
  }

  // Repayments
  Future<List<Repayment>> getRepayments(String investorId) {
    return (select(repayments)..where((t) => t.investorId.equals(investorId))).get();
  }

  Future<void> addRepayment(RepaymentsCompanion entry) => into(repayments).insert(entry);

  Future<void> deleteRepayment(String id) {
    return (delete(repayments)..where((t) => t.id.equals(id))).go();
  }
}
