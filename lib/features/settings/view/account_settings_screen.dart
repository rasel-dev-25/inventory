import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/view/sign_in_screen.dart' show errorText;
import '../../sync/controller/sync_controller.dart';

/// Account/auth settings — sign-out and, for an owner, inviting staff by
/// email (`AuthController.inviteStaff`, backed by
/// `add_staff_member_by_email` — see `supabase/migrations/
/// 0006_owner_onboarding_rpc.sql`). New in M1: v1 had no concept of a
/// signed-in user at all, so there was nothing here to add to before.
class AccountSettingsScreen extends GetView<AuthController> {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('account'.tr)),
      body: Obx(() {
        final session = controller.session.value;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'signedInAs'.tr,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      session?.email ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('${'role'.tr}: ${session?.role?.name ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SyncSection(),
            const SizedBox(height: AppSpacing.xl),
            if (session?.isOwner ?? false) ...[
              Text(
                'inviteStaffByEmail'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _InviteStaffForm(),
              const SizedBox(height: AppSpacing.xl),
            ],
            OutlinedButton.icon(
              onPressed: controller.signOut,
              icon: const Icon(Icons.logout),
              label: Text('signOut'.tr),
            ),
          ],
        );
      }),
    );
  }
}

class _InviteStaffForm extends GetView<AuthController> {
  const _InviteStaffForm();

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'email'.tr),
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => errorText(controller.errorMessage.value)),
        const SizedBox(height: AppSpacing.sm),
        Obx(
          () => FilledButton(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    final ok = await controller.inviteStaff(
                      emailController.text.trim(),
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('staffInvitedSuccessfully'.tr)),
                      );
                      emailController.clear();
                    }
                  },
            child: controller.isSubmitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('invite'.tr),
          ),
        ),
      ],
    );
  }
}

/// Manual push-then-pull, via `SyncController.syncNow()` — see that
/// class's doc comment for why this is push-then-pull rather than
/// concurrent, and SYNC.md for the outbox/puller design underneath it.
class _SyncSection extends StatelessWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      sync.pendingOutboxCount.value == 0
                          ? 'syncNow'.tr
                          : 'pendingSyncCount'.trParams({
                              'count': '${sync.pendingOutboxCount.value}',
                            }),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: sync.status.value == SyncStatus.syncing
                        ? null
                        : sync.syncNow,
                    icon: sync.status.value == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      sync.status.value == SyncStatus.syncing
                          ? 'syncing'.tr
                          : 'syncNow'.tr,
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final message = sync.statusMessage.value;
              if (message == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  message,
                  style: TextStyle(
                    color: sync.status.value == SyncStatus.failure
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
