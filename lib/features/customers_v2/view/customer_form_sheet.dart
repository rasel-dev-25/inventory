import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
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
    required this.suspicionFlag,
    required this.isBlocked,
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

  const CustomerFormSheet({
    super.key,
    this.existing,
    this.onCapturePhoto,
    this.existingPhotoSource,
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
  late bool _suspicionFlag = widget.existing?.suspicionFlag ?? false;
  late bool _isBlocked = widget.existing?.isBlocked ?? false;
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: photoSource.startsWith('http')
                      ? Image.network(
                          photoSource,
                          height: 160,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(photoSource),
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 160,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('suspicionFlag'.tr),
                value: _suspicionFlag,
                onChanged: (v) => setState(() => _suspicionFlag = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('isBlockedLabel'.tr),
                value: _isBlocked,
                onChanged: (v) => setState(() => _isBlocked = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: Text('save'.tr)),
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
        suspicionFlag: _suspicionFlag,
        isBlocked: _isBlocked,
        photoLocalPath: _photoLocalPath,
      ),
    );
  }
}
