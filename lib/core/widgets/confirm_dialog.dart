import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool> showConfirmDialog({
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  Color? confirmColor,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(cancelLabel ?? 'cancel'.tr),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor ?? Colors.red),
          onPressed: () => Get.back(result: true),
          child: Text(confirmLabel ?? 'delete'.tr, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}
