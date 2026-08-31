import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/local/app_database.dart';
import '../../../data/sync/pending_upload_service.dart';
import '../../../data/sync/sync_pull_service.dart';
import '../../../data/sync/sync_push_service.dart';
import '../../../domain/entities/auth_session.dart';
import '../../auth/controller/auth_controller.dart';

/// What the "Sync Now" affordance shows — kept as one enum rather than
/// several booleans for the same reason `AuthUiStatus` is, so a screen
/// has exactly one `switch`/comparison to get right.
enum SyncStatus { idle, syncing, success, failure }

/// Manually-triggered *and* automatic outbox push + cursor pull, wired
/// into `AccountSettingsScreen`'s "Sync Now" button as well as a
/// periodic timer and a connectivity-regained listener. Deliberately
/// push-then-pull, not concurrent: a push can create rows a subsequent
/// pull would otherwise re-fetch as "new" from this same device, which
/// is harmless but wasteful — pushing first means this device's own
/// outbox is already empty by the time the pull runs.
///
/// Requires a resolved shop membership (`AuthController.session.value
/// .hasShop`) to run at all — there is no real backend shop id to sync
/// against before onboarding completes. [syncNow] (the user-facing
/// button) reports that as a real, visible failure; the automatic
/// triggers ([_autoSync]) silently skip instead — an owner mid-onboarding
/// does not need a "sync failed" message popping up every five minutes
/// for a state that isn't a failure at all, just "not ready yet".
///
/// [connectivityChanges] and [autoSyncInterval] are constructor
/// parameters, not read from `Connectivity()`/a hardcoded literal
/// directly in this class, specifically so tests can supply a fake
/// stream and a short interval — `Connectivity()` reads a platform
/// channel that plain `test()` (no widget/plugin registration) cannot
/// satisfy, the same reason `SyncTransport`/`AuthRepository` are
/// injected rather than constructed internally elsewhere in this
/// codebase.
class SyncController extends GetxController {
  final AppDatabase db;
  final SyncPushService pushService;
  final SyncPullService pullService;
  final PendingUploadService uploadService;
  final AuthController authController;
  final Stream<List<ConnectivityResult>> connectivityChanges;
  final Duration autoSyncInterval;

  SyncController({
    required this.db,
    required this.pushService,
    required this.pullService,
    required this.uploadService,
    required this.authController,
    required this.connectivityChanges,
    this.autoSyncInterval = const Duration(minutes: 5),
  });

  final status = SyncStatus.idle.obs;
  final statusMessage = RxnString();
  final pendingOutboxCount = 0.obs;

  /// Progress state used during full / initial sync UI
  final isInitialSyncing = false.obs;
  final syncProgressMessage = 'আপনার ডেটা প্রস্তুত হচ্ছে...'.obs;
  final syncProgressFraction = 0.0.obs;

  StreamSubscription<Object?>? _outboxCountSub;
  StreamSubscription<Object?>? _uploadCountSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<AuthSession?>? _sessionSub;
  Timer? _periodicTimer;

  /// Tracks whether the last connectivity reading was "offline", so a
  /// sync only fires on the offline→online *edge*, not on every
  /// connectivity event (e.g. wifi→wifi network handoffs, which still
  /// emit a change event but were never actually offline in between).
  bool _wasOffline = false;
  int _pendingOutboxEntries = 0;
  int _pendingUploads = 0;

  @override
  void onInit() {
    super.onInit();
    _outboxCountSub = db.syncMetadataDao.watchPendingCount().listen((count) {
      _pendingOutboxEntries = count;
      _updatePendingWorkCount();
    });
    _uploadCountSub = db.syncMetadataDao.watchPendingUploadCount().listen((
      count,
    ) {
      _pendingUploads = count;
      _updatePendingWorkCount();
    });

    _periodicTimer = Timer.periodic(autoSyncInterval, (_) => _autoSync());

    _connectivitySub = connectivityChanges.listen((results) {
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      final regainedConnectivity = _wasOffline && !isOffline;
      _wasOffline = isOffline;
      if (regainedConnectivity) _autoSync();
    });

    _sessionSub = authController.session.listen((sess) {
      if (sess?.hasShop == true &&
          !isInitialSyncing.value &&
          status.value != SyncStatus.syncing) {
        _autoSync();
      }
    });
  }

  @override
  void onClose() {
    _outboxCountSub?.cancel();
    _uploadCountSub?.cancel();
    _connectivitySub?.cancel();
    _sessionSub?.cancel();
    _periodicTimer?.cancel();
    super.onClose();
  }

  void _updatePendingWorkCount() {
    pendingOutboxCount.value = _pendingOutboxEntries + _pendingUploads;
  }

