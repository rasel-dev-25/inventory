import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../domain/entities/customer.dart';

/// What [CustomerFormSheet] hands back on save — `CustomersScreen` decides
/// whether that means a create or an update, since only it knows whether
/// [CustomerFormSheet.existing] was passed. Same split of responsibility
/// as `ProductFormSheet`/`ProductFormResult`.
class CustomerFormResult {
  final String name;
  final String? address;
  final String? contact;
  final bool suspicionFlag;
  final bool isBlocked;
  final String? photoLocalPath;

  const CustomerFormResult({
    required this.name,
    this.suspicionFlag = false,
    this.isBlocked = false,
    this.address,
    this.contact,
    this.photoLocalPath,
  });
}

/// Create/edit form for a single [Customer]. Pure form state — validation
/// and the actual create/update call both live in `CustomersController`,
/// this widget only ever returns a [CustomerFormResult] via
/// `Navigator.pop`.
class CustomerFormSheet extends StatefulWidget {
  final Customer? existing;
  final Future<String?> Function()? onCapturePhoto;
  final String? existingPhotoSource;
  final Future<void> Function()? onDelete;

  const CustomerFormSheet({
    super.key,
    this.existing,
    this.onCapturePhoto,
    this.existingPhotoSource,
    this.onDelete,
  });

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name,
  );
  late final _addressController = TextEditingController(
    text: widget.existing?.address,
  );
  late final _contactController = TextEditingController(
    text: widget.existing?.contact,
  );
  String? _photoLocalPath;
  late String? _photoPreviewSource = widget.existingPhotoSource;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'addCustomer'.tr : 'editCustomer'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'customerName'.tr),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'nameRequired'.tr : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'phone'.tr),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'address'.tr),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: widget.onCapturePhoto == null ? null : _capturePhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _photoPreviewSource == null
                      ? 'addCustomerPhoto'.tr
                      : 'changeCustomerPhoto'.tr,
                ),
              ),
              if (_photoPreviewSource case final photoSource?) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => showFullScreenImageViewer(
                    context,
                    imagePath: photoSource,
                    title: _nameController.text.trim().isNotEmpty
                        ? _nameController.text.trim()
                        : 'Customer Photo',
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SafeImage(
                        source: photoSource,
                        height: 160,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        fallbackIcon: Icons.broken_image_outlined,
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('tapToZoom'.tr, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: Text('save'.tr)),
              if (widget.existing != null && widget.onDelete != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('deleteCustomer'.tr),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('${'delete'.tr} ${widget.existing!.name}?'),
                        content: Text('deleteCustomerConfirm'.tr),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('cancel'.tr),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('delete'.tr),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await widget.onDelete!();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final photoPath = await widget.onCapturePhoto?.call();
    if (photoPath == null || !mounted) return;
    setState(() {
      _photoLocalPath = photoPath;
      _photoPreviewSource = photoPath;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CustomerFormResult(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        suspicionFlag: widget.existing?.suspicionFlag ?? false,
        isBlocked: widget.existing?.isBlocked ?? false,
        photoLocalPath: _photoLocalPath,
      ),
    );
  }
}
