import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/services/due_lifecycle.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Records a payment against an outstanding [Due] — `notes/business_logic.md`
/// §ছ's "বকেয়া পরিশোধ" flow — mirroring [SaveSaleUseCase]'s shape: look the
/// row up fresh (never trust a caller-held [Due] snapshot, which may be
/// stale by the time the user taps "pay"), validate via the domain layer,
/// then write the advanced due + the new [DuePayment] + the cash-in ledger
/// entry as one atomic local write plus one outbox event.
///
/// The overpay/already-settled rules live in `due_lifecycle.dart`'s
/// `applyDuePayment` — this use case does not re-implement them, just wires
/// that `Result<Due>` into the same local-write/outbox shape every other
/// use case in this directory uses.
///
/// A due payment is always cash-in (the customer is paying down what they
/// owe), so unlike [SaveSaleUseCase] there is no "did any cash actually
/// change hands" branch — a `cash_ledger_entries` row is written
/// unconditionally, for the full [paymentAmount].
class PayDueUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  PayDueUseCase(this.db);

  Future<Result<void>> call({
    required String dueId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
    required String shopId,
    required DateTime date,
    required DateTime now,
  }) async {
    final due = await db.dueDao.getById(dueId);
    if (due == null) {
      return Result.err(NotFoundFailure('due', dueId));
    }

    final result = applyDuePayment(due: due, paymentAmount: paymentAmount);
    if (result.isErr) {
      return Result.err(result.failureOrNull!);
    }
    final updatedDue = result.valueOrNull!;

    final paymentId = _uuid.v7();
    final ledgerId = _uuid.v7();
    final dateIso = date.toUtc().toIso8601String();

    final upserts = <TableUpsert>[
      // Partial update: only the two columns `due_lifecycle.dart` actually
      // advances. `apply_outbox_event`'s upsert only sets provided columns
      // on conflict (see `sync_enqueue_helper.dart`'s doc comment), so this
      // never risks clobbering `original_amount_minor`/`customer_id`/etc.
      // with stale values from whenever this event happens to be pushed.
      TableUpsert(
        table: 'dues',
        row: {
          'id': updatedDue.id,
          'shop_id': shopId,
          'paid_amount_minor': updatedDue.paidAmount.minorUnits,
          'status': updatedDue.status.name,
        },
      ),
      TableUpsert(
        table: 'due_payments',
        row: {
          'id': paymentId,
          'due_id': updatedDue.id,
          'amount_minor': paymentAmount.minorUnits,
          'payment_method': paymentMethod.name,
          'date': dateIso,
        },
      ),
      TableUpsert(
        table: 'cash_ledger_entries',
        row: {
          'id': ledgerId,
          'shop_id': shopId,
          'amount_minor': paymentAmount.minorUnits,
          'payment_method': paymentMethod.name,
          'source_type': 'due_payment',
          'source_id': updatedDue.id,
          'date': dateIso,
        },
      ),
    ];

    await writeAndEnqueue(
      db: db,
      eventType: 'due_payment_recorded',
      upserts: upserts,
      localWrite: () async {
        await db.dueDao.applyPayment(
          updatedDue: updatedDue,
          paymentId: paymentId,
          paymentAmount: paymentAmount,
          paymentMethod: paymentMethod,
          date: date,
          now: now,
        );
        await db.ledgerDao.recordCashLedgerEntry(
          id: ledgerId,
          shopId: shopId,
          amountMinor: paymentAmount.minorUnits,
          paymentMethod: paymentMethod,
          sourceType: 'due_payment',
          sourceId: updatedDue.id,
          date: date,
          now: now,
        );
      },
    );

    return const Result.ok(null);
  }
}
