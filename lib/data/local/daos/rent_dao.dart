import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/rent_transaction.dart' as domain;
import '../app_database.dart';
import '../tables/rent.dart';

part 'rent_dao.g.dart';

extension _RentTransactionRowMapping on RentTransactionRow {
  domain.RentTransaction toDomain() {
    return domain.RentTransaction(
      id: id,
      bookProductId: bookProductId,
      customerId: customerId,
      startDate: startDate,
      dueDate: dueDate,
      deposit: Money.fromMinor(depositMinor),
      rentPrice: Money.fromMinor(rentPriceMinor),
      extraDayCharge: extraDayChargeMinor == null
          ? null
          : Money.fromMinor(extraDayChargeMinor!),
      damageCharge: damageChargeMinor == null
          ? null
          : Money.fromMinor(damageChargeMinor!),
      status: status,
      returnedDate: returnedDate,
    );
  }
}

/// Data access for [RentPricingTiers] + [RentTransactions] — grouped in
/// one accessor since a rental is meaningless without the tier config
/// that priced it, the same reasoning `DueDao` (Dues+DuePayments) and
/// `InvestorDao` (Investors+InvestorRepayments) already establish.
///
/// [RentPricingTiers] is read-only here — editing tiers (the spec's
/// "কনফিগারযোগ্য") is not yet built anywhere in v2; the six default tiers
/// `AppDatabaseV2._seed()` writes on a fresh database are what
/// `IssueRentUseCase`'s tier lookup uses today. Tracked as a follow-up,
/// not a silent omission.
@DriftAccessor(tables: [RentPricingTiers, RentTransactions])
class RentDao extends DatabaseAccessor<AppDatabaseV2> with _$RentDaoMixin {
  RentDao(super.db);

  Stream<List<RentPricingTierRow>> watchTiers(String shopId) {
    final query = select(rentPricingTiers)
      ..where((t) => t.shopId.equals(shopId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch();
  }

  /// One-shot fetch for [IssueRentUseCase]'s tier lookup — a use case
  /// doing a single computation wants a `Future`, not a `Stream` it would
  /// have to `.first` off of.
  Future<List<RentPricingTierRow>> getTiers(String shopId) {
    final query = select(rentPricingTiers)
      ..where((t) => t.shopId.equals(shopId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.get();
  }

  Future<domain.RentTransaction?> getById(String id) async {
    final row = await (select(
      rentTransactions,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Every rental for [shopId], most recently issued first — the Rent
  /// screen filters this itself into "active" vs. "history" sections,
  /// same reasoning `StockController`/`LedgerDao.watchAll` already give
  /// for why a DAO returns unfiltered rows when the caller needs more
  /// than one view over them.
  Stream<List<domain.RentTransaction>> watchAll(String shopId) {
    final query = select(rentTransactions)
      ..where((r) => r.shopId.equals(shopId))
      ..orderBy([(r) => OrderingTerm.desc(r.startDate)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// How many of [productId]'s copies are currently out on rent for
  /// [shopId] — the subtrahend in "available copies = `Products.qty` −
  /// this", per `tables/rent.dart`'s own doc comment on why that
  /// subtraction is computed on read rather than cached anywhere.
  Future<int> countActiveRentals(String shopId, String productId) async {
    final query = selectOnly(rentTransactions)
      ..addColumns([rentTransactions.id.count()])
      ..where(
        rentTransactions.shopId.equals(shopId) &
            rentTransactions.bookProductId.equals(productId) &
            rentTransactions.status.equalsValue(RentStatus.active),
      );
    final row = await query.getSingle();
    return row.read(rentTransactions.id.count()) ?? 0;
  }

  Future<void> create(
    domain.RentTransaction rent, {
    required String shopId,
    required DateTime now,
  }) {
    return into(rentTransactions).insert(
      RentTransactionsCompanion.insert(
        id: rent.id,
        shopId: shopId,
        bookProductId: rent.bookProductId,
        customerId: rent.customerId,
        startDate: rent.startDate,
        dueDate: rent.dueDate,
        depositMinor: Value(rent.deposit.minorUnits),
        rentPriceMinor: Value(rent.rentPrice.minorUnits),
        status: rent.status,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Writes the return-flow fields together — [RentStatus.returned],
  /// [domain.RentTransaction.returnedDate], and the two charges only
  /// known now — matching the "advance every related field in one write"
  /// rule `DueDao.applyPayment` documents for the same reason (so a
  /// caller can never observe a rental marked returned with stale/absent
  /// charge fields, or vice versa).
  Future<void> markReturned(
    domain.RentTransaction updated, {
    required DateTime now,
  }) {
    return (update(
      rentTransactions,
    )..where((r) => r.id.equals(updated.id))).write(
      RentTransactionsCompanion(
        status: Value(updated.status),
        returnedDate: Value(updated.returnedDate),
        extraDayChargeMinor: Value(updated.extraDayCharge?.minorUnits),
        damageChargeMinor: Value(updated.damageCharge?.minorUnits),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markStolen(String id, DateTime now) {
    return (update(rentTransactions)..where((r) => r.id.equals(id))).write(
      RentTransactionsCompanion(
        status: const Value(RentStatus.treatedAsStolen),
        updatedAt: Value(now),
      ),
    );
  }
}
