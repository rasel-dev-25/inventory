/// Abstraction over "now", so every part of the app that needs the current
/// time gets it through DI instead of calling `DateTime.now()` directly.
///
/// This is what makes date-dependent business logic (due reminders, rent
/// overdue checks, "today's dashboard") deterministically testable, and it
/// is the seam that lets the sync engine distinguish "device clock" (used
/// only for the user-facing business date, and always editable) from
/// "server-authoritative timestamp" (used for conflict resolution — see
/// SYNC.md). Business code must depend on [Clock], never on `DateTime.now()`.
abstract class Clock {
  const Clock();

  /// The current instant, always in UTC. Convert to local/Bengali display
  /// time only in the presentation layer.
  DateTime now();

  /// Today's date at midnight UTC — convenience for "day view" filters.
  DateTime today() {
    final n = now();
    return DateTime.utc(n.year, n.month, n.day);
  }
}

/// The real system clock, used everywhere in production code.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

/// A clock that always returns a fixed instant, or one that can be
/// explicitly advanced. Used exclusively in tests so date-dependent
/// behaviour (e.g. "is this rental overdue") can be exercised deterministically.
class FixedClock extends Clock {
  DateTime _current;
  FixedClock(DateTime initial) : _current = initial.toUtc();

  @override
  DateTime now() => _current;

  /// Moves the fixed instant forward (or backward, with a negative
  /// duration) — useful for "advance one day and check overdue status"
  /// style tests.
  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  void set(DateTime instant) {
    _current = instant.toUtc();
  }
}
