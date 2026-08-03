import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('parses a whole taka amount', () {
      expect(Money.parse('150').minorUnits, 15000);
    });

    test('parses paisa correctly', () {
      expect(Money.parse('150.50').minorUnits, 15050);
      expect(Money.parse('150.5').minorUnits, 15050);
      expect(Money.parse('0.05').minorUnits, 5);
    });

    test('parses negative amounts', () {
      expect(Money.parse('-25.75').minorUnits, -2575);
    });

    test('strips thousands separators', () {
      expect(Money.parse('12,345.67').minorUnits, 1234567);
    });

    test('truncates extra fractional precision rather than guessing', () {
      expect(Money.parse('10.999').minorUnits, 1099);
    });

    test('rejects malformed input', () {
      expect(() => Money.parse('abc'), throwsA(isA<MoneyException>()));
      expect(() => Money.parse(''), throwsA(isA<MoneyException>()));
      expect(() => Money.parse('1.2.3'), throwsA(isA<MoneyException>()));
    });
  });

  group('arithmetic', () {
    test('add and subtract stay exact', () {
      final a = Money.parse('10.10');
      final b = Money.parse('0.20');
      expect((a + b).minorUnits, 1030);
      expect((a - b).minorUnits, 990);
    });

    test('refuses to combine different currencies', () {
      final bdt = Money.parse('10', currency: Currency.bdt);
      const usd = Currency(code: 'USD', symbol: r'$');
      final other = Money.parse('10', currency: usd);
      expect(() => bdt + other, throwsA(isA<MoneyException>()));
    });

    test('multiply by scalar rounds once, at the end', () {
      // 33.33 * 3 = 99.99 exactly — no rounding drift expected here.
      final price = Money.parse('33.33');
      expect((price * 3).minorUnits, 9999);
    });

    test('multiply by a fractional percent rounds to nearest paisa', () {
      final amount = Money.parse('100.00');
      // 100.00 * 0.15 = 15.00 exactly
      expect((amount * 0.15).minorUnits, 1500);
      // A case that does not divide evenly: 10.01 * (1/3)
      final third = Money.parse('10.01') / 3;
      expect(third.minorUnits, 334); // 333.67 rounds to 334
    });

    test('division by zero throws instead of producing Infinity', () {
      final amount = Money.parse('10');
      expect(() => amount / 0, throwsA(isA<MoneyException>()));
    });

    test('comparisons order correctly including negatives', () {
      final a = Money.parse('-5');
      final b = Money.parse('5');
      expect(a < b, isTrue);
      expect(b > a, isTrue);
      expect(a <= a, isTrue);
    });

    test('abs and sign helpers', () {
      final negative = Money.parse('-42.00');
      expect(negative.isNegative, isTrue);
      expect(negative.abs.isPositive, isTrue);
      expect(Money.zero().isZero, isTrue);
    });
  });

  group('allocate (largest remainder method)', () {
    test('splits evenly divisible amounts with no leakage', () {
      final total = Money.parse('100.00');
      final shares = total.allocate([1, 1, 1, 1]); // 4-way even split
      expect(shares.map((m) => m.minorUnits), [2500, 2500, 2500, 2500]);
      final sum = shares.fold(Money.zero(), (a, b) => a + b);
      expect(sum, total);
    });

    test('never loses or gains a paisa on an uneven split', () {
      // 100.00 split three ways: naive 33.33/33.33/33.33 = 99.99, losing 1 paisa.
      final total = Money.parse('100.00');
      final shares = total.allocate([1, 1, 1]);
      final sum = shares.fold(Money.zero(), (a, b) => a + b);
      expect(
        sum,
        total,
        reason: 'allocation must reconstitute the exact total',
      );
      expect(shares.map((m) => m.minorUnits).reduce((a, b) => a + b), 10000);
    });

    test(
      'honours weighted (percentage-like) splits, e.g. investor profit share',
      () {
        // A profitSharePercent of 30% for the investor, 70% retained by shop.
        final grossProfit = Money.parse('1000.33');
        final shares = grossProfit.allocate([30, 70]);
        final sum = shares.fold(Money.zero(), (a, b) => a + b);
        expect(sum, grossProfit);
      },
    );

    test('rejects an empty or all-zero weight list', () {
      final total = Money.parse('10');
      expect(() => total.allocate([]), throwsA(isA<MoneyException>()));
      expect(() => total.allocate([0, 0]), throwsA(isA<MoneyException>()));
    });

    test('works correctly on a negative total (e.g. a reversal)', () {
      final total = Money.parse('-99.99');
      final shares = total.allocate([1, 1, 1]);
      final sum = shares.fold(Money.zero(), (a, b) => a + b);
      expect(sum, total);
    });
  });

  group('format (South Asian grouping)', () {
    test(
      'groups small amounts with a single comma before the last 3 digits',
      () {
        expect(Money.parse('12345.67').format(), '৳12,345.67');
      },
    );

    test('groups larger amounts in the lakh/crore pattern', () {
      // 1,234,567.00 in Western grouping is 12,34,567.00 in South Asian grouping.
      expect(Money.parse('1234567.00').format(), '৳12,34,567.00');
      expect(Money.parse('123456789.00').format(), '৳12,34,56,789.00');
    });

    test('formats amounts under 1000 with no comma', () {
      expect(Money.parse('999.50').format(), '৳999.50');
      expect(Money.parse('5').format(), '৳5.00');
    });

    test('formats negative amounts with a leading minus before the symbol', () {
      expect(Money.parse('-500').format(), '-৳500.00');
    });

    test('can omit the currency symbol', () {
      expect(Money.parse('500').format(showSymbol: false), '500.00');
    });
  });

  group('legacy double interop', () {
    test('fromDoubleMajorUnitsForLegacyImportOnly rounds to nearest paisa', () {
      final m = Money.fromDoubleMajorUnitsForLegacyImportOnly(10.005);
      expect(m.minorUnits, 1001); // rounds, doesn't truncate
    });
  });
}
