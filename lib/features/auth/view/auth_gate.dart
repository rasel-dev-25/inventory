import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shell/view/shell_screen.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
