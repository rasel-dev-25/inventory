import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The set of hardware/OS capabilities that vary across the three shipping
/// targets (Android phone, Windows desktop, Web). Every feature that
/// depends on one of these must check the flag and degrade explicitly
/// (file-picker fallback, a disabled button with an explanation) — it must
/// never crash, and it must never just silently disappear leaving the user
/// wondering where a button went.
///
/// This is a value object, not a service: it is computed once from the
/// platform, has no mutable state, and needs no DI lifecycle. Inject it via
/// [PlatformCapabilities.detect] at app start and pass it down, so widgets
/// never call `Platform.isWindows` etc. directly and every capability check
/// in the app reads from one place.
class PlatformCapabilities {
  final bool isWeb;
  final bool isAndroid;
  final bool isWindows;
  final bool isDesktop;
  final bool hasCamera;
  final bool hasMicrophone;
  final bool hasFileSystemAccess;

  const PlatformCapabilities({
    required this.isWeb,
    required this.isAndroid,
    required this.isWindows,
    required this.isDesktop,
    required this.hasCamera,
    required this.hasMicrophone,
    required this.hasFileSystemAccess,
  });

  /// Detects capabilities for the platform this build is actually running
  /// on. Safe to call on web: every `dart:io` `Platform.isX` check is
  /// short-circuited behind [kIsWeb] first, since `Platform` throws on web.
  factory PlatformCapabilities.detect() {
    if (kIsWeb) {
      return const PlatformCapabilities(
        isWeb: true,
        isAndroid: false,
        isWindows: false,
        isDesktop: false,
        // Browsers can be granted camera/mic permission, but per the spec's
        // QuickCapture flow (native OS voice recorder / gallery integration)
        // we treat web as file-picker-only for now — see ARCHITECTURE.md.
        hasCamera: false,
        hasMicrophone: false,
        hasFileSystemAccess: false,
      );
    }
    final isAndroid = Platform.isAndroid;
    final isWindows = Platform.isWindows;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return PlatformCapabilities(
      isWeb: false,
      isAndroid: isAndroid,
      isWindows: isWindows,
      isDesktop: isDesktop,
      hasCamera: isAndroid,
      hasMicrophone: isAndroid,
      hasFileSystemAccess: true,
    );
  }

  /// A fixed instance for widget tests / previews that don't run on a real
  /// platform channel — defaults to "full capability" (Android-like) so
  /// existing tests don't need to know about capability gating unless
  /// they're specifically testing it.
  static const forTesting = PlatformCapabilities(
    isWeb: false,
    isAndroid: true,
    isWindows: false,
    isDesktop: false,
    hasCamera: true,
    hasMicrophone: true,
    hasFileSystemAccess: true,
  );
}
