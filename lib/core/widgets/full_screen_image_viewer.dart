import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../design/tokens.dart';

/// Opens an immersive, professional full-screen image viewer with pinch-to-zoom,
/// double-tap zoom, smooth pan, title/caption, and swipe/tap-to-dismiss.
Future<void> showFullScreenImageViewer(
  BuildContext context, {
  required String imagePath,
  String? title,
  String? subtitle,
  String? heroTag,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FullScreenImageViewer(
          imagePath: imagePath,
          title: title,
          subtitle: subtitle,
          heroTag: heroTag,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    ),
  );
}

class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String? title;
  final String? subtitle;
  final String? heroTag;

  const FullScreenImageViewer({
    required this.imagePath,
    this.title,
    this.subtitle,
    this.heroTag,
    super.key,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final Matrix4 targetMatrix;

    if (currentScale > 1.2) {
      // Zoom out to normal
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x focused around double-tap position
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * (2.5 - 1);
      final y = -position.dy * (2.5 - 1);

      targetMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(2.5);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.imagePath.startsWith('http://') ||
        widget.imagePath.startsWith('https://');
    final file = File(widget.imagePath);
    final exists = isNetwork || file.existsSync();

    Widget errorFallback() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'imageNotFound'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );

    Widget imageWidget;
    if (!exists) {
      imageWidget = errorFallback();
    } else if (isNetwork) {
      imageWidget = Image.network(
        widget.imagePath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => errorFallback(),
      );
    } else {
      imageWidget = Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => errorFallback(),
      );
    }

    if (widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        onDoubleTapDown: (d) => _doubleTapDetails = d,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Interactive Zoomable Image area
            Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.8,
                maxScale: 5.0,
                child: imageWidget,
              ),
            ),

            // Top App Bar Overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showOverlay ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 16,
                  left: 8,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'back'.tr,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null && widget.title!.isNotEmpty)
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'close'.tr,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Helper Overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showOverlay ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pinch, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'pinchToZoom'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
