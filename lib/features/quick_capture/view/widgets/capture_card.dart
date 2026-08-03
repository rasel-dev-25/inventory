import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../../../../core/database/app_database.dart';

class CaptureCard extends StatefulWidget {
  final QuickCapture capture;
  final bool hasImage;
  final VoidCallback onDelete;

  const CaptureCard({
    super.key,
    required this.capture,
    required this.hasImage,
    required this.onDelete,
  });

  @override
  State<CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<CaptureCard> {
  bool _expanded = false;

  Widget _sourceIcon(String source) {
    IconData icon;
    Color color;
    switch (source) {
      case 'Customer': icon = Iconsax.people; color = Colors.teal;
      case 'Dues': icon = Iconsax.book; color = Colors.orange;
      case 'Product': icon = Iconsax.box; color = Colors.blue;
      case 'Asset': icon = Iconsax.buildings; color = Colors.purple;
      case 'Expense': icon = Iconsax.receipt; color = Colors.red;
      case 'Purchase': icon = Iconsax.shopping_cart; color = Colors.indigo;
      case 'Repayment': icon = Iconsax.money; color = Colors.green;
      default: icon = Iconsax.bookmark; color = Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    final c = widget.capture;
    final note = c.note;
    final source = c.source;
    final timeStr = c.timestamp.isNotEmpty
        ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(c.timestamp))
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
                      child: Image.file(File(c.imagePath), width: 48, height: 48, fit: BoxFit.cover),
                    ),
                  if (widget.hasImage) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _sourceIcon(source),
                            const SizedBox(width: 6),
                            Expanded(child: Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 11))),
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
                              Text('${'fromLabel'.tr}$source', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
