import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';

import '../../../../core/widgets/shop_logo.dart';
import '../../../../app/theme/app_colors.dart';
import '../controller/assets_controller.dart';

class AssetsScreen extends GetView<AssetsController> {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal,
        title: shopLogo(size: 20, color: Colors.white),
        actions: [
          Obx(() => IconButton(
            icon: Icon(Iconsax.calendar, color: controller.selectedDate.value != null ? Colors.yellow : Colors.white),
            onPressed: controller.pickDate,
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildForm(),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('assetList'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTeal)),
            ),
            const SizedBox(height: 10),
            Expanded(child: Obx(() => _buildList())),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('addNewAsset'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTeal)),
            const SizedBox(height: 10),
            Row(
              children: [
                GetBuilder<AssetsController>(
                  builder: (c) => GestureDetector(
                    onTap: c.pickImage,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage: c.assetImage != null ? FileImage(c.assetImage!) : null,
                      child: c.assetImage == null ? const Icon(Iconsax.camera) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.nameCtrl,
                    decoration: InputDecoration(labelText: 'assetNameHint'.tr, border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.valueCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'estimatedValue'.tr, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.noteCtrl,
              decoration: InputDecoration(labelText: 'noteOptional'.tr, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: controller.addAsset,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: kTeal),
              child: Text('saveAsset'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final list = controller.filteredAssets;
    if (list.isEmpty) {
      return Center(child: Text('noAssets'.tr, style: const TextStyle(fontSize: 16, color: Colors.black54)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final asset = list[index];
        final hasImage = asset.imagePath.isNotEmpty && File(asset.imagePath).existsSync();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: hasImage ? FileImage(File(asset.imagePath)) : null,
              child: hasImage ? null : const Icon(Iconsax.box),
            ),
            title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${'dateLabel'.tr}${asset.purchaseDate}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('৳${asset.estimatedValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
                IconButton(
                  icon: const Icon(Iconsax.edit, color: kTeal),
                  onPressed: () => controller.editAsset(asset),
                ),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.red),
                  onPressed: () => controller.deleteAsset(asset.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
