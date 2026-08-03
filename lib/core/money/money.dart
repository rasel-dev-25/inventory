/// A precise, immutable representation of a monetary amount.
///
/// Backed by an [int] count of the currency's smallest unit ("minor units" —
/// paisa for BDT) so arithmetic never touches a [double]. This is the single
/// type allowed to carry a monetary value anywhere in the app; raw `int`
/// minor-unit values must never cross a layer boundary un-wrapped.
///
/// Why this exists: the v1 codebase stored every amount as a Drift
/// `RealColumn` (an IEEE-754 double) and multiplied/divided it repeatedly
/// through unit-conversion and profit-split chains. That is guaranteed to
/// accumulate rounding error in a financial ledger. `Money` makes that class
/// of bug impossible to introduce by accident: there is no `+`/`-`/`*`/`/`
/// operator on a bare `double` amount anywhere in the domain layer.
library;

/// Thrown when constructing or parsing a [Money] value fails, e.g. mixing
/// currencies in an arithmetic operation, or parsing a malformed string.
class MoneyException implements Exception {
  final String message;
  const MoneyException(this.message);

  @override
  String toString() => 'MoneyException: $message';
}

/// An ISO-4217-ish currency descriptor. Only BDT is used today, but the
/// shape supports adding a second currency later without reworking [Money].
class Currency {
  final String code; // e.g. 'BDT'
  final String symbol; // e.g. '৳'
  final int minorUnitDigits; // e.g. 2 (paisa has 2 digits, like cents)

  const Currency({
    required this.code,
    required this.symbol,
    this.minorUnitDigits = 2,
  });

  static const bdt = Currency(code: 'BDT', symbol: '৳', minorUnitDigits: 2);

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// An immutable money amount stored as an exact integer count of minor
/// units (e.g. paisa). Two [Money] values can only be combined if they
/// share the same [currency].
class Money implements Comparable<Money> {
  /// The exact amount in minor units (paisa for BDT). Never a fraction.
  final int minorUnits;
  final Currency currency;

  const Money._(this.minorUnits, this.currency);

  /// Constructs a [Money] directly from a minor-unit integer (paisa).
  /// This is the primary, exact constructor — prefer it over [Money.fromMajor]
  /// wherever the source value is already known in minor units (e.g. a
  /// database column).
  factory Money.fromMinor(int minorUnits, {Currency currency = Currency.bdt}) {
    return Money._(minorUnits, currency);
  }

  /// Zero value in the given currency. Useful as a fold/reduce seed.
  factory Money.zero({Currency currency = Currency.bdt}) =>
      Money._(0, currency);

