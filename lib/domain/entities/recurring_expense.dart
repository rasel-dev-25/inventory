import '../../core/money/money.dart';
import 'enums.dart';

/// Represents a recurring monthly expense template (e.g. Shop Rent, Electricity,
/// Staff Salary, WiFi) that repeats every month.
class RecurringExpense {
  final String id;
  final String title;
  final ExpenseCategory category;
  final Money amount;
  final PaymentMethod paymentMethod;
  final int dayOfMonth;
  final bool isActive;

  const RecurringExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.dayOfMonth = 1,
    this.isActive = true,
  });

  RecurringExpense copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    Money? amount,
    PaymentMethod? paymentMethod,
    int? dayOfMonth,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'amountMinor': amount.minorUnits,
    'paymentMethod': paymentMethod.name,
    'dayOfMonth': dayOfMonth,
    'isActive': isActive,
  };

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ExpenseCategory.values.byName(json['category'] as String),
      amount: Money.fromMinor((json['amountMinor'] as num).toInt()),
      paymentMethod:
          PaymentMethod.values.byName(json['paymentMethod'] as String),
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt() ?? 1,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
