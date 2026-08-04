import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/rent_transaction.dart';
import 'package:inventory/domain/services/rent_lifecycle.dart';

const _tiers = [
  (maxPages: 50, days: 5, priceMinor: 500),
  (maxPages: 100, days: 10, priceMinor: 1000),
  (maxPages: 200, days: 15, priceMinor: 2000),
  (maxPages: 300, days: 20, priceMinor: 3000),
];

RentTransaction _rent({
  required DateTime startDate,
  required DateTime dueDate,
  RentStatus status = RentStatus.active,
  String? amount,
  String deposit = '0',
}) {
  return RentTransaction(
    id: 'rent-1',
    bookProductId: 'book-1',
    customerId: 'cust-1',
    startDate: startDate,
    dueDate: dueDate,
    deposit: Money.parse(deposit),
    rentPrice: Money.parse(amount ?? '10'),
    status: status,
  );
}

void main() {
  group('suggestTierFor', () {
    test('picks the smallest tier whose maxPages still covers the book', () {
      final tier = suggestTierFor(120, _tiers);
      expect(tier!.days, 15);
      expect(tier.price, Money.parse('20'));
    });

    test('matches exactly at a tier boundary', () {
      final tier = suggestTierFor(100, _tiers);
      expect(tier!.days, 10);
      expect(tier.price, Money.parse('10'));
    });

    test('returns null when no tier covers the page count', () {
      expect(suggestTierFor(500, _tiers), isNull);
    });
  });

  group('computeDueDate', () {
    test('adds the tier days to the start date', () {
      final due = computeDueDate(startDate: DateTime.utc(2026, 1, 1), days: 10);
      expect(due, DateTime.utc(2026, 1, 11));
    });
  });

  group('isOverdue', () {
    test('true when unreturned and past the due date', () {
      final rent = _rent(
        startDate: DateTime.utc(2026, 1, 1),
        dueDate: DateTime.utc(2026, 1, 10),
      );
      expect(isOverdue(rent, DateTime.utc(2026, 1, 11)), isTrue);
    });

    test('false when not yet due', () {
      final rent = _rent(
        startDate: DateTime.utc(2026, 1, 1),
        dueDate: DateTime.utc(2026, 1, 10),
      );
      expect(isOverdue(rent, DateTime.utc(2026, 1, 5)), isFalse);
    });

    test('false once returned, even if it was overdue when returned', () {
      final rent = _rent(
        status: RentStatus.returned,
        startDate: DateTime.utc(2026, 1, 1),
        dueDate: DateTime.utc(2026, 1, 10),
      );
      expect(isOverdue(rent, DateTime.utc(2026, 1, 20)), isFalse);
    });
  });

  group('computeExtraDays', () {
    test('is zero when returned on or before the due date', () {
      expect(
        computeExtraDays(
          dueDate: DateTime.utc(2026, 1, 10),
          actualReturnDate: DateTime.utc(2026, 1, 10),
        ),
        0,
      );
      expect(
        computeExtraDays(
          dueDate: DateTime.utc(2026, 1, 10),
          actualReturnDate: DateTime.utc(2026, 1, 5),
        ),
        0,
      );
    });

    test('counts whole days late', () {
      expect(
        computeExtraDays(
          dueDate: DateTime.utc(2026, 1, 10),
          actualReturnDate: DateTime.utc(2026, 1, 13),
        ),
        3,
      );
    });
  });

  group('suggestExtraDayCharge', () {
    test('is extraDays times the per-day rate', () {
      expect(
        suggestExtraDayCharge(extraDays: 3, perDayRate: Money.parse('2')),
        Money.parse('6'),
      );
    });
  });

  group('computeReturnSettlement', () {
    test('customer owes when charges exceed the deposit', () {
      final settlement = computeReturnSettlement(
        rentPrice: Money.parse('10'),
        deposit: Money.parse('5'),
        extraDayCharge: Money.parse('6'),
      );
      expect(settlement.totalPayable, Money.parse('16'));
      expect(settlement.netAmount, Money.parse('11'));
      expect(settlement.customerOwes, isTrue);
      expect(settlement.refundOwed, isFalse);
    });

    test('a refund is owed when the deposit exceeds the total', () {
      final settlement = computeReturnSettlement(
        rentPrice: Money.parse('10'),
        deposit: Money.parse('50'),
      );
      expect(settlement.netAmount, Money.parse('-40'));
      expect(settlement.refundOwed, isTrue);
      expect(settlement.customerOwes, isFalse);
      expect(settlement.refundAmount, Money.parse('40'));
    });

    test('exactly zero when the deposit matches the total precisely', () {
      final settlement = computeReturnSettlement(
        rentPrice: Money.parse('10'),
        deposit: Money.parse('10'),
      );
      expect(settlement.netAmount.isZero, isTrue);
      expect(settlement.customerOwes, isFalse);
      expect(settlement.refundOwed, isFalse);
    });

    test('damage charge adds to the total payable like extra-day charge', () {
      final settlement = computeReturnSettlement(
        rentPrice: Money.parse('10'),
        deposit: Money.zero(),
        damageCharge: Money.parse('25'),
      );
      expect(settlement.totalPayable, Money.parse('35'));
    });
  });
}
