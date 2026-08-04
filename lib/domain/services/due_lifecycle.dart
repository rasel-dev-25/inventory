/// The due lifecycle, per `notes/business_logic.md` §Due and §ছ:
/// creation from a sale (or a rental), partial payments, and the
/// pending → partially_paid → paid status transitions.
///
/// Unlike the profit/reconciliation calculators, applying a payment has
/// real business-rule failure modes a UI needs to react to (a zero/negative
/// amount, paying an already-settled due, overpaying) — so
/// [applyDuePayment] returns `Result<Due>` rather than throwing, per the
/// pattern `lib/core/error/result.dart` establishes for exactly this case.
library;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../entities/due.dart';
import '../entities/enums.dart';

/// Creates the [Due] that must be written alongside a credit or
/// partial-cash sale (or an under-paid rent return) — see
/// `notes/business_logic.md` §গ: "সেভ হলে একইসাথে Due এন্ট্রি অটো-তৈরি হবে".
///
/// [remainingAmount] is what's left unpaid *after* whatever cash was
/// already collected at sale/return time — never the full sale total, see
/// [Due]'s doc comment for why. Throws [ArgumentError] for a non-positive
/// remaining amount: a due for nothing owed should simply not be created
/// by the caller, not constructed and discarded.
Due createDue({
  required String id,
  required String customerId,
  required DueSourceType sourceType,
  required String sourceId,
  required Money remainingAmount,
  int? promisedDays,
  required DateTime now,
}) {
  if (!remainingAmount.isPositive) {
    throw ArgumentError.value(
      remainingAmount,
      'remainingAmount',
      'A due must be created for a positive remaining amount',
    );
  }
  return Due(
    id: id,
    customerId: customerId,
    sourceType: sourceType,
    sourceId: sourceId,
    originalAmount: remainingAmount,
    paidAmount: Money.zero(currency: remainingAmount.currency),
    promisedDays: promisedDays,
    status: DueStatus.pending,
    createdAt: now,
  );
}

/// How much is still owed on [due] right now.
Money remainingBalance(Due due) => due.originalAmount - due.paidAmount;

/// The pending/partially_paid/paid transition rule — the only place this
/// decision is made, so a due's displayed status can never disagree with
/// its own amounts.
DueStatus computeDueStatus({
  required Money originalAmount,
  required Money paidAmount,
}) {
  if (paidAmount >= originalAmount) return DueStatus.paid;
  if (paidAmount.isZero) return DueStatus.pending;
  return DueStatus.partiallyPaid;
}

/// Records a payment against [due], returning the updated due with
/// [Due.paidAmount] and [Due.status] both advanced together — per
/// business_logic.md's Data Integrity Rule #5, these must never be
/// updated independently of one another.
///
/// Rejects (rather than clamping) a payment that would overpay the due:
/// a due is a fixed amount owed, not a running account balance, so an
/// attempted overpayment is a data-entry mistake to surface to the user,
/// not silently absorb.
Result<Due> applyDuePayment({required Due due, required Money paymentAmount}) {
  if (!paymentAmount.isPositive) {
    return Result.err(
      const ValidationFailure(
        'paymentAmount',
        'Payment amount must be positive',
      ),
    );
  }
  if (due.status == DueStatus.paid) {
    return Result.err(
      const BusinessRuleFailure('This due is already fully paid'),
    );
  }

  final newPaidAmount = due.paidAmount + paymentAmount;
  if (newPaidAmount > due.originalAmount) {
    final overage = newPaidAmount - due.originalAmount;
    return Result.err(
      BusinessRuleFailure(
        'This payment would overpay the due by ${overage.format()}',
      ),
    );
  }

  return Result.ok(
    due.copyWith(
      paidAmount: newPaidAmount,
      status: computeDueStatus(
        originalAmount: due.originalAmount,
        paidAmount: newPaidAmount,
      ),
    ),
  );
}

/// The date [due] was promised to be settled by, or null if no promise
/// was made.
DateTime? promisedByDate(Due due) {
  if (due.promisedDays == null) return null;
  return due.createdAt.add(Duration(days: due.promisedDays!));
}

/// True when [due] is unpaid past its promised date, as of [now] — the
/// signal `notes/business_logic.md` §ছ's reminder feature reads.
bool isOverdue(Due due, DateTime now) {
  final promisedBy = promisedByDate(due);
  if (promisedBy == null || due.status == DueStatus.paid) return false;
  return now.isAfter(promisedBy);
}
