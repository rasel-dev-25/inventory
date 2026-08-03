/// The design system's raw scales: spacing, radius and elevation.
///
/// This is what the old `app_colors.dart` (9 lines: two colours and two
/// radii) was missing — every screen in the old app hardcoded its own
/// `EdgeInsets`, `fontSize` and one-off `Colors.grey.shadeNNN` literal
/// instead of pulling from a shared scale. That is also why dark mode was
/// broken on most screens: a literal `Colors.white` container background
/// never responds to `ThemeMode.dark`. Every widget built from M1 onward
/// must read colour from `Theme.of(context).colorScheme` and spacing/radius
/// from these tokens — never a raw literal.
library;

/// An 8-point spacing scale. Pick the nearest token instead of an arbitrary
/// pixel value; if nothing fits, that's a signal to revisit the layout
/// rather than reach for a one-off number.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radius scale, shared by every card/sheet/button/dialog.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

/// Elevation/shadow scale for surfaces that sit above the background.
abstract final class AppElevation {
  static const double flat = 0;
  static const double card = 1;
  static const double raised = 3;
  static const double overlay = 8;
}

/// Breakpoints for the responsive shell (bottom nav on phone, side rail on
/// desktop/web — see the shell rebuild in M1).
abstract final class AppBreakpoints {
  static const double compact = 600; // phone
  static const double medium = 1024; // small desktop / tablet landscape
  // >= medium is treated as "expanded" (desktop/web wide layout).
}

/// Standard animation durations, so slide-up forms and transitions across
/// the app feel consistent instead of each screen picking its own number.
abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
