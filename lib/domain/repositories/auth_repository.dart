import '../../core/error/result.dart';
import '../entities/auth_session.dart';

/// The boundary between the app and whatever identity/backend provider
/// sits behind it (Supabase Auth + Postgres — see
/// `lib/data/remote/supabase_auth_repository.dart`). Pure Dart, no
/// Flutter or Supabase import, so domain/use-case tests can fake this
/// without touching a network client — enforced by
/// `tool/check_layer_boundaries.sh` like every other domain file.
abstract class AuthRepository {
  /// Emits the current session (or null when signed out) immediately on
  /// listen, then again on every sign-in/sign-out/token-refresh. Does
  /// NOT re-emit just because shop membership changed elsewhere — call
  /// [resolveShopMembership] after a session-changed event to pick that
  /// up, since membership is a separate round trip.
  Stream<AuthSession?> get sessionChanges;

  AuthSession? get currentSession;

  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Looks up the caller's shop_members row (if any) and returns the
  /// session with [AuthSession.shopId]/[AuthSession.role] filled in.
  /// Returns the session unchanged (shopId/role still null) if the user
  /// has signed up but not yet completed onboarding or been added as
  /// staff by an owner — that is a normal, expected state, not a
  /// failure.
  Future<Result<AuthSession>> resolveShopMembership(AuthSession session);

  /// Atomically creates a new shop and makes the current user its
  /// owner — see the `create_shop_and_owner` Postgres function
  /// (supabase/migrations/0006_owner_onboarding_rpc.sql) for why this is
  /// one RPC call and not two client-issued INSERTs: the race/partial-
  /// failure gap flagged in migration 0002's "known limitation" note.
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  });

  /// Owner-only: adds an already-registered user (identified by the
  /// email they signed up with) as staff (view-only) on the owner's
  /// shop. Comes back as a [Result.err] wrapping a
  /// [PermissionFailure]-shaped message if the caller isn't that shop's
  /// owner, or a not-found-shaped message if no account exists yet for
  /// that email — the staff person must sign up first, onboarding
  /// screens don't create accounts on someone else's behalf.
  Future<Result<void>> addStaffMemberByEmail({
    required String shopId,
    required String email,
  });
}
