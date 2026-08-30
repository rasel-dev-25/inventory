import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/local/local_row_upserter.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/sync/pending_upload_service.dart';
import 'package:inventory/data/sync/sync_pull_service.dart';
import 'package:inventory/data/sync/sync_push_service.dart';
import 'package:inventory/data/sync/sync_transport.dart';
import 'package:inventory/data/sync/storage_upload_transport.dart';
import 'package:inventory/data/usecases/category_usecases.dart';
import 'package:inventory/domain/entities/auth_session.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/repositories/auth_repository.dart';
import 'package:inventory/features/auth/controller/auth_controller.dart';
import 'package:inventory/features/sync/controller/sync_controller.dart';
import 'package:test/test.dart';

/// Minimal fake — only what SyncController's tests actually exercise
/// (session state), same reasoning as `_FakeAuthRepository` in
/// `auth_gate_test.dart`.
class _FakeAuthRepository implements AuthRepository {
  AuthSession? _current;

  @override
  AuthSession? get currentSession => _current;

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  void seed(AuthSession session) => _current = session;

  @override
  Future<Result<AuthSession>> resolveShopMembership(
    AuthSession session,
  ) async => Result.ok(session);

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> addStaffMemberByEmail({
    required String shopId,
    required String email,
  }) => throw UnimplementedError();
}

class _FakeSyncTransport implements SyncTransport {
  final List<String> pushedIdempotencyKeys = [];
  Result<void> nextPushResult = const Result.ok(null);
  final Map<String, List<RemotePage>> pagesByTable = {};

  @override
  Future<Result<void>> pushEvent({
    required String idempotencyKey,
    required List<TableUpsert> upserts,
  }) async {
    pushedIdempotencyKeys.add(idempotencyKey);
    return nextPushResult;
  }

  @override
  Future<Result<RemotePage>> fetchSince({
    required String table,
    required String shopId,
    required DateTime? afterSyncedAt,
    required String? afterId,
    int limit = 200,
  }) async {
    final queue = pagesByTable[table];
    if (queue == null || queue.isEmpty)
      return const Result.ok(RemotePage(rows: []));
    return Result.ok(queue.removeAt(0));
  }
}

class _FakeStorageUploadTransport implements StorageUploadTransport {
  @override
  Future<Result<void>> upload({
    required String bucketName,
    required String storagePath,
    required String localPath,
  }) async => const Result.ok(null);

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  }) async => Result.ok('https://example.test/$storagePath');
}

