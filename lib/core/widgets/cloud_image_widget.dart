import 'dart:io';

import 'package:flutter/material.dart';

import '../storage/cloudinary_config.dart';

/// An intelligent, offline-first image widget that seamlessly displays:
/// 1. Local file path if present on disk (instant 0ms loading, works offline).
/// 2. Cloudinary CDN URL with on-the-fly WebP and dynamic size transformations.
/// 3. Standard network or asset fallbacks.
class CloudImageWidget extends StatelessWidget {
  final String? localPath;
  final String? remoteUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isThumbnail;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CloudImageWidget({
    super.key,
    this.localPath,
    this.remoteUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isThumbnail = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent = _buildContent(context);

    if (borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    // 1. First priority: Local file on device (fastest, offline-first)
    if (localPath != null && localPath!.isNotEmpty) {
      final file = File(localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, error, stackTrace) => _buildFallback(context),
        );
      }
    }

    // 2. Second priority: Remote Cloudinary CDN URL
    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      final targetUrl = _resolveOptimizedUrl(remoteUrl!);
      return Image.network(
        targetUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return placeholder ?? _defaultPlaceholder(ctx);
        },
        errorBuilder: (_, error, stackTrace) => errorWidget ?? _buildFallback(context),
      );
    }

    // 3. Fallback placeholder if no image exists
    return placeholder ?? _defaultPlaceholder(context);
  }

  String _resolveOptimizedUrl(String url) {
    if (!CloudinaryConfig.isCloudinaryUrl(url)) {
      return url;
    }

    if (isThumbnail) {
      final w = (width ?? 200).toInt();
      final h = (height ?? 200).toInt();
      return CloudinaryConfig.getThumbnailUrl(url, width: w, height: h);
    } else {
      return CloudinaryConfig.getPreviewUrl(url);
    }
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width != null && width! < 60) ? 20 : 28,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (width != null && width! < 60) ? 20 : 28,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
