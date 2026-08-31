import '../../core/money/money.dart';
import 'enums.dart';

/// Represents a payment received against an outstanding customer due.
class DuePayment {
  final String id;
  final String dueId;
  final Money amount;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final DateTime createdAt;

  const DuePayment({
    required this.id,
    required this.dueId,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuePayment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