  /// Performs full initial sync when a user signs in or connects to a shop.
  Future<void> performInitialSync(String shopId) async {
    isInitialSyncing.value = true;
    syncProgressFraction.value = 0.05;
    syncProgressMessage.value = 'সার্ভারের সাথে সংযোগ স্থাপন করা হচ্ছে...';
    try {
      await _performSync(
        shopId,
        onProgress: (table, index, total) {
          syncProgressFraction.value = (index / total).clamp(0.0, 1.0);
          syncProgressMessage.value = _tableFriendlyLabel(table);
        },
      );
    } catch (e) {
      AppLogger.w('SyncController', 'Initial sync caught exception: $e');
    } finally {
      isInitialSyncing.value = false;
    }
  }

  /// The user-facing "Sync Now" button — reports "no shop yet" as a
  /// real, visible failure (see the class doc comment for why the
  /// automatic path doesn't).
  Future<void> syncNow() async {
    if (status.value == SyncStatus.syncing) return;

    final shopId = authController.session.value?.shopId;
    if (shopId == null) {
      status.value = SyncStatus.failure;
      statusMessage.value = 'syncRequiresShop'.tr;
      return;
    }

    await _performSync(shopId);
  }

  /// Called by the periodic timer and the connectivity-regained
  /// listener — silently does nothing before onboarding completes or
  /// while a sync is already in flight, rather than surfacing either as
  /// a failure the user didn't ask about.
  Future<void> _autoSync() async {
    if (status.value == SyncStatus.syncing || isInitialSyncing.value) return;
    final shopId = authController.session.value?.shopId;
    if (shopId == null) return;
    await _performSync(shopId);
  }

  Future<void> _performSync(
    String shopId, {
    void Function(String table, int index, int totalTables)? onProgress,
  }) async {
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

      final uploadSummary = await uploadService.uploadPending();
      if (uploadSummary.failed > 0) {
        status.value = SyncStatus.failure;
        statusMessage.value =
            'Failed to upload ${uploadSummary.failed} photo(s).';
        return;
      }

      final uploadMetadataPush = await pushService.pushPending(
        remoteShopId: shopId,
      );
      if (uploadMetadataPush.failed > 0) {
        status.value = SyncStatus.failure;
        statusMessage.value = 'syncPushFailed'.trParams({
          'count': '${uploadMetadataPush.failed}',
        });
        return;
      }

      final pullResult = await pullService.pullAll(
        remoteShopId: shopId,
        onProgress: onProgress,
      );
      if (pullResult.isErr) {
        status.value = SyncStatus.failure;
        statusMessage.value = pullResult.failureOrNull!.message;
        return;
      }

      status.value = SyncStatus.success;
      statusMessage.value = 'syncSucceeded'.trParams({
        'pushed': '${pushSummary.succeeded + uploadMetadataPush.succeeded}',
        'pulled': '${pullResult.valueOrNull}',
      });
    } catch (e) {
      status.value = SyncStatus.failure;
      statusMessage.value = e.toString();
    }
  }

  String _tableFriendlyLabel(String table) {
    switch (table) {
      case 'categories':
      case 'units':
        return 'ক্যাটাগরি ও ইউনিট লোড হচ্ছে...';
      case 'products':
      case 'product_images':
        return 'পণ্য ও পণ্যের ছবি লোড হচ্ছে...';
      case 'customers':
      case 'customer_images':
        return 'গ্রাহক ও হিসাবের তথ্য লোড হচ্ছে...';
      case 'sales':
        return 'বিক্রয়ের হিসাব লোড হচ্ছে...';
      case 'dues':
      case 'due_payments':
        return 'বকেয়া ও পরিশোধের তথ্য লোড হচ্ছে...';
      case 'purchase_trips':
      case 'purchase_items':
      case 'purchase_other_costs':
        return 'ক্রয় ও খরচের হিসাব লোড হচ্ছে...';
      case 'investors':
      case 'investor_repayments':
      case 'legacy_settlements':
        return 'বিনিয়োগ ও আর্থিক হিসাব লোড হচ্ছে...';
      case 'rent_pricing_tiers':
      case 'rent_transactions':
        return 'ভাড়া ও সার্ভিস রেকর্ড লোড হচ্ছে...';
      case 'expenses':
        return 'দোকানের খরচের তালিকা লোড হচ্ছে...';
      case 'orders':
      case 'fixed_assets':
      case 'fixed_asset_images':
        return 'অর্ডার ও সম্পদ লোড হচ্ছে...';
      case 'quick_captures':
      case 'cash_ledger_entries':
      case 'stock_movements':
      case 'audit_log_entries':
        return 'লেজার ও অডিট হিস্ট্রি সিঙ্ক হচ্ছে...';
      default:
        return 'দোকানের ডেটা প্রস্তুত করা হচ্ছে...';
    }
  }
}
