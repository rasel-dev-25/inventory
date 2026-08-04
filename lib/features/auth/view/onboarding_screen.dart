import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../controller/auth_controller.dart';
import 'sign_in_screen.dart' show errorText;

/// Shown for a signed-in user with no resolved shop membership yet —
/// either a brand-new owner who hasn't created a shop, or a staff member
/// who signed up and is waiting for their owner to add them (see
/// `add_staff_member_by_email` in
/// `supabase/migrations/0006_owner_onboarding_rpc.sql`). Both paths are
/// offered here since the app has no way to know in advance which one
/// applies — that's a business decision the person makes on this screen,
/// not something inferable from their account alone.
class OnboardingScreen extends GetView<AuthController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> createShop() async {
      if (!formKey.currentState!.validate()) return;
      await controller.createShop(shopNameController.text.trim());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('createYourShop'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'signOut'.tr,
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: shopNameController,
                          decoration: InputDecoration(labelText: 'shopName'.tr),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'shopName'.tr
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Obx(() => errorText(controller.errorMessage.value)),
                        const SizedBox(height: AppSpacing.sm),
                        Obx(
                          () => FilledButton(
                            onPressed: controller.isSubmitting.value
                                ? null
                                : createShop,
                            child: controller.isSubmitting.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('createShop'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  // Plain Text, not Obx: this string is static — it does
                  // not read any Rx value, and GetX's Obx throws
                  // "improper use of Obx" at build time for a builder
                  // that never registers an observable (only the email
                  // below actually needs to be reactive).
                  Text(
                    'waitingForOwnerInvite'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(
                    () => Text(
                      controller.session.value?.email ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: controller.refreshMembership,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
