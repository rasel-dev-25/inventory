import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;
import 'package:iconsax/iconsax.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/date_utils.dart';

class AssetsController extends GetxController {
  final _dao = Get.find<AppDatabase>().assetDao;
  final _imageService = ImageService();

  final assets = <FixedAsset>[].obs;
  final selectedDate = Rxn<DateTime>();
  final totalAssets = 0.0.obs;

  final nameCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  File? assetImage;

  List<FixedAsset> get filteredAssets {
    if (selectedDate.value == null) return assets;
    final formatted = AppDateUtils.format(selectedDate.value!);
    return assets.where((a) => a.purchaseDate == formatted).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAssets();
  }

  Future<void> loadAssets() async {
    assets.value = await _dao.getAll();
    totalAssets.value = await _dao.totalValue();
  }

  Future<void> pickImage() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) {
      assetImage = file;
      update();
    }
  }

  Future<void> addAsset() async {
    if (nameCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
    await _dao.insertAsset(
      FixedAssetsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameCtrl.text,
        estimatedValue: double.parse(valueCtrl.text),
        purchaseDate: AppDateUtils.today(),
        imagePath: Value(assetImage?.path ?? ''),
      ),
    );
    nameCtrl.clear();
    valueCtrl.clear();
    noteCtrl.clear();
    assetImage = null;
    update();
    await loadAssets();
  }

  Future<void> editAsset(FixedAsset asset) async {
    final nameCtrl = TextEditingController(text: asset.name);
    final valueCtrl = TextEditingController(
      text: asset.estimatedValue.toString(),
    );
    File? editImage = asset.imagePath.isNotEmpty ? File(asset.imagePath) : null;

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.edit, color: Colors.teal, size: 22),
            const SizedBox(width: 10),
            Text('editAsset'.tr),
          ],
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final file = await _imageService.pickFromCamera();
                    if (file != null) {
                      setDialogState(() => editImage = file);
                    }
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: editImage != null
                        ? FileImage(editImage!)
                        : null,
                    child: editImage == null
                        ? const Icon(Iconsax.camera, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'assetNameHint'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'estimatedValue'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    if (result == true &&
        nameCtrl.text.isNotEmpty &&
        valueCtrl.text.isNotEmpty) {
      await _dao.updateAsset(
        asset.id,
        FixedAssetsCompanion(
          name: Value(nameCtrl.text),
          estimatedValue: Value(double.parse(valueCtrl.text)),
          imagePath: Value(editImage?.path ?? ''),
        ),
      );
      await loadAssets();
    }
  }

  Future<void> deleteAsset(String id) async {
    await _dao.deleteAsset(id);
    await loadAssets();
  }

  Future<void> pickDate() async {
    final picked = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      ),
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  void clearDateFilter() {
    selectedDate.value = null;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    valueCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }
}
