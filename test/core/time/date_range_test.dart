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

  group('DateRange.weekContaining', () {
    test('spans Monday through Sunday regardless of which day is passed', () {
      // 2026-08-05 is a Wednesday.
      final range = DateRange.weekContaining(DateTime.utc(2026, 8, 5));
      expect(range.start, DateTime.utc(2026, 8, 3)); // Monday
      expect(range.end, DateTime.utc(2026, 8, 10)); // next Monday
    });

    test('a Monday itself is the start of its own week', () {
      final range = DateRange.weekContaining(DateTime.utc(2026, 8, 3, 18));
      expect(range.start, DateTime.utc(2026, 8, 3));
    });

    test('a Sunday belongs to the week that started the previous Monday', () {
      final range = DateRange.weekContaining(DateTime.utc(2026, 8, 9));
      expect(range.start, DateTime.utc(2026, 8, 3));
      expect(range.end, DateTime.utc(2026, 8, 10));
    });

    test('correctly crosses a month boundary', () {
      // 2026-09-02 is a Wednesday; that week starts Monday 2026-08-31.
      final range = DateRange.weekContaining(DateTime.utc(2026, 9, 2));
      expect(range.start, DateTime.utc(2026, 8, 31));
      expect(range.end, DateTime.utc(2026, 9, 7));
    });
  });

  group('DateRange.monthContaining', () {
    test('spans the first through the last day of the month', () {
      final range = DateRange.monthContaining(DateTime.utc(2026, 8, 15));
      expect(range.start, DateTime.utc(2026, 8, 1));
      expect(range.end, DateTime.utc(2026, 9, 1));
      expect(range.contains(DateTime.utc(2026, 8, 31, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime.utc(2026, 9, 1)), isFalse);
    });

    test('correctly rolls December into next January', () {
      final range = DateRange.monthContaining(DateTime.utc(2026, 12, 10));
      expect(range.start, DateTime.utc(2026, 12, 1));
      expect(range.end, DateTime.utc(2027, 1, 1));
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
