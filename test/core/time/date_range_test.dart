import 'package:inventory/core/time/date_range.dart';
import 'package:test/test.dart';

void main() {
  group('DateRange.dayContaining', () {
    test('contains the start of the day', () {
      final range = DateRange.dayContaining(DateTime.utc(2026, 8, 3, 14, 30));
      expect(range.contains(DateTime.utc(2026, 8, 3, 0, 0)), isTrue);
    });

    test('contains the end of the day but excludes midnight the next day', () {
      final range = DateRange.dayContaining(DateTime.utc(2026, 8, 3));
      expect(range.contains(DateTime.utc(2026, 8, 3, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime.utc(2026, 8, 4, 0, 0)), isFalse);
    });

    test('excludes the previous day', () {
      final range = DateRange.dayContaining(DateTime.utc(2026, 8, 3));
      expect(range.contains(DateTime.utc(2026, 8, 2, 23, 59, 59)), isFalse);
    });

    test('normalizes a non-UTC input to the correct UTC day', () {
      final localNoon = DateTime.utc(2026, 8, 3, 12).toLocal();
      final range = DateRange.dayContaining(localNoon);
      expect(range.contains(DateTime.utc(2026, 8, 3, 1)), isTrue);
    });
  });

  group('DateRange.allTime', () {
    test('contains dates far in the past and future', () {
      final range = DateRange.allTime();
      expect(range.contains(DateTime.utc(1980)), isTrue);
      expect(range.contains(DateTime.utc(2999)), isTrue);
    });
  });

  group('whereInRange', () {
    test('filters a list down to only the items inside the range — proves '
        'day-view and all-time can share one calculation, fed different '
        'inputs', () {
      final items = [
        DateTime.utc(2026, 8, 1),
        DateTime.utc(2026, 8, 3, 5),
        DateTime.utc(2026, 8, 3, 20),
        DateTime.utc(2026, 8, 4),
      ];
      final dayView = items
          .whereInRange(
            DateRange.dayContaining(DateTime.utc(2026, 8, 3)),
            (d) => d,
          )
          .toList();
      expect(dayView, [
        DateTime.utc(2026, 8, 3, 5),
        DateTime.utc(2026, 8, 3, 20),
      ]);

      final allTimeView = items
          .whereInRange(DateRange.allTime(), (d) => d)
          .toList();
      expect(allTimeView, items);
    });
  });
}
