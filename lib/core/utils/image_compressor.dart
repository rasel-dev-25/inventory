import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import 'app_logger.dart';

/// Central image compression utility to resize and compress photos before
/// storing locally and uploading to Supabase Storage.
class AppImageCompressor {
  static const _tag = 'AppImageCompressor';

  /// Standard max dimension for product, customer, and asset photos.
  static const int defaultMaxDimension = 1200;

  /// Higher max dimension for receipts, invoices, and text-heavy quick memos.
  static const int memoMaxDimension = 1600;

  /// Optimal JPEG/WebP quality (0-100) balancing sharpness and low file size (~150 KB).
  static const int defaultQuality = 80;

  /// Compresses [sourceFile] and writes the optimized image to [destinationPath].
  ///
  /// Preserves aspect ratio, fits within [maxWidth] x [maxHeight], and strips EXIF bloat.
  /// Falls back gracefully to standard copy if native compressor is unavailable (e.g. unit tests).
  static Future<String> compressAndSave({
    required File sourceFile,
    required String destinationPath,
    int maxWidth = defaultMaxDimension,
    int maxHeight = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    final destFile = File(destinationPath);
    await destFile.parent.create(recursive: true);

    try {
      final ext = p.extension(destinationPath).toLowerCase();
      final format = ext == '.webp'
          ? CompressFormat.webp
          : ext == '.png'
              ? CompressFormat.png
              : CompressFormat.jpeg;

      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.path,
        destinationPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: format,
        keepExif: false,
      );

      if (result != null && await File(result.path).exists()) {
        final originalSize = await sourceFile.length();
        final compressedSize = await File(result.path).length();
        final pct = originalSize > 0
            ? ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1)
            : '0.0';
        AppLogger.d(
          _tag,
          'Compressed image: $originalSize B -> $compressedSize B ($pct% savings)',
        );
        return result.path;
      }
    } catch (e) {
      AppLogger.w(
        _tag,
        'Native compression skipped or failed, using standard copy: $e',
      );
    }

    // Fallback if native compressor is unavailable
    if (sourceFile.path != destinationPath) {
      await sourceFile.copy(destinationPath);
    }
    return destinationPath;
  }
}
