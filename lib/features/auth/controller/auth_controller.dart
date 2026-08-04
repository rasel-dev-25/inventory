import 'dart:async';

import 'package:get/get.dart';

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
  final AuthRepository _repo;

  AuthController(this._repo);

  final status = AuthUiStatus.loading.obs;
  final session = Rxn<AuthSession>();
  final errorMessage = RxnString();
  final isSubmitting = false.obs;

  StreamSubscription<AuthSession?>? _sub;

  @override
  void onInit() {
    super.onInit();
    // Resolve whatever session already exists (e.g. a still-valid token
    // from a previous app launch) before the stream's first event, so
    // the UI doesn't flash the sign-in screen on every cold start.
    final initial = _repo.currentSession;
    if (initial != null) {
      _handleSessionChange(initial);
    } else {
      status.value = AuthUiStatus.signedOut;
    }
    _sub = _repo.sessionChanges.listen(_handleSessionChange);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _handleSessionChange(AuthSession? newSession) async {
    if (newSession == null) {
      session.value = null;
      status.value = AuthUiStatus.signedOut;
      return;
    }
    status.value = AuthUiStatus.loading;
    final result = await _repo.resolveShopMembership(newSession);
    result.fold(
      onOk: (resolved) {
        session.value = resolved;
        status.value = resolved.hasShop
            ? AuthUiStatus.ready
            : AuthUiStatus.needsOnboarding;
      },
      onErr: (failure) {
        // Membership lookup failing (network blip, etc.) shouldn't strand
        // the user on an infinite spinner — fall back to the
        // authenticated-but-unresolved state and let them retry via the
        // onboarding screen's own affordances.
        session.value = newSession;
        status.value = AuthUiStatus.needsOnboarding;
        errorMessage.value = failure.message;
      },
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    isSubmitting.value = true;
    errorMessage.value = null;
    final result = await _repo.signIn(email: email, password: password);
    isSubmitting.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  Future<bool> signUp({required String email, required String password}) async {
    isSubmitting.value = true;
    errorMessage.value = null;
    final result = await _repo.signUp(email: email, password: password);
    isSubmitting.value = false;
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
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

  Future<void> signOut() => _repo.signOut();
}
