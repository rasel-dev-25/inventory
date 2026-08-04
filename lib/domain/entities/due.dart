import '../../core/money/money.dart';
import 'enums.dart';

/// An outstanding balance from a credit sale or an unpaid rental charge,
/// per `notes/business_logic.md` §Due.
///
/// [originalAmount] is the amount *still owed as of when this due was
/// created* — for a partial-cash sale, that is the sale total minus
/// whatever was paid in cash at sale time, not the full sale total. The
/// spec's sale flow (§গ) only creates a Due for the unpaid remainder, so
/// modelling it any other way would double-count the cash already
/// collected. [paidAmount] only ever grows via a [DuePayment] recorded
/// after this due was created — never edited directly, see
/// `due_lifecycle.dart`'s `applyDuePayment`.
class Due {
  final String id;
  final String customerId;
  final DueSourceType sourceType;
  final String sourceId;
  final Money originalAmount;
  final Money paidAmount;

  /// Days the customer promised to pay within, counted from [createdAt].
  /// Null when no promise was made.
  final int? promisedDays;

  final DueStatus status;
  final DateTime createdAt;

  const Due({
    required this.id,
    required this.customerId,
    required this.sourceType,
    required this.sourceId,
    required this.originalAmount,
    required this.paidAmount,
    this.promisedDays,
    required this.status,
    required this.createdAt,
  });

  Due copyWith({Money? paidAmount, DueStatus? status}) {
    return Due(
      id: id,
      customerId: customerId,
      sourceType: sourceType,
      sourceId: sourceId,
      originalAmount: originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      promisedDays: promisedDays,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
