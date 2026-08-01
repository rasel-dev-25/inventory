import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:intl/intl.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;

final Box _quickBox = Hive.box('quickBox');

void saveQuickCapture({
  required String note,
  String? imagePath,
  String source = '',
}) {
  final captures = List<Map<dynamic, dynamic>>.from(_quickBox.get('captures', defaultValue: []));
  captures.insert(0, {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'timestamp': DateTime.now().toIso8601String(),
    'note': note,
    'imagePath': imagePath ?? '',
    'source': source,
  });
  _quickBox.put('captures', captures);
}

List<Map<dynamic, dynamic>> getAllCaptures() {
  return List<Map<dynamic, dynamic>>.from(_quickBox.get('captures', defaultValue: []));
}

void deleteCapture(String id) {
  final captures = List<Map<dynamic, dynamic>>.from(_quickBox.get('captures', defaultValue: []));
  captures.removeWhere((c) => c['id'] == id);
  _quickBox.put('captures', captures);
}

Widget _captureSourceIcon(String source) {
  IconData icon;
  Color color;
  switch (source) {
    case 'Customer':
      icon = Iconsax.people;
      color = Colors.teal;
      break;
    case 'Dues':
      icon = Iconsax.book;
      color = Colors.orange;
      break;
    case 'Product':
      icon = Iconsax.box;
      color = Colors.blue;
      break;
    case 'Asset':
      icon = Iconsax.buildings;
      color = Colors.purple;
      break;
    case 'Expense':
      icon = Iconsax.receipt;
      color = Colors.red;
      break;
    case 'Purchase':
      icon = Iconsax.shopping_cart;
      color = Colors.indigo;
      break;
    case 'Repayment':
      icon = Iconsax.money;
      color = Colors.green;
      break;
    default:
      icon = Iconsax.bookmark;
      color = Colors.grey;
  }
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, size: 14, color: color),
  );
}

class QuickCaptureGallery extends StatefulWidget {
  const QuickCaptureGallery({super.key});

  @override
  State<QuickCaptureGallery> createState() => _QuickCaptureGalleryState();
}

class _QuickCaptureGalleryState extends State<QuickCaptureGallery> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechInitialized = false;
  List<Map<dynamic, dynamic>> _captures = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _load();
  }

  void _load() {
    setState(() => _captures = getAllCaptures());
  }

  Future<void> _captureCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60);
    if (picked == null) return;
    if (!mounted) return;

    final noteCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.Lang.tr('addNote'), style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: noteCtrl,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(hintText: lang.Lang.tr('whatIsThis'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: Text(lang.Lang.tr('skip'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, noteCtrl.text), child: Text(lang.Lang.tr('save'))),
        ],
      ),
    );
    if (result == null) return;
    saveQuickCapture(note: result, imagePath: picked.path, source: 'Camera');
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.Lang.tr('photoCaptured')), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _startListening() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize();
      if (!_speechInitialized) return;
    }
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (val) {
        if (val.hasConfidenceRating && val.confidence > 0 && val.recognizedWords.isNotEmpty) {
          saveQuickCapture(note: val.recognizedWords, source: 'Voice');
          _speech.stop();
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.Lang.tr('voiceCaptured')), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
            );
          }
        }
      },
    );
    setState(() {});
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: shopLogo(size: 18, color: Colors.white),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (_captures.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash, size: 20),
              tooltip: lang.Lang.tr('clearAll'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(lang.Lang.tr('clearAllCaptures')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.Lang.tr('cancel'))),
                      TextButton(
                        onPressed: () {
                          _quickBox.put('captures', []);
                          Navigator.pop(ctx);
                          _load();
                        },
                        child: Text(lang.Lang.tr('clear'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildActionBar(),
          const Divider(height: 1),
          Expanded(child: _captures.isEmpty ? _buildEmptyState() : _buildCaptureList()),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B).withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Iconsax.camera, lang.Lang.tr('camera'), _captureCamera),
              _actionButton(Iconsax.edit, lang.Lang.tr('note'), () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: Text(lang.Lang.tr('quickNote'), style: const TextStyle(fontSize: 14)),
                      content: TextField(
                        controller: ctrl,
                        autofocus: true,
                        maxLines: 3,
                        decoration: InputDecoration(hintText: lang.Lang.tr('writeSomething'), border: const OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.Lang.tr('cancel'))),
                        ElevatedButton(
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              saveQuickCapture(note: ctrl.text.trim(), source: 'Quick Note');
                              Navigator.pop(ctx);
                              _load();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lang.Lang.tr('noteCaptured')), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                          child: Text(lang.Lang.tr('save')),
                        ),
                      ],
                    );
                  },
                );
              }),
              _actionButton(
                _isListening ? Iconsax.microphone : Iconsax.microphone_slash,
                _isListening ? lang.Lang.tr('recording') : lang.Lang.tr('voice'),
                _isListening ? _stopListening : _startListening,
                color: _isListening ? Colors.red : null,
              ),
            ],
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red.shade400),
                  ),
                  const SizedBox(width: 8),
                  Text(lang.Lang.tr('listening'),
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF00897B);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 22, color: c),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w500)),
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
          Text(lang.Lang.tr('noCaptures'), style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          const SizedBox(height: 6),
          Text(lang.Lang.tr('captureHint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCaptureList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _captures.length,
      itemBuilder: (ctx, i) {
        final c = _captures[i];
        final hasImage = c['imagePath']?.toString().isNotEmpty == true && File(c['imagePath']).existsSync();
        return _CaptureCard(
          capture: c,
          hasImage: hasImage,
          onDelete: () {
            deleteCapture(c['id']);
            _load();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.Lang.tr('captureDeleted')), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
            );
          },
        );
      },
    );
  }
}

class _CaptureCard extends StatefulWidget {
  final Map<dynamic, dynamic> capture;
  final bool hasImage;
  final VoidCallback onDelete;

  const _CaptureCard({
    required this.capture,
    required this.hasImage,
    required this.onDelete,
  });

  @override
  State<_CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<_CaptureCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.capture;
    final note = c['note']?.toString() ?? '';
    final source = c['source']?.toString() ?? '';
    final ts = c['timestamp']?.toString() ?? '';
    final timeStr = ts.isNotEmpty
        ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(ts))
        : '';
    final noteShort = note.length > 60 ? '${note.substring(0, 60)}...' : note;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(c['imagePath'].toString()),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (widget.hasImage) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _captureSourceIcon(source),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(timeStr,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.trash, size: 18),
                              color: Colors.red.shade300,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_expanded ? note : noteShort,
                            style: TextStyle(
                              fontSize: 13,
                              color: note.isEmpty ? Colors.grey.shade400 : Colors.black87,
                              fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
                            )),
                        if (_expanded && source.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Iconsax.arrow_right, size: 14, color: Colors.grey.shade400),
                              Text('${lang.Lang.tr('fromLabel')}$source',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
