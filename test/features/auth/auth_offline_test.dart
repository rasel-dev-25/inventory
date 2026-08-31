import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/domain/entities/auth_session.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/repositories/auth_repository.dart';
import 'package:inventory/features/auth/controller/auth_controller.dart';

class _OfflineFakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _current;
  bool returnNetworkError = false;

  void emit(AuthSession? session) {
    _current = session;
    _controller.add(session);
  }

  @override
  AuthSession? get currentSession => _current;

  @override
  Stream<AuthSession?> get sessionChanges => _controller.stream;

  @override
  Future<Result<AuthSession>> resolveShopMembership(AuthSession session) async {
    if (returnNetworkError) {
      return const Result.err(
        UnknownFailure("SocketException: Failed host lookup: 'supabase.co'"),
      );
    }
    return Result.ok(
      session.copyWith(shopId: 'shop-cached-123', role: ShopMemberRole.owner),
    );
  }

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    final s = AuthSession(userId: 'u1', email: email);
    _current = s;
    return Result.ok(s);
  }

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> addStaffMemberByEmail({
    required String email,
    required String shopId,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  late _OfflineFakeAuthRepository repo;

  setUp(() {
    repo = _OfflineFakeAuthRepository();
  });

  tearDown(() {
    Get.reset();
  });

  test('preserves ready status when network is offline and session already has shop', () async {
    // 1. First online resolution gives active shop
    final controller = AuthController(repo);
    Get.put<AuthController>(controller);

    repo.emit(const AuthSession(userId: 'u1', email: 'test@example.com'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.status.value, AuthUiStatus.ready);
    expect(controller.session.value?.shopId, 'shop-cached-123');

    // 2. Now user goes offline and stream re-emits or background refresh triggers
    repo.returnNetworkError = true;
    repo.emit(const AuthSession(userId: 'u1', email: 'test@example.com'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Controller MUST stay ready, not kick user to onboarding!
    expect(controller.status.value, AuthUiStatus.ready);
    expect(controller.session.value?.hasShop, isTrue);
  });
}
