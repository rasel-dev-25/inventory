import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/utils/calculator_evaluator.dart';

void main() {
  group('CalculatorEvaluator Tests', () {
    test('basic arithmetic', () {
      expect(CalculatorEvaluator.evaluate('10 + 20'), 30.0);
      expect(CalculatorEvaluator.evaluate('100 - 45'), 55.0);
      expect(CalculatorEvaluator.evaluate('12 * 8'), 96.0);
      expect(CalculatorEvaluator.evaluate('12 × 8'), 96.0);
      expect(CalculatorEvaluator.evaluate('100 / 4'), 25.0);
      expect(CalculatorEvaluator.evaluate('100 ÷ 4'), 25.0);
    });

    test('operator precedence', () {
      expect(CalculatorEvaluator.evaluate('10 + 5 * 2'), 20.0);
      expect(CalculatorEvaluator.evaluate('50 - 10 / 2'), 45.0);
      expect(CalculatorEvaluator.evaluate('20 * 2 + 15 / 3'), 45.0);
    });

    test('decimals and rounding', () {
      expect(CalculatorEvaluator.evaluate('12.5 + 7.5'), 20.0);
      expect(CalculatorEvaluator.evaluate('10.25 * 4'), 41.0);
      expect(CalculatorEvaluator.formatResult(20.0), '20');
      expect(CalculatorEvaluator.formatResult(20.5), '20.5');
      expect(CalculatorEvaluator.formatResult(20.75), '20.75');
    });

    test('percentages', () {
      // 500 - 10% = 450
      expect(CalculatorEvaluator.evaluate('500 - 10%'), 450.0);
      // 200 + 15% = 230
      expect(CalculatorEvaluator.evaluate('200 + 15%'), 230.0);
      // 1000 * 5% = 50
      expect(CalculatorEvaluator.evaluate('1000 * 5%'), 50.0);
    });

    test('live preview evaluation', () {
      expect(CalculatorEvaluator.evaluatePreview('100 + '), 100.0);
      expect(CalculatorEvaluator.evaluatePreview('100 + 50 × '), 150.0);
      expect(CalculatorEvaluator.evaluatePreview('100 + 50 * 2'), 200.0);
    });

    test('negative numbers and division by zero', () {
      expect(CalculatorEvaluator.evaluate('-10 + 30'), 20.0);
      expect(CalculatorEvaluator.evaluate('50 / 0'), isNull);
    });
  });
}
