import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth + the Postgres RPCs in
/// `supabase/migrations/0006_owner_onboarding_rpc.sql`. This is the only
/// file in the app allowed to import `package:supabase_flutter` for
/// auth — everything above it (controllers, screens) talks to the pure
/// Dart [AuthRepository] interface, per ARCHITECTURE.md's layering rule.
class SupabaseAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client;

  SupabaseAuthRepository([sb.SupabaseClient? client])
    : _client = client ?? sb.Supabase.instance.client;

  AuthSession _toSession(sb.User user) =>
      AuthSession(userId: user.id, email: user.email);

  @override
  Stream<AuthSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user == null ? null : _toSession(user);
      });

  @override
  AuthSession? get currentSession {
    final user = _client.auth.currentUser;
    return user == null ? null : _toSession(user);
  }

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Result.err(
          UnknownFailure(
            'sign-up did not return a user (check email confirmation settings)',
          ),
        );
      }
      return Result.ok(_toSession(user));
    } on sb.AuthException catch (e) {
      return Result.err(_mapAuthException(e));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Result.err(
          UnknownFailure('sign-in did not return a user'),
        );
      }
      return Result.ok(_toSession(user));
    } on sb.AuthException catch (e) {
      return Result.err(_mapAuthException(e));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<Result<AuthSession>> resolveShopMembership(AuthSession session) async {
    try {
      final row = await _client
          .from('shop_members')
          .select('shop_id, role')
          .eq('user_id', session.userId)
          .maybeSingle();

      if (row == null) {
        // Normal, expected state for a brand-new user who hasn't
        // onboarded yet — not a failure.
        return Result.ok(session);
      }

      final role = row['role'] == 'owner'
          ? ShopMemberRole.owner
          : ShopMemberRole.staff;
      return Result.ok(
        session.copyWith(shopId: row['shop_id'] as String, role: role),
      );
    } on sb.PostgrestException catch (e) {
      return Result.err(UnknownFailure(e.message));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  @override
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  }) async {
    final session = currentSession;
    if (session == null) {
      return const Result.err(
        UnknownFailure('createShopAndBecomeOwner called with no session'),
      );
    }
    try {
      final shopId = await _client.rpc(
        'create_shop_and_owner',
        params: {'p_shop_name': shopName},
      );
      return Result.ok(
        session.copyWith(shopId: shopId as String, role: ShopMemberRole.owner),
      );
    } on sb.PostgrestException catch (e) {
      return Result.err(BusinessRuleFailure(e.message));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> addStaffMemberByEmail({
    required String shopId,
    required String email,
  }) async {
    try {
      await _client.rpc(
        'add_staff_member_by_email',
        params: {'p_shop_id': shopId, 'p_email': email},
      );
      return const Result.ok(null);
    } on sb.PostgrestException catch (e) {
      // The RPC's own guard clauses (owner-only, must already have an
      // account) surface here as plain Postgres exceptions — see
      // add_staff_member_by_email's body. Mapped to the closest Failure
      // rather than left as UnknownFailure since the UI can act on
      // these two specifically (e.g. "ask them to sign up first").
      final message = e.message;
      if (message.contains('only the shop owner')) {
        return Result.err(PermissionFailure(message));
      }
      if (message.contains('no account found')) {
        return Result.err(NotFoundFailure('user', email));
      }
      return Result.err(BusinessRuleFailure(message));
    } catch (e, st) {
      return Result.err(UnknownFailure(e, stackTrace: st));
    }
  }

  Failure _mapAuthException(sb.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return const ValidationFailure('password', 'Incorrect email or password');
    }
    if (message.contains('email') && message.contains('confirm')) {
      return ValidationFailure('email', e.message);
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return const ValidationFailure(
        'email',
        'An account with this email already exists',
      );
    }
    return ValidationFailure('email', e.message);
  }
}
