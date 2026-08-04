import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/expense.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'ledger_reversal.dart';
import 'sync_enqueue_helper.dart';

/// Create/delete for [Expense] — per `notes/business_logic.md` §চ section
/// 1: "মাসিক ভাড়া ও অন্যান্য খরচ — বেচাকেনার ক্যাশ থেকেই কাটে, Total Cash
/// কমায়". Pairs the expense write with a negative `cash_ledger_entries`
/// row, the same shape `SavePurchaseTripUseCase`/
/// `RecordInvestorRepaymentUseCase` use for every other cash-out event —
/// so an expense's impact on Total Cash can never be silently missing.
///
/// No `update` — see `ExpenseDao`'s own doc comment for why editing an
/// amount/category/payment-method after the fact would leave the ledger
/// entry recorded alongside it wrong. A mistaken expense is deleted via
/// [softDelete], not edited.
class ExpenseUseCases {
  final AppDatabaseV2 db;
  static const _uuid = Uuid();

  ExpenseUseCases(this.db);

  Future<Result<void>> create(
    Expense expense, {
    required String shopId,
    required DateTime now,
  }) async {
    if (!expense.amount.isPositive) {
      return const Result.err(
        ValidationFailure('amount', 'Expense amount must be positive'),
      );
    }

    final ledgerId = _uuid.v7();
    final dateIso = expense.date.toUtc().toIso8601String();

    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'expenses',
        row: {
          'id': expense.id,
          'shop_id': shopId,
          'category': expense.category.name,
          'amount_minor': expense.amount.minorUnits,
          'date': dateIso,
          'description': expense.description,
          'payment_method': expense.paymentMethod.name,
        },
      ),
      TableUpsert(
        table: 'cash_ledger_entries',
        row: {
          'id': ledgerId,
          'shop_id': shopId,
          // Cash-out, hence negated — same convention as every other
          // cash-out use case in this directory.
          'amount_minor': -expense.amount.minorUnits,
          'payment_method': expense.paymentMethod.name,
          'source_type': 'expense',
          'source_id': expense.id,
          'date': dateIso,
        },
      ),
    ];

    await writeAndEnqueue(
      db: db,
      eventType: 'expense_recorded',
      upserts: upserts,
      localWrite: () async {
        await db.expenseDao.create(expense, shopId: shopId, now: now);
        await db.ledgerDao.recordCashLedgerEntry(
          id: ledgerId,
          shopId: shopId,
          amountMinor: -expense.amount.minorUnits,
          paymentMethod: expense.paymentMethod,
          sourceType: 'expense',
          sourceId: expense.id,
          date: expense.date,
          now: now,
        );
      },
    );

    return const Result.ok(null);
  }

  /// Soft-deletes the expense *and* reverses its cash-ledger entry (a new,
  /// negated row — see `ledger_reversal.dart`'s own doc comment for why
  /// this is a new row, never an edit of the original). This closes the
  /// gap `ExpenseDao.softDelete`'s doc comment used to describe: deleting
  /// an expense now actually restores its amount to Total Cash, not just
  /// hides the row.
  Future<void> softDelete(
    String id, {
    required String shopId,
    required DateTime now,
  }) async {
    final reversal = await buildCashLedgerReversal(
      db: db,
      shopId: shopId,
      sourceType: 'expense',
      sourceId: id,
      date: now,
      now: now,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'expense_deleted',
      upserts: [
        TableUpsert(
          table: 'expenses',
          row: {
            'id': id,
            'shop_id': shopId,
            'deleted_at': now.toIso8601String(),
          },
        ),
        ...reversal.upserts,
      ],
      localWrite: () async {
        await db.expenseDao.softDelete(id, now);
        await reversal.localWrite();
      },
    );
  }
}
