import 'dart:io';

import 'package:flutter/material.dart';

import '../storage/cloudinary_config.dart';

/// A completely crash-safe image rendering widget.
///
/// Features:
/// - Handles null, empty, invalid, 404, or corrupt image sources safely.
/// - Prioritizes local file on disk for instant 0ms offline rendering.
/// - Falls back to remote Cloudinary/HTTP URLs with auto-optimization.
/// - Never crashes the UI or shows red screens/overflow stripes.
/// - Provides customizable placeholders, fallback icons, and error widgets.
class SafeImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? fallbackWidget;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? iconColor;

  const SafeImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fallbackWidget,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildImageContent(context);

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: content,
      );
    }

    return content;
  }

  Widget _buildImageContent(BuildContext context) {
    final rawSource = source?.trim() ?? '';
    if (rawSource.isEmpty) {
      return _buildFallback(context);
    }

    // 1. Network / Cloudinary URL
    if (rawSource.startsWith('http://') || rawSource.startsWith('https://')) {
      final optimizedUrl = _getOptimizedUrl(rawSource);
      return Image.network(
        optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return placeholder ?? _defaultLoading(ctx);
        },
        errorBuilder: (ctx, error, stackTrace) {
          return _buildFallback(ctx);
        },
      );
    }

    // 2. Local file on device
    try {
      final file = File(rawSource);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, error, stackTrace) {
            return _buildFallback(ctx);
          },
        );
      }
    } catch (_) {
      // Ignore file system errors and fall through to fallback
    }

    // 3. Fallback if file does not exist or URL is invalid
    return _buildFallback(context);
  }

  String _getOptimizedUrl(String url) {
    if (!CloudinaryConfig.isCloudinaryUrl(url)) {
      return url;
    }
    if (width != null && width! <= 300 && height != null && height! <= 300) {
      return CloudinaryConfig.getThumbnailUrl(
        url,
        width: width!.toInt(),
        height: height!.toInt(),
      );
    }
    return CloudinaryConfig.getPreviewUrl(url);
  }

  Widget _defaultLoading(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: fallbackColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Center(
        child: SizedBox(
          width: (width != null && width! < 50) ? 14 : 20,
          height: (height != null && height! < 50) ? 14 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallbackWidget != null) return fallbackWidget!;

    final theme = Theme.of(context);
    final bg = fallbackColor ?? theme.colorScheme.surfaceContainerHighest;
    final fg = iconColor ?? theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Container(
      width: width,
      height: height,
      color: bg,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (width != null && width! < 60) ? 20 : 28,
          color: fg,
        ),
      ),
    );
  }
}
