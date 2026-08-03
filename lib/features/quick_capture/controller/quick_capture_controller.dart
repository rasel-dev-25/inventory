import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/database/app_database.dart';
import '../../../../core/services/image_service.dart';

class QuickCaptureController extends GetxController {
  final _dao = Get.find<AppDatabase>().quickCaptureDao;
  final _imageService = ImageService();

  final captures = <QuickCapture>[].obs;
  final isListening = false.obs;

  stt.SpeechToText? _speech;
  bool _speechInitialized = false;

  @override
  void onInit() {
    super.onInit();
    loadCaptures();
  }

  Future<void> loadCaptures() async {
    captures.value = await _dao.getAll();
  }

  Future<void> captureCamera() async {
    final file = await _imageService.pickFromCamera(quality: 60);
    if (file == null) return;

    final noteCtrl = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text('addNote'.tr, style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: noteCtrl,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'whatIsThis'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: ''),
            child: Text('skip'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: noteCtrl.text),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result == null) return;

    await _dao.insertCapture(
      QuickCapturesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toIso8601String(),
        note: result,
        imagePath: Value(file.path),
        source: const Value('Camera'),
      ),
    );
    await loadCaptures();
    Get.snackbar(
      '',
      'photoCaptured'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> captureNote(String note) async {
    if (note.trim().isEmpty) return;
    await _dao.insertCapture(
      QuickCapturesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toIso8601String(),
        note: note.trim(),
        source: const Value('Quick Note'),
      ),
    );
    await loadCaptures();
    Get.snackbar(
      '',
      'noteCaptured'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void showNoteDialog() {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('quickNote'.tr, style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'writeSomething'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              captureNote(ctrl.text);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> startListening() async {
    _speech ??= stt.SpeechToText();
    if (!_speechInitialized) {
      _speechInitialized = await _speech!.initialize();
      if (!_speechInitialized) return;
    }
    isListening.value = true;
    _speech!.listen(
      onResult: (val) {
        if (val.hasConfidenceRating &&
            val.confidence > 0 &&
            val.recognizedWords.isNotEmpty) {
          captureVoice(val.recognizedWords);
          _speech!.stop();
          isListening.value = false;
        }
      },
    );
  }

  Future<void> captureVoice(String text) async {
    await _dao.insertCapture(
      QuickCapturesCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toIso8601String(),
        note: text,
        source: const Value('Voice'),
      ),
    );
    await loadCaptures();
    Get.snackbar(
      '',
      'voiceCaptured'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void stopListening() {
    _speech?.stop();
    isListening.value = false;
  }

  Future<void> deleteCaptureById(String id) async {
    await _dao.deleteCapture(id);
    await loadCaptures();
    Get.snackbar(
      '',
      'captureDeleted'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> clearAll() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('clearAllCaptures'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('clear'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dao.deleteAll();
      await loadCaptures();
    }
  }

  @override
  void onClose() {
    _speech?.cancel();
    super.onClose();
  }
}
