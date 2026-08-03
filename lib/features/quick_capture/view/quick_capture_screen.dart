import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';

import '../../../../core/widgets/shop_logo.dart';
import '../../../../app/theme/app_colors.dart';
import '../controller/quick_capture_controller.dart';
import 'widgets/capture_card.dart';

class QuickCaptureScreen extends GetView<QuickCaptureController> {
  const QuickCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: shopLogo(size: 18, color: Colors.white),
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        actions: [
          Obx(
            () => controller.captures.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.trash, size: 20),
                    tooltip: 'clearAll'.tr,
                    onPressed: controller.clearAll,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildActionBar(),
          const Divider(height: 1),
          Expanded(
            child: Obx(
              () => controller.captures.isEmpty
                  ? _buildEmptyState()
                  : _buildCaptureList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kTeal.withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                Iconsax.camera,
                'camera'.tr,
                controller.captureCamera,
              ),
              _actionButton(Iconsax.edit, 'note'.tr, controller.showNoteDialog),
              Obx(
                () => _actionButton(
                  controller.isListening.value
                      ? Iconsax.microphone
                      : Iconsax.microphone_slash,
                  controller.isListening.value ? 'recording'.tr : 'voice'.tr,
                  controller.isListening.value
                      ? controller.stopListening
                      : controller.startListening,
                  color: controller.isListening.value ? Colors.red : null,
                ),
              ),
            ],
          ),
          Obx(
            () => controller.isListening.value
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'listening'.tr,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? kTeal;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 22, color: c),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.bookmark, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'noCaptures'.tr,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'captureHint'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: controller.captures.length,
      itemBuilder: (ctx, i) {
        final c = controller.captures[i];
        final hasImage =
            c.imagePath.isNotEmpty && File(c.imagePath).existsSync();
        return CaptureCard(
          capture: c,
          hasImage: hasImage,
          onDelete: () => controller.deleteCaptureById(c.id),
        );
      },
    );
  }
}
