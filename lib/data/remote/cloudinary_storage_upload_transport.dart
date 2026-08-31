import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:crypto/crypto.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/storage/cloudinary_config.dart';
import '../../core/utils/app_logger.dart';
import '../sync/storage_upload_transport.dart';

/// Cloudinary-backed implementation of [StorageUploadTransport].
///
/// Uses Cloudinary REST API with an unsigned upload preset to securely upload
/// media files into structured folder hierarchies (`inventory_app/<shopId>/<entityType>/`).
class CloudinaryStorageUploadTransport implements StorageUploadTransport {
  final CloudinaryConfig config;
  final http.Client _httpClient;

  CloudinaryStorageUploadTransport({
    this.config = const CloudinaryConfig(),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Endpoint URL for uploading images to Cloudinary.
  Uri get _uploadUri => Uri.parse(
        'https://api.cloudinary.com/v1_1/${config.cloudName}/image/upload',
      );

  @override
  Future<Result<void>> upload({
    required String bucketName,
    required String storagePath,
    required String localPath,
  }) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        return Result.err(
          UnknownFailure('Local file not found at path: $localPath'),
        );
      }

      final request = http.MultipartRequest('POST', _uploadUri);
      request.fields['upload_preset'] = config.uploadPreset;

      // Extract folder and public_id from storagePath or bucketName
      // Example storagePath: "shop_1/products/prod_123_456.jpg" or "prod_123/img_456.jpg"
      final folder = _extractFolder(bucketName, storagePath);
      final filenameWithoutExt = path.basenameWithoutExtension(storagePath);

      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      if (filenameWithoutExt.isNotEmpty) {
        request.fields['public_id'] = filenameWithoutExt;
      }

      final multipartFile = await http.MultipartFile.fromPath('file', localPath);
      request.files.add(multipartFile);

      AppLogger.i(
        'Cloudinary',
        'Upload started: $localPath -> $folder/$filenameWithoutExt',
      );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final secureUrl = json['secure_url'] as String?;
        final publicId = json['public_id'] as String?;

        AppLogger.i(
          'Cloudinary',
          'Upload successful! publicId: $publicId, url: $secureUrl',
        );
        return const Result.ok(null);
      } else {
        AppLogger.e(
          'Cloudinary',
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
        return Result.err(
          UnknownFailure(
            'Cloudinary upload failed (${response.statusCode}): ${response.body}',
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.e('Cloudinary', 'Upload error: $error', error: error, stackTrace: stackTrace);
      return Result.err(UnknownFailure(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void>> delete({
    required String bucketName,
    required String storagePath,
  }) async {
    try {
      final publicId = _extractFullPublicId(bucketName, storagePath);
      AppLogger.i('Cloudinary', 'Deleting media: $publicId from $bucketName');

      final destroyUri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${config.cloudName}/image/destroy',
      );

      // 1. If API Key and Secret are configured, use signed destroy endpoint
      if (config.apiKey.isNotEmpty && config.apiSecret.isNotEmpty) {
        final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
        final toSign = 'public_id=$publicId&timestamp=$timestamp${config.apiSecret}';
        final signature = sha1.convert(utf8.encode(toSign)).toString();

        final response = await _httpClient.post(
          destroyUri,
          body: {
            'public_id': publicId,
            'api_key': config.apiKey,
            'timestamp': timestamp,
            'signature': signature,
          },
        );

        AppLogger.i(
          'Cloudinary',
          'Signed destroy response: ${response.statusCode} - ${response.body}',
        );
      } else {
        // 2. Direct destroy endpoint
        final response = await _httpClient.post(
          destroyUri,
          body: {
            'public_id': publicId,
            'upload_preset': config.uploadPreset,
          },
        );
        AppLogger.i(
          'Cloudinary',
          'Destroy response: ${response.statusCode} - ${response.body}',
        );
      }
      return const Result.ok(null);
    } catch (error, stackTrace) {
      AppLogger.e('Cloudinary', 'Delete error: $error', error: error, stackTrace: stackTrace);
      return Result.err(UnknownFailure(error, stackTrace: stackTrace));
    }
  }

  String _extractFullPublicId(String bucketName, String storagePath) {
    if (storagePath.startsWith(config.folderPrefix)) {
      final ext = path.extension(storagePath);
      if (ext.isNotEmpty) {
        return storagePath.substring(0, storagePath.length - ext.length);
      }
      return storagePath;
    }
    final folder = _extractFolder(bucketName, storagePath);
    final filename = path.basenameWithoutExtension(storagePath);
    return '$folder/$filename'.replaceAll(r'\', '/');
  }

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    try {
      // 1. If it's already a full CDN URL, return it directly
      if (storagePath.startsWith('http://') ||
          storagePath.startsWith('https://')) {
        return Result.ok(storagePath);
      }

      // 2. If it's a relative path or public_id, resolve full public_id
      String publicId = storagePath;
      if (!publicId.startsWith(config.folderPrefix)) {
        final folder = _extractFolder(bucketName, storagePath);
        final filename = path.basenameWithoutExtension(storagePath);
        publicId = '$folder/$filename';
      }

      final url = CloudinaryConfig.transformUrl(
        publicId,
        transformation: 'q_auto,f_auto',
        cloudName: config.cloudName,
      );
      return Result.ok(url);
    } catch (error, stackTrace) {
      return Result.err(UnknownFailure(error, stackTrace: stackTrace));
    }
  }

  /// Extracts the target folder path in Cloudinary.
  String _extractFolder(String bucketName, String storagePath) {
    // If storagePath already starts with the root folder prefix (e.g. "inventory_app/...")
    if (storagePath.startsWith(config.folderPrefix)) {
      final dirname = path.dirname(storagePath);
      return dirname.replaceAll(r'\', '/');
    }

    // Standard structured folder: "inventory_app/<shopId>/<entityType>"
    final baseFolder = config.folderFor(entityType: bucketName);
    final dirname = path.dirname(storagePath);
    if (dirname.isNotEmpty && dirname != '.') {
      return '$baseFolder/$dirname'.replaceAll(r'\', '/');
    }
    return baseFolder;
  }
}
