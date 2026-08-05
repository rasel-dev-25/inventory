import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/capabilities.dart';

/// A thin wrapper over `flutter_local_notifications`, gated by
/// [PlatformCapabilities.hasNotifications] — Android-only, same reasoning
/// as the camera/microphone gating elsewhere. [initialize]/[show] are
/// both safe no-ops on Windows/Web; callers never need their own
/// platform check.
///
/// **Deliberately scoped to immediate, foreground-triggered
/// notifications only** — `ReminderController` calls [show] when its own
/// reminder recomputation (driven by live database watches, while the
/// app is running) finds a new actionable reminder. This is *not* an
/// exact-alarm scheduler: it will not wake the device at a specific time
/// if the app has been fully killed, which would need
/// `zonedSchedule`/`SCHEDULE_EXACT_ALARM`/a boot receiver — real
/// additional native-Android plumbing this change does not attempt, and
/// flagged here rather than silently pretended to work. A reminder that
/// becomes due while the app is not running will still be there, correct
/// and un-missed, the next time the app opens and recomputes the inbox
/// — it just won't have pushed a system notification while closed.
class NotificationService {
  final PlatformCapabilities capabilities;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';

  bool _initialized = false;

  NotificationService(this.capabilities);

  /// Safe to call unconditionally at app start — a no-op on any platform
  /// where [PlatformCapabilities.hasNotifications] is false, and safe to
  /// call more than once (only the first call does anything).
  Future<void> initialize() async {
    if (!capabilities.hasNotifications || _initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // Android 13+ (API 33) requires this to be requested explicitly at
    // runtime — a no-op (returns true) on older Android versions where
    // notification permission is granted at install time instead.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Shows an immediate notification. [id] should be a stable hash of
  /// whatever this notification is *about* (see
  /// `ReminderController._notificationIdFor`) so re-showing the same
  /// logical notification replaces the previous one instead of stacking
  /// duplicates.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!capabilities.hasNotifications || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
