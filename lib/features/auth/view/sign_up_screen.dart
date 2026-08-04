import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../controller/auth_controller.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends GetView<AuthController> {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      if (passwordController.text != confirmController.text) {
        controller.errorMessage.value = 'passwordsDontMatch'.tr;
        return;
      }
      await controller.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('signUp'.tr)),
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
                      decoration: InputDecoration(labelText: 'password'.tr),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'password'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'confirmPassword'.tr,
                      ),
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
                            : Text('signUp'.tr),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => Get.off(() => const SignInScreen()),
                      child: Text('haveAccountSignIn'.tr),
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
