import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/data/local/local_storage_metrics_service.dart';
import 'package:inventory/data/remote/supabase_storage_metrics_service.dart';
import 'package:inventory/domain/entities/auth_session.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/storage_usage.dart';
import 'package:inventory/domain/repositories/auth_repository.dart';
import 'package:inventory/features/auth/controller/auth_controller.dart';
import 'package:inventory/features/storage_usage/controller/storage_usage_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _current;

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
    return Result.ok(session);
  }

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<AuthSession>> createShopAndBecomeOwner({
    required String shopName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> addStaffMemberByEmail({
    required String shopId,
    required String email,
  }) async => throw UnimplementedError();
}

class _FakeRemoteMetricsService extends SupabaseStorageMetricsService {
  Result<({CloudStorageStats cloud, DatabaseStorageStats database})> nextResult =
      const Result.ok((
    cloud: CloudStorageStats(
      totalBytes: 52428800, // 50 MB
      quotaBytes: 1073741824, // 1 GB
      productImages: BucketStorageStats(bytes: 31457280, count: 15),
      customerImages: BucketStorageStats(bytes: 10485760, count: 5),
      fixedAssetImages: BucketStorageStats(bytes: 10485760, count: 3),
    ),
    database: DatabaseStorageStats(
      totalRecords: 250,
      productsCount: 50,
      customersCount: 30,
      salesCount: 100,
      duesCount: 20,
      ordersCount: 10,
      expensesCount: 20,
      purchasesCount: 20,
    ),
  ));

  @override
  Future<Result<({CloudStorageStats cloud, DatabaseStorageStats database})>>
      fetchRemoteMetrics() async {
    return nextResult;
  }
}

class _FakeLocalMetricsService implements LocalStorageMetricsService {
  LocalDeviceStorageStats nextResult = const LocalDeviceStorageStats(
    databaseSizeBytes: 2097152, // 2 MB
    imageCacheSizeBytes: 4194304, // 4 MB
    pendingOutboxCount: 2,
  );

  @override
  Future<LocalDeviceStorageStats> fetchLocalMetrics() async {
    return nextResult;
  }
}

void main() {
  late _FakeAuthRepository authRepo;
  late AuthController authController;
  late _FakeRemoteMetricsService remoteService;
  late _FakeLocalMetricsService localService;
  late StorageUsageController controller;

  setUp(() {
    authRepo = _FakeAuthRepository();
    authController = AuthController(authRepo);
    authController.onInit();
    remoteService = _FakeRemoteMetricsService();
    localService = _FakeLocalMetricsService();

    controller = StorageUsageController(
      remoteService: remoteService,
      localService: localService,
      authController: authController,
    );
  });

  test('populates metrics and calculates formatted strings when user has shop',
      () async {
    authRepo.emit(
      const AuthSession(
        userId: 'u1',
        email: 'test@shop.com',
        shopId: 'shop-1',
        role: ShopMemberRole.owner,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await controller.fetchUsage(showLoading: false);

    expect(controller.storageUsage.value, isNotNull);
    final usage = controller.storageUsage.value!;

    expect(usage.cloud.totalBytes, 52428800);
    expect(usage.cloud.productImages.count, 15);
    expect(usage.database.totalRecords, 250);
    expect(usage.local.databaseSizeBytes, 2097152);
    expect(usage.local.pendingOutboxCount, 2);

    expect(controller.usedPercentage, closeTo(4.88, 0.05));
    expect(controller.formattedCloudUsed, '50.0 MB');
    expect(controller.formattedCloudQuota, '1.0 GB');
    expect(controller.formattedCloudRemaining, '974.0 MB');
  });

  test('handles remote failure gracefully without crashing', () async {
    authRepo.emit(
      const AuthSession(
        userId: 'u1',
        email: 'test@shop.com',
        shopId: 'shop-1',
        role: ShopMemberRole.owner,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    remoteService.nextResult =
        const Result.err(NetworkFailure('Network offline'));

    await controller.fetchUsage(showLoading: false);

    expect(controller.storageUsage.value, isNotNull);
    expect(controller.storageUsage.value!.local.totalLocalBytes, 6291456);
  });
}