void main() {
  late AppDatabase db;
  late _FakeAuthRepository authRepo;
  late AuthController authController;
  late _FakeSyncTransport transport;
  late SyncController syncController;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    Get.testMode = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authRepo = _FakeAuthRepository();
    transport = _FakeSyncTransport();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();
  });

  tearDown(() async {
    syncController.onClose();
    authController.onClose();
    await connectivityController.close();
    await db.close();
    Get.reset();
  });

  // AuthController.onInit() kicks off an *unawaited* async chain
  // (_handleSessionChange -> resolveShopMembership) to resolve
  // session.value — fine in the real app (a GetX-driven UI just rebuilds
  // once it settles), but a real race in a test that reads
  // session.value immediately after constructing the controller. Since
  // this test constructs AuthController directly rather than via
  // Get.put (no widget tree, no GetX lifecycle to drive it
  // automatically), bootstrapAuth must explicitly wait for that chain to
  // finish rather than assume Get.put's usual timing.
  //
  // autoSyncInterval defaults to a full day specifically so the periodic
  // timer never fires during a test that isn't testing the timer itself
  // — tests that do want it fast pass a short override.
  Future<void> bootstrapAuth(
    AuthSession? session, {
    Duration autoSyncInterval = const Duration(days: 1),
  }) async {
    if (session != null) authRepo.seed(session);
    authController = AuthController(authRepo);
    authController.onInit();
    // Flushes the pending _handleSessionChange -> resolveShopMembership
    // microtask chain — _FakeAuthRepository.resolveShopMembership is
    // `async` with no internal `await`, so it completes after exactly
    // one event-loop turn, which Duration.zero is enough to flush.
    await Future<void>.delayed(Duration.zero);
    syncController = SyncController(
      db: db,
      pushService: SyncPushService(db.syncMetadataDao, transport),
      pullService: SyncPullService(
        db.syncMetadataDao,
        transport,
        LocalRowUpserter(db),
      ),
      uploadService: PendingUploadService(
        db,
        db.syncMetadataDao,
        _FakeStorageUploadTransport(),
      ),
      authController: authController,
      connectivityChanges: connectivityController.stream,
      autoSyncInterval: autoSyncInterval,
    );
    // Same reasoning as authController.onInit() above: constructed
    // directly, not via Get.put, so nothing else calls this — without
    // it the periodic timer and connectivity listener this test suite
    // exercises below are never actually started.
    syncController.onInit();
  }

  test('syncNow is a no-op failure when the session has no shop yet', () async {
    await bootstrapAuth(
      const AuthSession(userId: 'u1', email: 'owner@example.com'),
    );

    await syncController.syncNow();

    expect(syncController.status.value, SyncStatus.failure);
    expect(transport.pushedIdempotencyKeys, isEmpty);
  });

  test(
    'syncNow pushes pending outbox entries then pulls, reporting success',
    () async {
      await bootstrapAuth(
        const AuthSession(
          userId: 'u1',
          email: 'owner@example.com',
          shopId: 'real-shop-1',
          role: ShopMemberRole.owner,
        ),
      );

      final categoryUseCases = CategoryUseCases(db);
      await categoryUseCases.create(
        id: 'cat-1',
        shopId: defaultShopId,
        name: 'Books',
        sortOrder: 0,
      );

      await syncController.syncNow();

      expect(syncController.status.value, SyncStatus.success);
      expect(transport.pushedIdempotencyKeys, hasLength(1));
      // Not asserting the exact translated string here — .trParams'
      // fallback formatting with no Translations registered (a plain
      // `test()`, not a GetMaterialApp) isn't this test's concern; the
      // status enum plus the real push/pull counts above are.
      expect(syncController.statusMessage.value, isNotNull);

      // The outbox is empty after a successful push.
      final pending = await db.syncMetadataDao.pendingEntries();
      expect(pending, isEmpty);
    },
  );

  test(
    'a failed push is reported and the outbox entry is kept for retry',
    () async {
      await bootstrapAuth(
        const AuthSession(
          userId: 'u1',
          email: 'owner@example.com',
          shopId: 'real-shop-1',
          role: ShopMemberRole.owner,
        ),
      );
      transport.nextPushResult = const Result.err(UnknownFailure('offline'));

      final categoryUseCases = CategoryUseCases(db);
      await categoryUseCases.create(
        id: 'cat-2',
        shopId: defaultShopId,
        name: 'Attar',
        sortOrder: 0,
      );

      await syncController.syncNow();

      expect(syncController.status.value, SyncStatus.failure);
      final pending = await db.syncMetadataDao.pendingEntries();
      expect(
        pending,
        hasLength(1),
        reason: 'a failed push must not drop the outbox entry',
      );
    },
  );

  test('pullAll applies remote rows after a clean push', () async {
    await bootstrapAuth(
      const AuthSession(
        userId: 'u1',
        email: 'owner@example.com',
        shopId: 'real-shop-1',
        role: ShopMemberRole.owner,
      ),
    );
    transport.pagesByTable['categories'] = [
      const RemotePage(
        rows: [
          {
            'id': 'cat-remote-1',
            'shop_id': 'real-shop-1',
            'name': 'Remote Category',
            'sort_order': 0,
            'synced_at': '2026-01-01T00:00:00.000Z',
          },
        ],
      ),
    ];

    await syncController.syncNow();

    expect(
      syncController.status.value,
      SyncStatus.success,
      reason: syncController.statusMessage.value,
    );
    final row = await (db.select(
      db.categories,
    )..where((c) => c.id.equals('cat-remote-1'))).getSingleOrNull();
    expect(row, isNotNull);
    expect(row!.shopId, defaultShopId);
  });

  test('pendingOutboxCount reflects the live outbox size', () async {
    await bootstrapAuth(null);
    final categoryUseCases = CategoryUseCases(db);
    expect(await db.syncMetadataDao.watchPendingCount().first, 0);

    await categoryUseCases.create(
      id: 'cat-3',
      shopId: defaultShopId,
      name: 'Topi',
      sortOrder: 0,
    );

    // watchPendingCount is a live Stream; give it one microtask turn to
    // deliver the post-write count rather than asserting the DAO
    // directly a second time.
    final count = await db.syncMetadataDao.watchPendingCount().first;
    expect(count, 1);
  });

  group('automatic sync (periodic timer)', () {
    test(
      'a pending outbox entry is pushed automatically once the timer fires',
      () async {
        await bootstrapAuth(
          const AuthSession(
            userId: 'u1',
            email: 'owner@example.com',
            shopId: 'real-shop-1',
            role: ShopMemberRole.owner,
          ),
          autoSyncInterval: const Duration(milliseconds: 20),
        );

        final categoryUseCases = CategoryUseCases(db);
        await categoryUseCases.create(
          id: 'cat-auto-1',
          shopId: defaultShopId,
          name: 'Books',
          sortOrder: 0,
        );
        expect(
          transport.pushedIdempotencyKeys,
          isEmpty,
          reason: 'no sync has run yet',
        );

        // The timer is real (Timer.periodic), so this really does wait —
        // deliberately short (autoSyncInterval above) rather than mocked,
        // so this test exercises the actual Timer, not a stand-in for it.
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(transport.pushedIdempotencyKeys, isNotEmpty);
        expect(await db.syncMetadataDao.pendingEntries(), isEmpty);
      },
    );

    test(
      'the timer silently does nothing before onboarding completes',
      () async {
        await bootstrapAuth(
          const AuthSession(userId: 'u1', email: 'owner@example.com'),
          autoSyncInterval: const Duration(milliseconds: 20),
        );

        await Future<void>.delayed(const Duration(milliseconds: 60));

        // Unlike syncNow() (the button), the automatic path must not turn
        // "not onboarded yet" into a visible failure state — see the class
        // doc comment.
        expect(syncController.status.value, SyncStatus.idle);
        expect(syncController.statusMessage.value, isNull);
        expect(transport.pushedIdempotencyKeys, isEmpty);
      },
    );
  });

  group('automatic sync (connectivity regained)', () {
    test('going from offline to online triggers an automatic sync', () async {
      await bootstrapAuth(
        const AuthSession(
          userId: 'u1',
          email: 'owner@example.com',
          shopId: 'real-shop-1',
          role: ShopMemberRole.owner,
        ),
      );
      final categoryUseCases = CategoryUseCases(db);
      await categoryUseCases.create(
        id: 'cat-auto-2',
        shopId: defaultShopId,
        name: 'Attar',
        sortOrder: 0,
      );

      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(
        transport.pushedIdempotencyKeys,
        isEmpty,
        reason: 'still offline, must not sync yet',
      );

      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(transport.pushedIdempotencyKeys, isNotEmpty);
    });

    test(
      'a network handoff that never actually went offline does not trigger a sync',
      () async {
        await bootstrapAuth(
          const AuthSession(
            userId: 'u1',
            email: 'owner@example.com',
            shopId: 'real-shop-1',
            role: ShopMemberRole.owner,
          ),
        );
        final categoryUseCases = CategoryUseCases(db);
        await categoryUseCases.create(
          id: 'cat-auto-3',
          shopId: defaultShopId,
          name: 'Topi',
          sortOrder: 0,
        );

        // wifi -> ethernet: a real connectivity *event* connectivity_plus
        // would emit (e.g. plugging in a cable while on wifi), but never
        // an offline/none reading in between.
        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);
        connectivityController.add([ConnectivityResult.ethernet]);
        await Future<void>.delayed(Duration.zero);

        expect(transport.pushedIdempotencyKeys, isEmpty);
      },
    );
  });
}
