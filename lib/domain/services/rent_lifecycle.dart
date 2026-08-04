/// The book-rental lifecycle, per `notes/business_logic.md` §জ: tier
/// lookup at issue time, the overdue check, and the return-settlement
/// math (extra-day charge, damage charge, deposit adjustment). Pure
/// functions only — no I/O, no database — same discipline
/// `due_lifecycle.dart`/`purchase_reconciliation.dart` establish.
/// Validation with real failure modes (rejecting a return on an
/// already-returned rental, an invalid payment amount) lives in
/// `ReturnRentUseCase`, not here — matching where `due_lifecycle.dart`
/// draws that same line (`applyDuePayment` is the one function there that
/// returns a `Result`; everything else is a plain computation).
library;

import '../../core/money/money.dart';
import '../entities/enums.dart';
import '../entities/rent_transaction.dart';

/// Finds the smallest-`maxPages` tier that still covers [pageCount] —
/// e.g. a 120-page book matches the tier for `maxPages: 200`, not `100`,
/// even though 120 > 100. Returns `null` when no tier covers [pageCount]
/// (a book longer than every configured tier) — the spec's "ম্যানুয়াল
/// ওভাররাইড করা যাবে" means the caller falls back to manual entry rather
/// than this function guessing a tier that doesn't actually cover the
/// book.
({int days, Money price})? suggestTierFor(
  int pageCount,
  List<({int maxPages, int days, int priceMinor})> tiers,
) {
  final sorted = [...tiers]..sort((a, b) => a.maxPages.compareTo(b.maxPages));
  for (final tier in sorted) {
    if (pageCount <= tier.maxPages) {
      return (days: tier.days, price: Money.fromMinor(tier.priceMinor));
    }
  }
  return null;
}

DateTime computeDueDate({required DateTime startDate, required int days}) {
  return startDate.add(Duration(days: days));
}

/// True when [rent] is unreturned and past its due date, as of [now] — the
/// display-computed signal the Rent screen's overdue badge reads. Does
/// **not** mutate or persist `RentStatus.overdue`: see this file's own
/// module-level note in the working plan for why the stored `overdue`
/// enum value is reached only via an explicit owner action today, not an
/// automatic time-based transition.
bool isOverdue(RentTransaction rent, DateTime now) {
  if (rent.status == RentStatus.returned ||
      rent.status == RentStatus.treatedAsStolen) {
    return false;
  }
  return now.isAfter(rent.dueDate);
}

/// `অতিরিক্ত দিন = max(0, প্রকৃত তারিখ − নির্ধারিত তারিখ)` — the return
/// flow's step 3, computed in whole days.
int computeExtraDays({
  required DateTime dueDate,
  required DateTime actualReturnDate,
}) {
  final extraDays = actualReturnDate.difference(dueDate).inDays;
  return extraDays > 0 ? extraDays : 0;
}

/// The return flow's step 4 — `extraDays × perDayRate`, a suggestion the
/// owner can override, never a value this function insists on.
Money suggestExtraDayCharge({
  required int extraDays,
  required Money perDayRate,
}) {
  return perDayRate * extraDays;
}

/// The return flow's steps 6-7 result: how much is actually owed once
/// [rentPrice] + [extraDayCharge] + [damageCharge] are weighed against
/// the [deposit] already held.
///
/// [netAmount] is signed: positive means the customer still owes this
/// much (a [Due] should be created for whatever part of it isn't paid
/// immediately); negative means the shop owes the customer a refund of
/// that magnitude; zero means the deposit exactly covers the total, no
/// money changes hands either way.
class ReturnSettlement {
  final Money totalPayable;
  final Money netAmount;

  const ReturnSettlement({required this.totalPayable, required this.netAmount});

  bool get customerOwes => netAmount.isPositive;
  bool get refundOwed => netAmount.isNegative;

  /// The refund amount as a positive [Money] — only meaningful when
  /// [refundOwed] is true; a caller that reads this without checking
  /// [refundOwed] first would get a *positive* number even though it
  /// represents cash flowing out of the shop, so always check first.
  Money get refundAmount => -netAmount;
}

ReturnSettlement computeReturnSettlement({
  required Money rentPrice,
  required Money deposit,
  Money? extraDayCharge,
  Money? damageCharge,
}) {
  final currency = rentPrice.currency;
  final totalPayable =
      rentPrice +
      (extraDayCharge ?? Money.zero(currency: currency)) +
      (damageCharge ?? Money.zero(currency: currency));
  return ReturnSettlement(
    totalPayable: totalPayable,
    netAmount: totalPayable - deposit,
  );
}
