import 'package:inventory/core/money/money.dart';
import 'package:inventory/core/time/date_range.dart';
import 'package:inventory/domain/entities/cash_ledger_entry.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/services/cash_balance_calculator.dart';
import 'package:test/test.dart';

CashLedgerEntry _entry({
  required String amount,
  PaymentMethod method = PaymentMethod.cash,
  DateTime? date,
  String sourceType = 'sale',
}) {
  return CashLedgerEntry(
    id: 'entry-$amount-$method-$sourceType-${date ?? ''}',
    amount: Money.parse(amount),
    paymentMethod: method,
    sourceType: sourceType,
    sourceId: 'src-1',
    date: date ?? DateTime.utc(2026, 8, 3),
  );
}

void main() {
  group('calculateCashBalances', () {
    test('sums entries into the correct payment-method bucket', () {
      final balances = calculateCashBalances([
        _entry(amount: '100', method: PaymentMethod.cash),
        _entry(amount: '50', method: PaymentMethod.mobileBanking),
        _entry(amount: '200', method: PaymentMethod.bankTransfer),
      ]);
      expect(balances.cashBalance, Money.parse('100'));
      expect(balances.mobileBankingBalance, Money.parse('50'));
      expect(balances.bankBalance, Money.parse('200'));
    });

    test('totalAvailableFunds is the sum of all three sub-balances', () {
      final balances = calculateCashBalances([
        _entry(amount: '100', method: PaymentMethod.cash),
        _entry(amount: '50', method: PaymentMethod.mobileBanking),
        _entry(amount: '200', method: PaymentMethod.bankTransfer),
      ]);
      expect(balances.totalAvailableFunds, Money.parse('350'));
    });

    test('negative (outflow) entries reduce the balance — this is exactly '
        'how an expense or a purchase should affect cash', () {
      final balances = calculateCashBalances([
        _entry(amount: '500', method: PaymentMethod.cash), // a sale
        _entry(amount: '-120', method: PaymentMethod.cash), // an expense
      ]);
      expect(balances.cashBalance, Money.parse('380'));
    });

    test('multiple entries of the same payment method accumulate', () {
      final balances = calculateCashBalances([
        _entry(amount: '100', method: PaymentMethod.mobileBanking),
        _entry(amount: '200', method: PaymentMethod.mobileBanking),
        _entry(amount: '-50', method: PaymentMethod.mobileBanking),
      ]);
      expect(balances.mobileBankingBalance, Money.parse('250'));
    });

    test('an empty ledger produces all-zero balances, not a crash', () {
      final balances = calculateCashBalances([]);
      expect(balances.cashBalance.isZero, isTrue);
      expect(balances.mobileBankingBalance.isZero, isTrue);
      expect(balances.bankBalance.isZero, isTrue);
      expect(balances.totalAvailableFunds.isZero, isTrue);
    });

    test('day view and all-time view are the same function, fed different '
        'inputs via DateRange — never two different formulas', () {
      final entries = [
        _entry(amount: '100', date: DateTime.utc(2026, 8, 2)),
        _entry(amount: '200', date: DateTime.utc(2026, 8, 3, 9)),
        _entry(amount: '300', date: DateTime.utc(2026, 8, 3, 18)),
        _entry(amount: '400', date: DateTime.utc(2026, 8, 4)),
      ];

      final dayView = calculateCashBalances(
        entries.whereInRange(
          DateRange.dayContaining(DateTime.utc(2026, 8, 3)),
          (e) => e.date,
        ),
      );
      expect(dayView.cashBalance, Money.parse('500')); // 200 + 300

      final allTimeView = calculateCashBalances(
        entries.whereInRange(DateRange.allTime(), (e) => e.date),
      );
      expect(allTimeView.cashBalance, Money.parse('1000'));
    });

    test('reconciles against a hand-computed total across all three methods '
        'and both directions — the spec\'s "sanity check" this function exists '
        'to make trustworthy', () {
      final balances = calculateCashBalances([
        _entry(amount: '1000', method: PaymentMethod.cash, sourceType: 'sale'),
        _entry(
          amount: '500',
          method: PaymentMethod.mobileBanking,
          sourceType: 'duePayment',
        ),
        _entry(
          amount: '2000',
          method: PaymentMethod.bankTransfer,
          sourceType: 'rentIncome',
        ),
        _entry(
          amount: '-300',
          method: PaymentMethod.cash,
          sourceType: 'purchase',
        ),
        _entry(
          amount: '-150',
          method: PaymentMethod.cash,
          sourceType: 'expense',
        ),
        _entry(
          amount: '-1000',
          method: PaymentMethod.bankTransfer,
          sourceType: 'investorRepayment',
        ),
      ]);
      expect(balances.cashBalance, Money.parse('550')); // 1000 - 300 - 150
      expect(balances.mobileBankingBalance, Money.parse('500'));
      expect(balances.bankBalance, Money.parse('1000')); // 2000 - 1000
      expect(balances.totalAvailableFunds, Money.parse('2050'));
    });
  });
}
