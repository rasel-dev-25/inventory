import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/storage_usage.dart';

/// Fetches remote storage statistics from Supabase via `get_shop_storage_usage` RPC.
class SupabaseStorageMetricsService {
  static const _tag = 'StorageMetrics';

  final sb.SupabaseClient? _client;

  SupabaseStorageMetricsService([sb.SupabaseClient? client]) : _client = client;

  sb.SupabaseClient get _effectiveClient =>
      _client ?? sb.Supabase.instance.client;

  Future<Result<({CloudStorageStats cloud, DatabaseStorageStats database})>>
      fetchRemoteMetrics() async {
    try {
      final response = await _effectiveClient.rpc('get_shop_storage_usage');
      if (response == null || response is! Map<String, dynamic>) {
        return const Result.err(
          UnknownFailure('Invalid response from get_shop_storage_usage'),
        );
      }

      final cloudJson =
          (response['cloud_storage'] as Map<String, dynamic>?) ?? const {};
      final dbJson =
          (response['database'] as Map<String, dynamic>?) ?? const {};

      return Result.ok((
        cloud: CloudStorageStats.fromJson(cloudJson),
        database: DatabaseStorageStats.fromJson(dbJson),
      ));
    } catch (e, stack) {
      AppLogger.e(
        _tag,
        'Failed to fetch storage usage: $e',
        error: e,
        stackTrace: stack,
      );
      return Result.err(UnknownFailure(e, stackTrace: stack));
    }
  }
}
