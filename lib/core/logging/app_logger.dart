import 'dart:developer' as developer;

/// Severity for a log entry. Kept small and explicit rather than the usual
/// 6-level scheme — this app only ever needs to distinguish "developer
/// trace", "something worth knowing", and "something is actually wrong".
enum LogLevel { debug, info, warning, error }

/// The single logging entry point for the app. Every `catch` block must log
/// through this — the old codebase's `catch (Object e) { showSnackbar(e) }`
/// pattern discarded the stack trace and left no record once the snackbar
/// disappeared. `AppLogger` always keeps the stack trace when one is given,
/// and is the seam where we can later attach a remote error reporter
/// without touching call sites.
class AppLogger {
  final String tag;
  const AppLogger(this.tag);

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warning(String message, [Object? error]) =>
      _log(LogLevel.warning, message, error: error);
  void error(String message, Object error, [StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: _severityOf(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  int _severityOf(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };
}
