import '../../core/money/money.dart';
import 'enums.dart';

/// A payment made *to* an investor, per `notes/business_logic.md` §Investor
/// and §Investor page's "কবে দিতে হবে" / repayment tracking. Mirrors
/// `lib/data/local/tables/investors.dart`'s `InvestorRepayments` — append-
/// only, same reasoning as `CashLedgerEntries`: a mistaken entry is
/// corrected with a reversal row, never edited or deleted.
///
/// [type] distinguishes a capital return (money the investor originally
/// put in, going back to them) from a profit-share payout — see
/// `investor_metrics.dart`'s `remainingBalance`, which only subtracts
/// `RepaymentType.capitalReturn` rows, never profit-share ones (paying an
/// investor their profit doesn't reduce how much of their *capital* the
/// shop still owes).
class InvestorRepayment {
  final String id;
  final String investorId;
  final Money amount;
  final RepaymentType type;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const InvestorRepayment({
    required this.id,
    required this.investorId,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.date,
  });
}
