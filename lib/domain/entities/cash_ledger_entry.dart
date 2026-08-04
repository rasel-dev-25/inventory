import '../../core/money/money.dart';
import 'enums.dart';

/// One row of the append-only cash ledger, per
/// `lib/data/local/tables/ledger.dart`'s `CashLedgerEntries` — see that
/// file for why this is append-only and why [amount] is signed rather
/// than split into separate debit/credit columns.
///
/// [sourceType] deliberately stays a plain string here, matching the
/// schema column: the set of things that can create a ledger entry (sale,
/// due payment, rent income, purchase, expense, investor repayment) is
/// small and closed today, but the schema can't express that as a single
/// foreign key (a ledger entry's source is polymorphic), so neither does
/// this entity — introducing a `CashLedgerSourceType` enum here without a
/// matching schema-level `textEnum` would create a second, redundant
/// source of truth for the same value. If a schema migration adds
/// `textEnum<CashLedgerSourceType>` later, this can follow.
class CashLedgerEntry {
  final String id;

  /// Signed: positive = cash in, negative = cash out.
  final Money amount;
  final PaymentMethod paymentMethod;
  final String sourceType;
  final String sourceId;
  final String? description;
  final DateTime date;

  const CashLedgerEntry({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.sourceType,
    required this.sourceId,
    this.description,
    required this.date,
  });
}
