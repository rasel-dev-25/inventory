import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../sync/storage_upload_transport.dart';

class SupabaseStorageUploadTransport implements StorageUploadTransport {
  final sb.SupabaseClient _client;

  SupabaseStorageUploadTransport([sb.SupabaseClient? client])
    : _client = client ?? sb.Supabase.instance.client;

  @override
  Future<Result<void>> upload({
    required String bucketName,
    required String storagePath,
    required String localPath,
  }) async {
    try {
      await _client.storage
          .from(bucketName)
          .upload(
            storagePath,
            File(localPath),
            fileOptions: const sb.FileOptions(upsert: true),
          );
      return const Result.ok(null);
    } on sb.StorageException catch (error) {
      if (error.statusCode == '401' || error.statusCode == '403') {
        return Result.err(PermissionFailure(error.message));
      }
      return Result.err(UnknownFailure(error.message));
    } catch (error, stackTrace) {
      return Result.err(UnknownFailure(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    try {
      final url = await _client.storage
          .from(bucketName)
          .createSignedUrl(storagePath, expiresIn.inSeconds);
      return Result.ok(url);
    } on sb.StorageException catch (error) {
      if (error.statusCode == '401' || error.statusCode == '403') {
        return Result.err(PermissionFailure(error.message));
      }
      return Result.err(UnknownFailure(error.message));
    } catch (error, stackTrace) {
      return Result.err(UnknownFailure(error, stackTrace: stackTrace));
    }
  }
}
