import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/services/due_lifecycle.dart';
import 'package:test/test.dart';

Due _pendingDue({String original = '500', int? promisedDays}) {
  return createDue(
    id: 'due-1',
    customerId: 'cust-1',
    sourceType: DueSourceType.sale,
    sourceId: 'sale-1',
    remainingAmount: Money.parse(original),
    promisedDays: promisedDays,
    now: DateTime.utc(2026, 8, 3),
  );
}

void main() {
  group('createDue', () {
    test('starts pending with zero paid', () {
      final due = _pendingDue();
      expect(due.status, DueStatus.pending);
      expect(due.paidAmount.isZero, isTrue);
      expect(due.originalAmount, Money.parse('500'));
    });

    test('rejects a non-positive remaining amount — nothing should be owed '
        'means no due should exist at all', () {
      expect(
        () => createDue(
          id: 'due-x',
          customerId: 'cust-1',
          sourceType: DueSourceType.sale,
          sourceId: 'sale-1',
          remainingAmount: Money.zero(),
          now: DateTime.utc(2026, 8, 3),
        ),
        throwsArgumentError,
      );
      expect(
        () => createDue(
          id: 'due-x',
          customerId: 'cust-1',
          sourceType: DueSourceType.sale,
          sourceId: 'sale-1',
          remainingAmount: Money.parse('-10'),
          now: DateTime.utc(2026, 8, 3),
        ),
        throwsArgumentError,
      );
    });

    test('supports a rent-sourced due with the correct sourceType', () {
      final due = createDue(
        id: 'due-rent-1',
        customerId: 'cust-2',
        sourceType: DueSourceType.rent,
        sourceId: 'rent-1',
        remainingAmount: Money.parse('30'),
        now: DateTime.utc(2026, 8, 3),
      );
      expect(due.sourceType, DueSourceType.rent);
    });
  });

  group('computeDueStatus', () {
    test('zero paid is pending', () {
      expect(
        computeDueStatus(
          originalAmount: Money.parse('100'),
          paidAmount: Money.zero(),
        ),
        DueStatus.pending,
      );
    });

    test('partial paid is partiallyPaid', () {
      expect(
        computeDueStatus(
          originalAmount: Money.parse('100'),
          paidAmount: Money.parse('40'),
        ),
        DueStatus.partiallyPaid,
      );
    });

    test('exact paid is paid', () {
      expect(
        computeDueStatus(
          originalAmount: Money.parse('100'),
          paidAmount: Money.parse('100'),
        ),
        DueStatus.paid,
      );
    });
  });

  group('applyDuePayment', () {
    test('a valid partial payment updates paidAmount and status together', () {
      final due = _pendingDue(original: '500');
      final result = applyDuePayment(
        due: due,
        paymentAmount: Money.parse('200'),
      );
      final updated = result.unwrap();
      expect(updated.paidAmount, Money.parse('200'));
      expect(updated.status, DueStatus.partiallyPaid);
    });

    test('a payment that exactly covers the remainder transitions to paid', () {
      final due = _pendingDue(original: '500');
      final result = applyDuePayment(
        due: due,
        paymentAmount: Money.parse('500'),
      );
      final updated = result.unwrap();
      expect(updated.status, DueStatus.paid);
      expect(remainingBalance(updated).isZero, isTrue);
    });

    test('two sequential partial payments accumulate correctly', () {
      final due = _pendingDue(original: '500');
      final afterFirst = applyDuePayment(
        due: due,
        paymentAmount: Money.parse('200'),
      ).unwrap();
      final afterSecond = applyDuePayment(
        due: afterFirst,
        paymentAmount: Money.parse('300'),
      ).unwrap();
      expect(afterSecond.status, DueStatus.paid);
      expect(afterSecond.paidAmount, Money.parse('500'));
    });

    test('rejects a zero or negative payment amount', () {
      final due = _pendingDue();
      expect(
        applyDuePayment(due: due, paymentAmount: Money.zero()).isErr,
        isTrue,
      );
      expect(
        applyDuePayment(due: due, paymentAmount: Money.parse('-10')).isErr,
        isTrue,
      );
    });

    test('rejects any payment against an already-paid due', () {
      final due = _pendingDue(
        original: '100',
      ).copyWith(paidAmount: Money.parse('100'), status: DueStatus.paid);
      final result = applyDuePayment(due: due, paymentAmount: Money.parse('1'));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<BusinessRuleFailure>());
    });

    test(
      'rejects a payment that would overpay the due, rather than clamping it',
      () {
        final due = _pendingDue(original: '500');
        final result = applyDuePayment(
          due: due,
          paymentAmount: Money.parse('600'),
        );
        expect(result.isErr, isTrue);
        // The original due must be untouched — a rejected payment is not a
        // partial success.
        expect(due.paidAmount.isZero, isTrue);
      },
    );
  });

  group('promisedByDate / isOverdue', () {
    test('null promisedDays means no promised date and never overdue', () {
      final due = _pendingDue();
      expect(promisedByDate(due), isNull);
      expect(isOverdue(due, DateTime.utc(2099)), isFalse);
    });

    test('promisedByDate is createdAt plus promisedDays', () {
      final due = _pendingDue(promisedDays: 7);
      expect(promisedByDate(due), DateTime.utc(2026, 8, 10));
    });

    test('is overdue once now passes the promised date', () {
      final due = _pendingDue(promisedDays: 7);
      expect(isOverdue(due, DateTime.utc(2026, 8, 9)), isFalse);
      expect(isOverdue(due, DateTime.utc(2026, 8, 11)), isTrue);
    });

    test('a paid due is never overdue, even past its promised date', () {
      final due = _pendingDue(
        promisedDays: 7,
      ).copyWith(paidAmount: Money.parse('500'), status: DueStatus.paid);
      expect(isOverdue(due, DateTime.utc(2026, 9, 1)), isFalse);
    });
  });
}
