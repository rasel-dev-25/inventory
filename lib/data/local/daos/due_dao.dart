import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/due.dart' as domain;
import '../../../domain/entities/enums.dart';
import '../app_database.dart';
import '../tables/dues.dart';

part 'due_dao.g.dart';

extension _DueRowMapping on DueRow {
  domain.Due toDomain() {
    return domain.Due(
      id: id,
      customerId: customerId,
      sourceType: sourceType,
      sourceId: sourceId,
      originalAmount: Money.fromMinor(originalAmountMinor),
      paidAmount: Money.fromMinor(paidAmountMinor),
      promisedDays: promisedDays,
      status: status,
      createdAt: createdAt,
    );
  }
}

/// Data access for [Dues] + [DuePayments]. [applyPayment] is the one
/// place `Dues.paidAmountMinor`/`status` change after creation — both
/// written together with the [DuePayments] row that caused the change,
/// in one transaction, per Data Integrity Rule #5 (see `Dues`' own doc
/// comment) and the same reasoning `due_lifecycle.dart`'s
/// `applyDuePayment` documents for why the two must never update
/// independently.
@DriftAccessor(tables: [Dues, DuePayments])
class DueDao extends DatabaseAccessor<AppDatabase> with _$DueDaoMixin {
  DueDao(super.db);

  Future<domain.Due?> getById(String id) async {
    final row = await (select(
      dues,
    )..where((d) => d.id.equals(id) & d.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Due>> watchAll(String shopId) {
    final query = select(dues)
      ..where((d) => d.shopId.equals(shopId) & d.deletedAt.isNull())
      ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Due due, {
    required String shopId,
    required DateTime now,
  }) {
    return into(dues).insert(
      DuesCompanion.insert(
        id: due.id,
        shopId: shopId,
        customerId: due.customerId,
        sourceType: due.sourceType,
        sourceId: due.sourceId,
        originalAmountMinor: due.originalAmount.minorUnits,
        paidAmountMinor: Value(due.paidAmount.minorUnits),
        promisedDays: Value(due.promisedDays),
        status: due.status,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }

  /// Writes the advanced [Due] (new `paidAmount`/`status`, computed by
  /// `due_lifecycle.dart`'s `applyDuePayment` — this DAO does not
  /// recompute or validate them) together with the [DuePayments] row
  /// that justifies the change.
  Future<void> applyPayment({
    required domain.Due updatedDue,
    required String paymentId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
    required DateTime date,
    required DateTime now,
  }) async {
    await db.transaction(() async {
      await (update(dues)..where((d) => d.id.equals(updatedDue.id))).write(
        DuesCompanion(
          paidAmountMinor: Value(updatedDue.paidAmount.minorUnits),
          status: Value(updatedDue.status),
          updatedAt: Value(now),
        ),
      );
      await into(duePayments).insert(
        DuePaymentsCompanion.insert(
          id: paymentId,
          dueId: updatedDue.id,
          amountMinor: paymentAmount.minorUnits,
          paymentMethod: paymentMethod,
          date: date,
          createdAt: now,
          syncedAt: now,
        ),
      );
    });
  }

  Future<domain.Due?> getBySource(String sourceType, String sourceId) async {
    final row = await (select(dues)..where(
      (d) =>
          d.sourceType.equals(sourceType) &
          d.sourceId.equals(sourceId) &
          d.deletedAt.isNull(),
    )).getSingleOrNull();
    return row?.toDomain();
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(dues)..where((d) => d.id.equals(id))).write(
      DuesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
