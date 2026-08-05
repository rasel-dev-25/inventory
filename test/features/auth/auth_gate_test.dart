import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/domain/entities/auth_session.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/repositories/auth_repository.dart';
import 'package:inventory/features/auth/controller/auth_controller.dart';
import 'package:inventory/features/auth/view/auth_gate.dart';
import 'package:inventory/features/auth/view/onboarding_screen.dart';
import 'package:inventory/features/auth/view/sign_in_screen.dart';

/// A hand-written fake rather than mocktail here: [AuthRepository]'s
/// interesting behaviour for AuthGate is entirely in how
/// [sessionChanges] evolves over time, which a fake stream this test
/// controls directly is a more honest simulation of than stubbing return
/// values call-by-call.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _current;

  /// The membership resolveShopMembership should return for the next
  /// call — lets a test simulate "signed in but not onboarded yet" vs
  /// "signed in with a shop" without needing a real backend.
  AuthSession Function(AuthSession) resolveTransform = (s) => s;

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
    return Result.ok(resolveTransform(session));
  }

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> addStaffMemberByEmail({
    required String shopId,
    required String email,
  }) async {
    throw UnimplementedError();
  }

  void dispose() => _controller.close();
}

void main() {
  late _FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    Get.testMode = true;
  });

  tearDown(() {
    fakeRepo.dispose();
    Get.reset();
  });

  Widget buildHarness() {
    Get.put<AuthController>(AuthController(fakeRepo));
    return const MaterialApp(home: AuthGate());
  }

  // A "shows the loading spinner on the very first frame" case is
  // deliberately not covered here: with no session at controller
  // construction, AuthController.onInit() takes the synchronous
  // `else` branch straight to AuthUiStatus.signedOut (see
  // auth_controller.dart) — there is no Future in flight to catch mid-air
  // for that path. Exercising the loading branch would mean seeding the
  // fake with a non-null currentSession and asserting before
  // resolveShopMembership's Future resolves, which depends on
  // flutter_test's internal microtask-flushing behaviour during
  // pumpWidget rather than on anything AuthGate/AuthController control —
  // not a reliable thing to pin a test to.

  testWidgets('shows SignInScreen when there is no session', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('shows OnboardingScreen for a signed-in user with no shop yet', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    fakeRepo.emit(const AuthSession(userId: 'u1', email: 'owner@example.com'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    // The onboarding screen surfaces the signed-in email so a staff
    // member knows what to tell their owner to invite.
    expect(find.text('owner@example.com'), findsOneWidget);
  });

  testWidgets(
    'moves from onboarding to the shell once shop membership resolves',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      fakeRepo.emit(
        const AuthSession(userId: 'u1', email: 'owner@example.com'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Simulate resolveShopMembership now finding a shop_members row —
      // AuthController.refreshMembership() is what a real onboarding
      // screen wires its "check again" button to.
      fakeRepo.resolveTransform = (s) =>
          s.copyWith(shopId: 'shop-1', role: ShopMemberRole.owner);
      await Get.find<AuthController>().refreshMembership();

      // Deliberately NOT pumping again from here: AuthGate's ready
      // branch renders the real ShellScreen, which pulls in the whole
      // AppDatabase/5-controller graph (Get.find<AppDatabase>() for
      // each of its 5 embedded screens) that this auth-routing test
      // never sets up — letting that branch actually build would fail
      // the test on an unrelated missing dependency, not on anything
      // AuthGate got wrong. AuthUiStatus.ready is the exact value
      // AuthGate's switch uses to pick ShellScreen (see auth_gate.dart),
      // so asserting the controller reached it is the correct boundary
      // for what this test owns; verifying ShellScreen itself renders
      // belongs to a shell widget test, not an auth one.
      expect(Get.find<AuthController>().status.value, AuthUiStatus.ready);
    },
  );

  testWidgets('returns to SignInScreen after sign-out', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    fakeRepo.emit(const AuthSession(userId: 'u1', email: 'owner@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    fakeRepo.emit(null);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
