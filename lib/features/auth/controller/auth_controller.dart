import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/repositories/auth_repository.dart';

/// What the app should currently show, derived from the session stream —
/// kept as a single enum (rather than several booleans a screen has to
/// combine correctly itself) so `AuthGate` has exactly one `switch` to
/// get right.
enum AuthUiStatus {
  /// Resolving the initial session on app start, or between a
  /// sign-in/out action and its result.
  loading,

  /// No signed-in user.
  signedOut,

  /// Signed in, but no shop membership yet — needs to create a shop
  /// (owner) or wait to be invited (staff who signed up first).
  needsOnboarding,

  /// Signed in with a resolved shop + role — the shell can render.
  ready,
}

/// Wraps [AuthRepository] with the reactive state the UI needs: GetX
/// controllers are this app's existing pattern (see
/// `SettingsController`), so auth follows the same shape rather than
/// introducing a second state-management approach for one feature.
class AuthController extends GetxController {
  static const _tag = 'AuthController';
  final AuthRepository _repo;

  AuthController(this._repo);

  final status = AuthUiStatus.loading.obs;
  final session = Rxn<AuthSession>();
  final errorMessage = RxnString();
  final isSubmitting = false.obs;
  /// Flips to true after a successful sign-up so the screen can show
  /// a confirmation banner before navigating away.
  final signUpSuccess = false.obs;

  StreamSubscription<AuthSession?>? _sub;

  /// The userId we are currently resolving, used to deduplicate the
  /// direct call from signIn() vs. the stream event that fires right
  /// after — without this guard both would call resolveShopMembership
  /// in parallel and the second one would clobber the first.
  String? _resolvingUserId;

