import 'package:test/test.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/error/result.dart';

void main() {
  group('Result', () {
    test('Ok carries a value and reports isOk', () {
      const r = Result<int>.ok(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
    });

    test('Err carries a failure and reports isErr', () {
      const r = Result<int>.err(NetworkFailure());
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<NetworkFailure>());
    });

    test('map transforms only the Ok branch', () {
      const ok = Result<int>.ok(10);
      const err = Result<int>.err(BusinessRuleFailure('nope'));
      expect(ok.map((v) => v * 2).valueOrNull, 20);
      expect(err.map((v) => v * 2).failureOrNull, isA<BusinessRuleFailure>());
    });

    test('flatMap chains and short-circuits on first failure', () {
      Result<int> step1(int x) =>
          x > 0 ? Result.ok(x) : Result.err(const BusinessRuleFailure('neg'));
      Result<int> step2(int x) => Result.ok(x * 10);

      final good = step1(5).flatMap(step2);
      expect(good.valueOrNull, 50);

      final bad = step1(-5).flatMap(step2);
      expect(bad.isErr, isTrue);
      expect(bad.failureOrNull, isA<BusinessRuleFailure>());
    });

    test('fold collapses both branches to a single type', () {
      const ok = Result<int>.ok(1);
      const err = Result<int>.err(NotFoundFailure('Product', 'p1'));

      final okMsg = ok.fold(onOk: (v) => 'value=$v', onErr: (f) => 'error');
      final errMsg = err.fold(onOk: (v) => 'value=$v', onErr: (f) => f.message);

      expect(okMsg, 'value=1');
      expect(errMsg, contains('Product'));
    });

    test('getOrElse falls back only on Err', () {
      const ok = Result<int>.ok(7);
      const err = Result<int>.err(NetworkFailure());
      expect(ok.getOrElse(-1), 7);
      expect(err.getOrElse(-1), -1);
    });

    test('unwrap returns the value on Ok and throws on Err', () {
      const ok = Result<int>.ok(3);
      const err = Result<int>.err(NetworkFailure());
      expect(ok.unwrap(), 3);
      expect(() => err.unwrap(), throwsStateError);
    });
  });

  group('Failure taxonomy', () {
    test('ValidationFailure carries the offending field', () {
      const f = ValidationFailure('qty', 'must be positive');
      expect(f.field, 'qty');
      expect(f.message, 'must be positive');
    });

    test('UnknownFailure preserves the original cause and stack trace', () {
      final cause = Exception('boom');
      final trace = StackTrace.current;
      final f = UnknownFailure(cause, stackTrace: trace);
      expect(f.cause, cause);
      expect(f.stackTrace, trace);
    });

    test('switch over Failure is exhaustive (compile-time guarantee)', () {
      String describe(Failure f) => switch (f) {
        NetworkFailure() => 'network',
        ValidationFailure() => 'validation',
        NotFoundFailure() => 'not_found',
        PermissionFailure() => 'permission',
        ConflictFailure() => 'conflict',
        BusinessRuleFailure() => 'business_rule',
        UnknownFailure() => 'unknown',
      };
      expect(describe(const NetworkFailure()), 'network');
      expect(describe(const PermissionFailure()), 'permission');
    });
  });
}
