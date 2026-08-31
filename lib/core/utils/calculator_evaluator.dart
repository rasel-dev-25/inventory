/// A pure Dart mathematical expression evaluator designed for financial & inventory calculators.
///
/// Supports addition (`+`), subtraction (`-`), multiplication (`×` / `*`),
/// division (`÷` / `/`), percentage calculations (`%`), and decimals (`.`).
class CalculatorEvaluator {
  const CalculatorEvaluator._();

  /// Evaluates an expression string and returns the calculated `double` or `null` if invalid.
  ///
  /// Examples:
  /// - `"100 + 50 * 2"` -> `200.0`
  /// - `"500 - 10%"` -> `450.0`
  /// - `"1200 / 12"` -> `100.0`
  /// - `"25.5 + 4.5"` -> `30.0`
  static double? evaluate(String expression) {
    final sanitized = _sanitize(expression);
    if (sanitized.isEmpty) return null;

    try {
      final tokens = _tokenize(sanitized);
      if (tokens.isEmpty) return null;
      return _parseAndEvaluate(tokens);
    } catch (_) {
      return null;
    }
  }

  /// Evaluates an expression for live preview as the user types.
  /// If the expression ends with an operator (e.g. `"100 + "`), it evaluates
  /// the sub-expression before the trailing operator.
  static double? evaluatePreview(String expression) {
    var trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    // Strip trailing operators or dots for preview
    while (trimmed.isNotEmpty &&
        (trimmed.endsWith('+') ||
            trimmed.endsWith('-') ||
            trimmed.endsWith('×') ||
            trimmed.endsWith('*') ||
            trimmed.endsWith('÷') ||
            trimmed.endsWith('/') ||
            trimmed.endsWith('.'))) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }

    return evaluate(trimmed);
  }

  /// Formats a calculated double into a clean display string without unnecessary trailing zeros.
  /// E.g. `100.0` -> `"100"`, `100.5` -> `"100.5"`, `100.556` -> `"100.56"`.
  static String formatResult(double value, {int maxDecimals = 2}) {
    if (value.isInfinite || value.isNaN) return 'Error';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final fixed = value.toStringAsFixed(maxDecimals);
    // Trim trailing zeroes after decimal point if present
    if (fixed.contains('.')) {
      final trimmed = fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return trimmed;
    }
    return fixed;
  }

  static String _sanitize(String expression) {
    return expression
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');
  }

  static List<_Token> _tokenize(String expr) {
    final tokens = <_Token>[];
    var i = 0;

    while (i < expr.length) {
      final char = expr[i];

      if (char == '+' || char == '-' || char == '*' || char == '/' || char == '%') {
        // Handle unary minus: if at start or preceded by another operator (except %)
        if (char == '-' &&
            (tokens.isEmpty ||
                (tokens.last.type == _TokenType.operator &&
                    tokens.last.op != '%'))) {
          // Unary minus - read following number
          i++;
          final start = i;
          while (i < expr.length && (RegExp(r'[0-9.]').hasMatch(expr[i]))) {
            i++;
          }
          if (start == i) throw const FormatException('Invalid negative number');
          final numStr = '-${expr.substring(start, i)}';
          final val = double.tryParse(numStr);
          if (val == null) throw const FormatException('Invalid number');
          tokens.add(_Token(_TokenType.number, value: val));
          continue;
        }

        tokens.add(_Token(_TokenType.operator, op: char));
        i++;
      } else if (RegExp(r'[0-9.]').hasMatch(char)) {
        final start = i;
        while (i < expr.length && (RegExp(r'[0-9.]').hasMatch(expr[i]))) {
          i++;
        }
        final numStr = expr.substring(start, i);
        final val = double.tryParse(numStr);
        if (val == null) throw const FormatException('Invalid number');
        tokens.add(_Token(_TokenType.number, value: val));
      } else {
        throw FormatException('Unexpected character: $char');
      }
    }

    return tokens;
  }

  static double _parseAndEvaluate(List<_Token> tokens) {
    if (tokens.isEmpty) throw const FormatException('Empty expression');

    // 1. First pass: Handle percentage `%`
    final pass1 = <_Token>[];
    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      if (tok.type == _TokenType.operator && tok.op == '%') {
        if (pass1.isEmpty || pass1.last.type != _TokenType.number) {
          throw const FormatException('Invalid percentage placement');
        }
        final prevNum = pass1.removeLast().value!;
        // Check if there is an operator and base number before this percentage
        // e.g. [500, '-', 10, '%'] -> 10% of 500 = 50
        if (pass1.length >= 2 &&
            pass1[pass1.length - 1].type == _TokenType.operator &&
            (pass1[pass1.length - 1].op == '+' || pass1[pass1.length - 1].op == '-') &&
            pass1[pass1.length - 2].type == _TokenType.number) {
          final base = pass1[pass1.length - 2].value!;
          final percentVal = base * (prevNum / 100.0);
          pass1.add(_Token(_TokenType.number, value: percentVal));
        } else {
          pass1.add(_Token(_TokenType.number, value: prevNum / 100.0));
        }
      } else {
        pass1.add(tok);
      }
    }

    // 2. Second pass: Handle multiplication `*` and division `/`
    final pass2 = <_Token>[];
    var i = 0;
    while (i < pass1.length) {
      final tok = pass1[i];
      if (tok.type == _TokenType.operator && (tok.op == '*' || tok.op == '/')) {
        if (pass2.isEmpty || pass2.last.type != _TokenType.number) {
          throw const FormatException('Missing operand before * or /');
        }
        if (i + 1 >= pass1.length || pass1[i + 1].type != _TokenType.number) {
          throw const FormatException('Missing operand after * or /');
        }

        final left = pass2.removeLast().value!;
        final right = pass1[i + 1].value!;
        i += 2;

        if (tok.op == '*') {
          pass2.add(_Token(_TokenType.number, value: left * right));
        } else {
          if (right == 0) throw const FormatException('Division by zero');
          pass2.add(_Token(_TokenType.number, value: left / right));
        }
      } else {
        pass2.add(tok);
        i++;
      }
    }

    // 3. Third pass: Handle addition `+` and subtraction `-`
    if (pass2.isEmpty || pass2.first.type != _TokenType.number) {
      throw const FormatException('Invalid start of expression');
    }

    var result = pass2.first.value!;
    var j = 1;
    while (j < pass2.length) {
      final opTok = pass2[j];
      if (opTok.type != _TokenType.operator ||
          (opTok.op != '+' && opTok.op != '-')) {
        throw const FormatException('Expected + or - operator');
      }
      if (j + 1 >= pass2.length || pass2[j + 1].type != _TokenType.number) {
        throw const FormatException('Missing operand after + or -');
      }

      final right = pass2[j + 1].value!;
      if (opTok.op == '+') {
        result += right;
      } else {
        result -= right;
      }
      j += 2;
    }

    return result;
  }
}

enum _TokenType { number, operator }

class _Token {
  final _TokenType type;
  final double? value;
  final String? op;

  _Token(this.type, {this.value, this.op});
}