  /// Constructs from a major-unit decimal string, e.g. "150.50" -> 15050 paisa.
  /// This is the one sanctioned entry point for human-typed amounts (a text
  /// field) or for one-time legacy-data import. It never accepts a [double]
  /// on purpose — see [MoneyException] below for why.
  factory Money.parse(String input, {Currency currency = Currency.bdt}) {
    final trimmed = input.trim().replaceAll(',', '');
    if (trimmed.isEmpty) {
      throw const MoneyException('Cannot parse an empty amount');
    }
    final negative = trimmed.startsWith('-');
    final unsigned = negative ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2 || parts.any((p) => p.isEmpty && parts.length > 1)) {
      throw MoneyException('Malformed amount: "$input"');
    }
    final wholePart = parts[0].isEmpty ? '0' : parts[0];
    if (!RegExp(r'^\d+$').hasMatch(wholePart)) {
      throw MoneyException('Malformed amount: "$input"');
    }
    var fractionPart = parts.length == 2 ? parts[1] : '';
    if (fractionPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionPart)) {
      throw MoneyException('Malformed amount: "$input"');
    }
    final digits = currency.minorUnitDigits;
    if (fractionPart.length > digits) {
      // Truncate extra precision rather than silently rounding a typed
      // amount in a way the user didn't see.
      fractionPart = fractionPart.substring(0, digits);
    }
    fractionPart = fractionPart.padRight(digits, '0');
    final whole = int.parse(wholePart);
    final frac = fractionPart.isEmpty ? 0 : int.parse(fractionPart);
    final minor = whole * _pow10(digits) + frac;
    return Money._(negative ? -minor : minor, currency);
  }

  /// Escape hatch for interop with external `double` sources (e.g. a legacy
  /// import script reading the old Drift `RealColumn` data once during
  /// migration). Rounds to the nearest minor unit. Deliberately verbose to
  /// discourage casual use anywhere in application code — if you find
  /// yourself calling this outside a one-off import/export tool, stop and
  /// use [Money.fromMinor] or [Money.parse] instead.
  factory Money.fromDoubleMajorUnitsForLegacyImportOnly(
    double majorUnits, {
    Currency currency = Currency.bdt,
  }) {
    final minor = (majorUnits * _pow10(currency.minorUnitDigits)).round();
    return Money._(minor, currency);
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw MoneyException(
        'Cannot combine ${currency.code} with ${other.currency.code}',
      );
    }
  }

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money._(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money._(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money._(-minorUnits, currency);

  /// Multiplies by a unitless scalar quantity (e.g. a line-item quantity,
  /// or a percentage expressed as a fraction like 0.15 for 15%).
  /// Rounds to the nearest minor unit using round-half-to-even-free
  /// standard rounding, applied exactly once at the end — never chained
  /// through repeated multiply/divide the way the old codebase did.
  Money operator *(num scalar) {
    return Money._((minorUnits * scalar).round(), currency);
  }

  /// Divides by a unitless scalar. See [operator *] for rounding behaviour.
  Money operator /(num scalar) {
    if (scalar == 0) {
      throw const MoneyException('Division by zero');
    }
    return Money._((minorUnits / scalar).round(), currency);
  }

  bool operator <(Money other) {
    _requireSameCurrency(other);
    return minorUnits < other.minorUnits;
  }

  bool operator <=(Money other) {
    _requireSameCurrency(other);
    return minorUnits <= other.minorUnits;
  }

  bool operator >(Money other) {
    _requireSameCurrency(other);
    return minorUnits > other.minorUnits;
  }

  bool operator >=(Money other) {
    _requireSameCurrency(other);
    return minorUnits >= other.minorUnits;
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money get abs => isNegative ? -this : this;

  /// Splits this amount across [weights] proportionally, without losing or
  /// gaining a single minor unit to rounding. This matters anywhere the
  /// spec divides money by percentage — e.g. an investor's profit share, or
  /// splitting a purchase-trip total across multiple fund sources. Naive
  /// `amount * percent` for each share and rounding each one independently
  /// can leak or overpay a paisa; this allocates the remainder
  /// deterministically to the earliest largest-remainder shares instead
  /// (the "largest remainder method").
  List<Money> allocate(List<num> weights) {
    if (weights.isEmpty) {
      throw const MoneyException('Cannot allocate to an empty weight list');
    }
    if (weights.any((w) => w < 0)) {
      throw const MoneyException('Allocation weights must be non-negative');
    }
    final totalWeight = weights.fold<num>(0, (a, b) => a + b);
    if (totalWeight == 0) {
      throw const MoneyException('Total allocation weight cannot be zero');
    }

    final rawShares = weights.map((w) => minorUnits * w / totalWeight).toList();
    final floors = rawShares.map((r) => r.truncate()).toList();
    final remainders = <int>[];
    for (var i = 0; i < rawShares.length; i++) {
      remainders.add(i);
    }
    remainders.sort(
      (a, b) => (rawShares[b] - floors[b]).compareTo(rawShares[a] - floors[a]),
    );

    var allocated = floors.fold<int>(0, (a, b) => a + b);
    var remaining = minorUnits - allocated;
    final result = List<int>.from(floors);
    var i = 0;
    while (remaining != 0 && i < remainders.length) {
      final idx = remainders[i];
      result[idx] += remaining > 0 ? 1 : -1;
      remaining += remaining > 0 ? -1 : 1;
      i++;
    }
    return result.map((m) => Money._(m, currency)).toList();
  }

  /// Formats using South Asian (lakh/crore) digit grouping, e.g.
  /// 1234567 paisa -> "৳12,345.67" for BDT-scale amounts, and larger values
  /// group as ...,##,##,### rather than the Western ,###,###,### pattern —
  /// e.g. ৳12,34,567.00, matching how amounts are actually written and read
  /// in Bangladesh.
  String format({bool showSymbol = true}) {
    final negative = isNegative;
    final abs = minorUnits.abs();
    final digits = currency.minorUnitDigits;
    final divisor = _pow10(digits);
    final whole = abs ~/ divisor;
    final frac = abs % divisor;

    final wholeStr = whole.toString();
    final grouped = _groupSouthAsian(wholeStr);
    final fracStr = digits > 0
        ? '.${frac.toString().padLeft(digits, '0')}'
        : '';
    final symbol = showSymbol ? currency.symbol : '';
    final sign = negative ? '-' : '';
    return '$sign$symbol$grouped$fracStr';
  }

  static String _groupSouthAsian(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last3';
  }

  @override
  String toString() => format();
}
