import '../../core/error/result.dart';

abstract class StorageUploadTransport {
  Future<Result<void>> upload({
    required String bucketName,
    required String storagePath,
    required String localPath,
  });

  Future<Result<void>> delete({
    required String bucketName,
    required String storagePath,
  });

  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  });
}
