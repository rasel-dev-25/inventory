import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shell/view/shell_screen.dart';
import '../../sync/controller/sync_controller.dart';
import '../controller/auth_controller.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

/// The app's actual root widget (registered as `AppRoutes.shell` in
/// `app_pages.dart`, replacing the bare `ShellScreen`). Watches
/// [AuthController.status] and renders exactly one of: a loading
/// spinner, sign-in, onboarding, or the existing shell — so every other
/// screen in the app can assume a resolved session + shop membership
/// exists by the time it's reachable, instead of each one re-checking
/// auth state itself.
class AuthGate extends GetView<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case AuthUiStatus.loading:
          return const _InitialSyncLoadingView();
        case AuthUiStatus.signedOut:
          return const SignInScreen();
        case AuthUiStatus.needsOnboarding:
          return const OnboardingScreen();
        case AuthUiStatus.ready:
          return const ShellScreen();
      }
    });
  }
}

class _InitialSyncLoadingView extends StatelessWidget {
  const _InitialSyncLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSyncRegistered = Get.isRegistered<SyncController>();
    final syncController = isSyncRegistered ? Get.find<SyncController>() : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branded Logo / Store Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                Text(
                  'দোকান ইনভেন্টরি',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'আপনার ক্লাউড ডেটাবেজের সাথে সংযোগ হচ্ছে...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 36),

                // Reactive Progress Indicator & Live Message
                if (syncController != null)
                  Obx(() {
                    final fraction = syncController.syncProgressFraction.value;
                    final message = syncController.syncProgressMessage.value;
                    final isSyncing = syncController.isInitialSyncing.value;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  message,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSyncing && fraction > 0)
                                Text(
                                  '${(fraction * 100).toInt()}%',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isSyncing && fraction > 0
                                ? LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 6,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  )
                                : const LinearProgressIndicator(
                                    minHeight: 6,
                                  ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),

                const SizedBox(height: 24),
                Text(
                  'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
