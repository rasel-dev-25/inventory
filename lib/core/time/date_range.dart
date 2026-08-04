/// A half-open time interval `[start, end)` — [start] is inclusive, [end]
/// is exclusive. This is the mechanism `notes/business_logic.md` §ঝ asks
/// for explicitly:
///
/// > "একই ক্যালকুলেশন ফাংশনে dateRange প্যারামিটার দিয়ে Day view ও All-time
/// > view — দুটোই একই লজিক দিয়ে সার্ভ করা ভালো (কোড ডুপ্লিকেশন এড়াতে)"
///
/// None of the calculators in `domain/services/` take a [DateRange]
/// parameter directly — they stay pure functions over whatever list a
/// caller passes in. [DateRange] is the reusable, testable *filter*
/// applied before calling one of them, so "day view" and "all-time view"
/// really are the same calculation, called twice with different inputs,
/// never two different formulas — the exact thing the v1 dashboard got
/// wrong (`loadDashboard()`'s totals were always all-time regardless of
/// the selected date; `_loadActivitiesForDate()` was a second, separate
/// code path that only filtered a secondary activity list).
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// The single UTC calendar day containing [day] (midnight to midnight).
  factory DateRange.dayContaining(DateTime day) {
    final utc = day.toUtc();
    final start = DateTime.utc(utc.year, utc.month, utc.day);
    return DateRange(start: start, end: start.add(const Duration(days: 1)));
  }

  /// Effectively unbounded — used for the "all-time" view so the exact
  /// same filtering code path (`range.contains`) works for both views.
  factory DateRange.allTime() {
    return DateRange(start: DateTime.utc(1970), end: DateTime.utc(9999));
  }

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(start) && utc.isBefore(end);
  }
}

extension DateRangeFilter<T> on Iterable<T> {
  /// Filters this collection to only the elements whose [dateOf] falls
  /// inside [range]. The one place "day view vs. all-time" logic should
  /// ever be applied — call a calculator with `list.whereInRange(range,
  /// (x) => x.date)` rather than hand-rolling a date comparison at the
  /// call site.
  Iterable<T> whereInRange(DateRange range, DateTime Function(T) dateOf) {
    return where((item) => range.contains(dateOf(item)));
  }
}
