import 'package:test/test.dart';
import 'package:inventory/core/time/clock.dart';

void main() {
  group('SystemClock', () {
    test('returns a UTC instant close to real now', () {
      const clock = SystemClock();
      final before = DateTime.now().toUtc();
      final now = clock.now();
      final after = DateTime.now().toUtc();
      expect(now.isUtc, isTrue);
      expect(now.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(now.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('FixedClock', () {
    test('always returns the same instant until advanced', () {
      final clock = FixedClock(DateTime.utc(2026, 8, 3, 10, 0));
      expect(clock.now(), DateTime.utc(2026, 8, 3, 10, 0));
      expect(clock.now(), DateTime.utc(2026, 8, 3, 10, 0));
    });

    test('advance moves the clock forward deterministically', () {
      final clock = FixedClock(DateTime.utc(2026, 8, 3, 10, 0));
      clock.advance(const Duration(days: 1));
      expect(clock.now(), DateTime.utc(2026, 8, 4, 10, 0));
    });

    test('advance accepts a negative duration to move backward', () {
      final clock = FixedClock(DateTime.utc(2026, 8, 3, 10, 0));
      clock.advance(const Duration(hours: -2));
      expect(clock.now(), DateTime.utc(2026, 8, 3, 8, 0));
    });

    test('today() truncates to midnight UTC', () {
      final clock = FixedClock(DateTime.utc(2026, 8, 3, 23, 59, 59));
      expect(clock.today(), DateTime.utc(2026, 8, 3));
    });

    test('set jumps directly to an explicit instant, converted to UTC', () {
      final clock = FixedClock(DateTime.utc(2026, 1, 1));
      clock.set(DateTime(2026, 8, 3, 12).toUtc());
      expect(clock.now(), DateTime(2026, 8, 3, 12).toUtc());
    });
  });
}
