/// Total Cash and the payment-method sub-balances, per
/// `notes/business_logic.md` §ঝ and §PaymentMethod.
///
/// The v1 dashboard computed "total cash" as
/// `Σ(Sale.amount where type=='cash')` — one table, ignoring due payments,
/// rent income, purchase cash-out, expenses, and investor repayments
/// entirely. That number could never reconcile with what was actually in
/// the till. Here, Total Cash is never a bespoke formula touching five
/// tables again — it is always exactly `Σ(CashLedgerEntry.amount)` over
/// whichever entries the caller passes in, because every one of those six
/// event kinds already mirrors into [CashLedgerEntry] as a signed amount
/// (see `lib/data/local/tables/ledger.dart`). This function cannot drift
/// from reality the way the v1 formula did, because there is no second
/// formula for it to drift from — the ledger table *is* the definition.
library;

import '../../core/money/money.dart';
import '../entities/cash_ledger_entry.dart';
import '../entities/enums.dart';

class CashBalances {
  final Money cashBalance;
  final Money mobileBankingBalance;
  final Money bankBalance;

  const CashBalances({
    required this.cashBalance,
    required this.mobileBankingBalance,
    required this.bankBalance,
  });

  /// "Total Available Funds" per business_logic.md's PaymentMethod
  /// section — the sum of all three sub-balances.
  Money get totalAvailableFunds =>
      cashBalance + mobileBankingBalance + bankBalance;
}

/// Sums [entries] into the three payment-method sub-balances plus their
/// total. Pass every ledger entry ever recorded for "all-time"; pass only
/// entries filtered by `DateRange.dayContaining(today)` (see
/// `lib/core/time/date_range.dart`) for "day view" — same function,
/// different input, per the spec's explicit implementation note against
/// duplicating this logic.
CashBalances calculateCashBalances(
  Iterable<CashLedgerEntry> entries, {
  Currency currency = Currency.bdt,
}) {
  var cash = Money.zero(currency: currency);
  var mobileBanking = Money.zero(currency: currency);
  var bank = Money.zero(currency: currency);

  for (final entry in entries) {
    switch (entry.paymentMethod) {
      case PaymentMethod.cash:
        cash += entry.amount;
      case PaymentMethod.mobileBanking:
        mobileBanking += entry.amount;
      case PaymentMethod.bankTransfer:
        bank += entry.amount;
    }
  }

  return CashBalances(
    cashBalance: cash,
    mobileBankingBalance: mobileBanking,
    bankBalance: bank,
  );
}
