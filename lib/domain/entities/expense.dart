import '../../core/money/money.dart';
import 'enums.dart';

/// A shop expense, per `notes/business_logic.md` §Expense/§চ.
///
/// > "নিয়ম: এই খরচ বেচা-কেনা থেকে আসা ক্যাশ থেকেই দেওয়া হয় — অর্থাৎ Total
/// > Cash থেকে বিয়োগ হবে, কোনো ইনভেস্টরের আলাদা ফান্ড থেকে না।"
///
/// Every [Expense] reduces Total Cash directly (see [ExpenseUseCases]'s
/// paired `cash_ledger_entries` write) and never draws from a specific
/// investor's fund — unlike a [PurchaseItem], there is no [FundSource] on
/// this entity at all, by design.
class Expense {
  final String id;
  final ExpenseCategory category;
  final Money amount;
  final DateTime date;
  final String? description;
  final PaymentMethod paymentMethod;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.description,
  });
}
