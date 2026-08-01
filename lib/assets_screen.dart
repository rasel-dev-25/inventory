import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _assetsBox = Hive.box('assetsBox');

  final _assetNameController = TextEditingController();
  final _assetValueController = TextEditingController();
  final _noteController = TextEditingController();
  File? _assetImage;

  List<FixedAsset> _assets = [];
  DateTime? _selectedDate;

  List<FixedAsset> get _filteredAssets {
    if (_selectedDate == null) return _assets;
    final formatted = DateFormat('dd-MM-yyyy').format(_selectedDate!);
    return _assets.where((a) => a.purchaseDate == formatted).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final stored = _assetsBox.get('assets', defaultValue: []);
    setState(() {
      _assets = List<Map<dynamic, dynamic>>.from(stored).map((a) => FixedAsset(
        id: a['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: a['name']?.toString() ?? '',
        estimatedValue: (a['estimatedValue']?.toDouble() ?? 0.0),
        purchaseDate: a['purchaseDate']?.toString() ?? '',
          image: a['imagePath'] != null && a['imagePath'].toString().isNotEmpty ? File(a['imagePath'].toString()) : null,
      )).toList();
    });
  }

  void _saveData() {
    final data = _assets.map((a) => {
      'id': a.id,
      'name': a.name,
      'estimatedValue': a.estimatedValue,
      'purchaseDate': a.purchaseDate,
      'imagePath': a.image?.path ?? '',
    }).toList();
    _assetsBox.put('assets', data);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      setState(() => _assetImage = File(pickedFile.path));
    }
  }

  void _addAsset() {
    if (_assetNameController.text.isEmpty || _assetValueController.text.isEmpty) return;

    setState(() {
      _assets.add(FixedAsset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _assetNameController.text,
        estimatedValue: double.parse(_assetValueController.text),
        purchaseDate: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        image: _assetImage,
      ));
      _assetNameController.clear();
      _assetValueController.clear();
      _assetImage = null;
      _saveData();
    });
  }

  void _editAsset(int index) {
    final asset = _assets[index];
    final nameCtrl = TextEditingController(text: asset.name);
    final valueCtrl = TextEditingController(text: asset.estimatedValue.toString());
    File? editImage = asset.image;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.edit, color: Colors.teal, size: 22),
            const SizedBox(width: 10),
            Text(lang.Lang.tr('editAsset')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 30, maxWidth: 600, maxHeight: 600);
                  if (picked != null) {
                    editImage = File(picked.path);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _editAsset(index);
                  }
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: editImage != null ? FileImage(editImage!) : null,
                  child: editImage == null ? const Icon(Iconsax.camera, size: 28) : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: lang.Lang.tr('assetNameHint'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.Lang.tr('estimatedValue'), border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
              setState(() {
                _assets[index] = FixedAsset(
                  id: asset.id,
                  name: nameCtrl.text,
                  estimatedValue: double.parse(valueCtrl.text),
                  purchaseDate: asset.purchaseDate,
                  image: editImage,
                );
                _saveData();
              });
              Navigator.pop(ctx);
            },
            child: Text(lang.Lang.tr('save')),
          ),
        ],
      ),
    );
  }

  void _deleteAsset(int index) {
    setState(() {
      _assets.removeAt(index);
      _saveData();
    });
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    setState(() {
      _selectedDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: shopLogo(size: 20, color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Iconsax.calendar, color: _selectedDate != null ? Colors.yellow : Colors.white),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(lang.Lang.tr('addNewAsset'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.teal.shade100,
                            backgroundImage: _assetImage != null ? FileImage(_assetImage!) : null,
                            child: _assetImage == null ? const Icon(Iconsax.camera) : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _assetNameController,
                             decoration: InputDecoration(labelText: lang.Lang.tr('assetNameHint'), border: const OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _assetValueController,
                      keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.Lang.tr('estimatedValue'), border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            decoration: InputDecoration(labelText: lang.Lang.tr('noteOptional'), border: const OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addAsset,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.teal),
                      child: Text(lang.Lang.tr('saveAsset'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(lang.Lang.tr('assetList'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredAssets.isEmpty
                  ? Center(
                      child: Text(lang.Lang.tr('noAssets'), style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    )
                  : ListView.builder(
                      itemCount: _filteredAssets.length,
                      itemBuilder: (context, index) {
                        final asset = _filteredAssets[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: asset.image != null ? FileImage(asset.image!) : null,
                              child: asset.image == null ? const Icon(Iconsax.box) : null,
                            ),
                            title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                             subtitle: Text('${lang.Lang.tr('dateLabel')}${asset.purchaseDate}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Text('৳${asset.estimatedValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                IconButton(
                                  icon: const Icon(Iconsax.edit, color: Colors.teal),
                                  onPressed: () => _editAsset(index),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.red),
                                  onPressed: () => _deleteAsset(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetValueController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
