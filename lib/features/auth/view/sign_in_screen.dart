import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../controller/auth_controller.dart';
import 'sign_up_screen.dart';

class SignInScreen extends GetView<AuthController> {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      await controller.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'appTitle'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: 'email'.tr),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                          ? 'email'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: 'password'.tr),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'password'.tr
                          : null,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Obx(() => errorText(controller.errorMessage.value)),
                    const SizedBox(height: AppSpacing.sm),
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : submit,
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('signIn'.tr),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => Get.to(() => const SignUpScreen()),
                      child: Text('noAccountSignUp'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared by sign-in/sign-up/onboarding — a fixed-height slot so the
/// error text appearing/disappearing doesn't jump the layout of the
/// button beneath it.
Widget errorText(String? message) {
  return SizedBox(
    height: 20,
    child: message == null
        ? null
        : Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
  );
}
