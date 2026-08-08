import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Central logging wrapper for the app.
///
/// Usage:
///   AppLogger.d('tag', 'some debug message');
///   AppLogger.i('SyncPull', 'pulled 5 rows from customers');
///   AppLogger.w('AuthController', 'session stream fired twice for same user');
///   AppLogger.e('SyncTransport', 'Supabase error', error: e, stackTrace: st);
///
/// In release builds all output is suppressed automatically (kDebugMode check).
/// In debug builds coloured, tagged log lines appear in the Flutter debug console.
abstract final class AppLogger {
  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,       // no stack frames in normal log lines
      errorMethodCount: 8,  // but show stack on errors
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // Suppress everything outside debug builds.
    level: kDebugMode ? Level.trace : Level.off,
  );

  /// Verbose trace — only use for very noisy per-row iteration logs.
  static void t(String tag, Object? message) =>
      _log.t('[$tag] $message');

  /// Debug — the most common level; sign-in flow, sync decisions, etc.
  static void d(String tag, Object? message) =>
      _log.d('[$tag] $message');

  /// Informational — successful high-level milestones (sync complete, etc.).
  static void i(String tag, Object? message) =>
      _log.i('[$tag] $message');

  /// Warning — unexpected but recoverable situations.
  static void w(String tag, Object? message, {Object? error}) =>
      _log.w('[$tag] $message', error: error);

  /// Error — failures that surface to the user or require investigation.
  static void e(
    String tag,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log.e('[$tag] $message', error: error, stackTrace: stackTrace);
}
