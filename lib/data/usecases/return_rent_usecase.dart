import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/due.dart';
import '../../domain/entities/enums.dart';
import '../../domain/services/due_lifecycle.dart';
import '../../domain/services/rent_lifecycle.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// The book-return flow, per `notes/business_logic.md` §জ's numbered
/// steps 1-8. [extraDayCharge]/[damageCharge] are the *final, already-
/// decided* amounts (auto-suggested by `rent_lifecycle.dart`'s
/// `suggestExtraDayCharge` and shown to the owner to override, exactly
/// like [SaveSaleUseCase] takes the final `actualSellPrice` rather than
/// computing a suggestion itself) — this use case only settles the
/// transaction with whatever values it's handed, it never re-derives
/// them.
///
/// The settlement (step 6: `rentPrice + extraDayCharge + damageCharge −
/// deposit`) can come out three ways, and each is a genuinely different
/// cash event:
/// - **Positive** (customer owes): [amountReceivedNow] is whatever they
///   pay right now (0 up to the full amount); any remainder becomes a
///   [Due] with `sourceType: rent` (step 7).
/// - **Negative** (a refund is owed): the shop pays the customer back
///   the difference, in full, immediately — there is no "due" concept
///   for money the *shop* owes a customer, so a partial refund is not
///   modeled; flagged here rather than silently assumed away.
/// - **Zero**: the deposit exactly covers everything; no cash moves.
class ReturnRentUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  ReturnRentUseCase(this.db);

  Future<Result<void>> call({
    required String rentId,
    required DateTime actualReturnDate,
    required Money amountReceivedNow,
    required PaymentMethod paymentMethod,
    required String shopId,
    required DateTime now,
    Money? extraDayCharge,
    Money? damageCharge,
    int? promisedDays,
  }) async {
    if (amountReceivedNow.isNegative) {
      return const Result.err(
        ValidationFailure(
          'amountReceivedNow',
          'Amount received cannot be negative',
        ),
      );
    }

    final rent = await db.rentDao.getById(rentId);
    if (rent == null) {
      return Result.err(NotFoundFailure('rentTransaction', rentId));
    }
    if (rent.status == RentStatus.returned ||
        rent.status == RentStatus.treatedAsStolen) {
      return const Result.err(
        BusinessRuleFailure('This rental has already been settled'),
      );
    }

    final settlement = computeReturnSettlement(
      rentPrice: rent.rentPrice,
      deposit: rent.deposit,
      extraDayCharge: extraDayCharge,
      damageCharge: damageCharge,
    );

    if (settlement.refundOwed && amountReceivedNow.isPositive) {
      return const Result.err(
        BusinessRuleFailure(
          'The deposit covers the total — a refund is owed, not a payment',
        ),
      );
    }
    if (settlement.customerOwes && amountReceivedNow > settlement.netAmount) {
      return const Result.err(
        BusinessRuleFailure('Amount received cannot exceed the amount owed'),
      );
    }

    final resolvedExtraDayCharge = extraDayCharge ?? Money.zero();
    final resolvedDamageCharge = damageCharge ?? Money.zero();
    final dateIso = actualReturnDate.toUtc().toIso8601String();

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'rent_transactions',
        row: {
          'id': rent.id,
          'shop_id': shopId,
          'status': RentStatus.returned.name,
          'returned_date': dateIso,
          'extra_day_charge_minor': resolvedExtraDayCharge.minorUnits,
          'damage_charge_minor': resolvedDamageCharge.minorUnits,
        },
      ),
    ];

    String? ledgerId;
    int? ledgerAmountMinor;
    Due? due;

    if (settlement.refundOwed) {
      ledgerId = _uuid.v7();
      ledgerAmountMinor = -settlement.refundAmount.minorUnits;
    } else if (settlement.customerOwes) {
      if (amountReceivedNow.isPositive) {
        ledgerId = _uuid.v7();
        ledgerAmountMinor = amountReceivedNow.minorUnits;
      }
      final remaining = settlement.netAmount - amountReceivedNow;
      if (remaining.isPositive) {
        due = createDue(
          id: _uuid.v7(),
          customerId: rent.customerId,
          sourceType: DueSourceType.rent,
          sourceId: rent.id,
          remainingAmount: remaining,
          promisedDays: promisedDays,
          now: now,
        );
      }
    }

    if (ledgerId != null) {
      upserts.add(
        TableUpsert(
          table: 'cash_ledger_entries',
          row: {
            'id': ledgerId,
            'shop_id': shopId,
            'amount_minor': ledgerAmountMinor,
            'payment_method': paymentMethod.name,
            'source_type': 'rent',
            'source_id': rent.id,
            'description': settlement.refundOwed
                ? 'Rental deposit refund'
                : 'Rental settlement',
            'date': dateIso,
          },
        ),
      );
    }
    if (due != null) {
      upserts.add(
        TableUpsert(
          table: 'dues',
          row: {
            'id': due.id,
            'shop_id': shopId,
            'customer_id': due.customerId,
            'source_type': due.sourceType.name,
            'source_id': due.sourceId,
            'original_amount_minor': due.originalAmount.minorUnits,
            'paid_amount_minor': due.paidAmount.minorUnits,
            'promised_days': due.promisedDays,
            'status': due.status.name,
          },
        ),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'rent_returned',
      upserts: upserts,
      localWrite: () async {
        await db.rentDao.markReturned(
          rent.copyWith(
            status: RentStatus.returned,
            returnedDate: actualReturnDate,
            extraDayCharge: resolvedExtraDayCharge,
            damageCharge: resolvedDamageCharge,
          ),
          now: now,
        );
        if (ledgerId != null) {
          await db.ledgerDao.recordCashLedgerEntry(
            id: ledgerId,
            shopId: shopId,
            amountMinor: ledgerAmountMinor!,
            paymentMethod: paymentMethod,
            sourceType: 'rent',
            sourceId: rent.id,
            date: actualReturnDate,
            now: now,
            description: settlement.refundOwed
                ? 'Rental deposit refund'
                : 'Rental settlement',
          );
        }
        if (due != null) {
          await db.dueDao.create(due, shopId: shopId, now: now);
        }
      },
    );

    return const Result.ok(null);
  }
}
