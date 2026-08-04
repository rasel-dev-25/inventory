import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/sync/sync_pull_service.dart';
import '../../../data/sync/sync_push_service.dart';
import '../../auth/controller/auth_controller.dart';

/// What the "Sync Now" affordance shows — kept as one enum rather than
/// several booleans for the same reason `AuthUiStatus` is, so a screen
/// has exactly one `switch`/comparison to get right.
enum SyncStatus { idle, syncing, success, failure }

/// Manually-triggered outbox push + cursor pull, wired into
/// `AccountSettingsScreen`'s "Sync Now" button. Deliberately push-then-
/// pull, not concurrent: a push can create rows a subsequent pull would
/// otherwise re-fetch as "new" from this same device, which is harmless
/// but wasteful — pushing first means this device's own outbox is
/// already empty by the time the pull runs.
///
/// Requires a resolved shop membership (`AuthController.session.value
/// .hasShop`) to run at all — there is no real backend shop id to sync
/// against before onboarding completes, so `syncNow()` is a deliberate
/// no-op (not a silent success) until then.
class SyncController extends GetxController {
  final AppDatabaseV2 db;
  final SyncPushService pushService;
  final SyncPullService pullService;
  final AuthController authController;

  SyncController({
    required this.db,
    required this.pushService,
    required this.pullService,
    required this.authController,
  });

  final status = SyncStatus.idle.obs;
  final statusMessage = RxnString();
  final pendingOutboxCount = 0.obs;

  StreamSubscription<Object?>? _outboxCountSub;

  @override
  void onInit() {
    super.onInit();
    _outboxCountSub = db.syncMetadataDao.watchPendingCount().listen((count) {
      pendingOutboxCount.value = count;
    });
  }

  @override
  void onClose() {
    _outboxCountSub?.cancel();
    super.onClose();
  }

  Future<void> syncNow() async {
    final shopId = authController.session.value?.shopId;
    if (shopId == null) {
      status.value = SyncStatus.failure;
      statusMessage.value = 'syncRequiresShop'.tr;
      return;
    }

    status.value = SyncStatus.syncing;
    statusMessage.value = null;
    try {
      final pushSummary = await pushService.pushPending(remoteShopId: shopId);
      if (pushSummary.failed > 0) {
        status.value = SyncStatus.failure;
        statusMessage.value = 'syncPushFailed'.trParams({
          'count': '${pushSummary.failed}',
        });
        return;
      }

      final pullResult = await pullService.pullAll(remoteShopId: shopId);
      if (pullResult.isErr) {
        status.value = SyncStatus.failure;
        statusMessage.value = pullResult.failureOrNull!.message;
        return;
      }

      status.value = SyncStatus.success;
      statusMessage.value = 'syncSucceeded'.trParams({
        'pushed': '${pushSummary.succeeded}',
        'pulled': '${pullResult.valueOrNull}',
      });
    } catch (e) {
      status.value = SyncStatus.failure;
      statusMessage.value = e.toString();
    }
  }
}