  @override
  void onInit() {
    super.onInit();
    AppLogger.d(_tag, 'onInit — checking for existing session');
    // Resolve whatever session already exists (e.g. a still-valid token
    // from a previous app launch) before the stream's first event, so
    // the UI doesn't flash the sign-in screen on every cold start.
    final initial = _repo.currentSession;
    if (initial != null) {
      AppLogger.i(_tag, 'existing session found userId=${initial.userId}');
      _handleSessionChange(initial);
    } else {
      AppLogger.d(_tag, 'no existing session → signedOut');
      status.value = AuthUiStatus.signedOut;
    }
    _sub = _repo.sessionChanges.listen((s) {
      AppLogger.d(_tag, 'sessionChanges stream event userId=${s?.userId}');
      _handleSessionChange(s);
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _handleSessionChange(AuthSession? newSession) async {
    if (newSession == null) {
      _resolvingUserId = null;
      session.value = null;
      status.value = AuthUiStatus.signedOut;
      return;
    }
    // Skip duplicate resolution for the same user (e.g. stream fires
    // immediately after signIn() already started resolving).
    if (_resolvingUserId == newSession.userId &&
        status.value == AuthUiStatus.loading) {
      return;
    }
    _resolvingUserId = newSession.userId;
    status.value = AuthUiStatus.loading;
    AppLogger.d(_tag, 'resolveShopMembership userId=${newSession.userId}');

    try {
      // Timeout so a slow/failed network call never strands the user on
      // an infinite spinner — fall through to onboarding after 15 s.
      final result = await _repo
          .resolveShopMembership(newSession)
          .timeout(const Duration(seconds: 15));

      result.fold(
        onOk: (resolved) {
          AppLogger.i(_tag, 'session resolved  shopId=${resolved.shopId}  role=${resolved.role}  hasShop=${resolved.hasShop}');
          session.value = resolved;
          status.value = resolved.hasShop
              ? AuthUiStatus.ready
              : AuthUiStatus.needsOnboarding;
          // Sign-in left isSubmitting=true so the button stayed disabled
          // while we resolved. Clear it now that we have a final status.
          isSubmitting.value = false;
        },
        onErr: (failure) {
          // Membership lookup failing (network blip, etc.) shouldn't strand
          // the user on an infinite spinner — fall back to onboarding.
          AppLogger.w(_tag, 'resolveShopMembership error: ${failure.message}');
          session.value = newSession;
          status.value = AuthUiStatus.needsOnboarding;
          isSubmitting.value = false;
          errorMessage.value = failure.message;
        },
      );
    } on TimeoutException {
      // Network too slow — land on onboarding so the user can tap
      // "Check again" once connectivity recovers.
      AppLogger.w(_tag, 'resolveShopMembership timed out after 15 s');
      session.value = newSession;
      status.value = AuthUiStatus.needsOnboarding;
      isSubmitting.value = false;
      errorMessage.value = 'Connection is slow — tap "Check again" when ready.';
    } catch (e, st) {
      AppLogger.e(_tag, 'resolveShopMembership threw unexpectedly', error: e, stackTrace: st);
      session.value = newSession;
      status.value = AuthUiStatus.needsOnboarding;
      isSubmitting.value = false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    AppLogger.d(_tag, 'signIn email=$email');
    isSubmitting.value = true;
    errorMessage.value = null;
    final result = await _repo.signIn(email: email, password: password);
    return result.fold(
      onOk: (returnedSession) {
        AppLogger.i(_tag, 'signIn OK  userId=${returnedSession.userId}');
        // Immediately kick off membership resolution using the session
        // we already have from the API response — don't wait for the
        // onAuthStateChange stream event, which can be delayed by
        // several seconds on mobile/emulator. The dedup guard in
        // _handleSessionChange prevents double-resolution when the
        // stream also fires shortly after.
        _handleSessionChange(returnedSession);
        // Keep isSubmitting = true; AuthGate replaces this widget when
        // status moves to loading/ready/needsOnboarding.
        return true;
      },
      onErr: (failure) {
        AppLogger.w(_tag, 'signIn FAILED: ${failure.message}');
        isSubmitting.value = false;
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> signUp({required String email, required String password}) async {
    AppLogger.d(_tag, 'signUp email=$email');
    isSubmitting.value = true;
    signUpSuccess.value = false;
    errorMessage.value = null;
    final result = await _repo.signUp(email: email, password: password);
    isSubmitting.value = false;
    return result.fold(
      onOk: (_) {
        AppLogger.i(_tag, 'signUp OK');
        signUpSuccess.value = true;
        return true;
      },
      onErr: (failure) {
        AppLogger.w(_tag, 'signUp FAILED: ${failure.message}');
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> createShop(String shopName) async {
    isSubmitting.value = true;
    errorMessage.value = null;
    final result = await _repo.createShopAndBecomeOwner(shopName: shopName);
    isSubmitting.value = false;
    return result.fold(
      onOk: (resolved) {
        session.value = resolved;
        status.value = AuthUiStatus.ready;
        return true;
      },
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> inviteStaff(String email) async {
    final shopId = session.value?.shopId;
    if (shopId == null) return false;
    isSubmitting.value = true;
    errorMessage.value = null;
    final result = await _repo.addStaffMemberByEmail(
      shopId: shopId,
      email: email,
    );
    isSubmitting.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  /// Re-checks shop membership without waiting for another auth event —
  /// needed because [AuthRepository.sessionChanges] only fires on
  /// sign-in/out/token-refresh, not when an owner adds this user as
  /// staff elsewhere. A staff member who just signed up has no other way
  /// to discover the invite short of restarting the app, so the
  /// onboarding screen exposes this as an explicit "check again" action.
  Future<void> refreshMembership() async {
    final current = session.value;
    if (current == null) return;
    await _handleSessionChange(current);
  }

  Future<void> signOut() async {
    AppLogger.i(_tag, 'signOut');
    _resolvingUserId = null;
    session.value = null;
    status.value = AuthUiStatus.signedOut;
    isSubmitting.value = false;
    signUpSuccess.value = false;
    errorMessage.value = null;

    // Pop all pushed routes (e.g., AccountSettingsScreen) back to root AuthGate.
    if (Get.key.currentState?.canPop() ?? false) {
      Get.until((route) => route.isFirst);
    }

    try {
      await _repo.signOut();
      AppLogger.d(_tag, 'signOut remote OK');
    } catch (e) {
      // Even if remote sign out throws (e.g. offline), local state is cleared.
      AppLogger.w(_tag, 'signOut remote threw (ignored)', error: e);
    }
  }
}
