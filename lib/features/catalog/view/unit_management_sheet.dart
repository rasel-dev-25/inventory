import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/unit_dao.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/usecases/unit_usecases.dart';
import '../../../domain/entities/product_unit.dart';

/// Modal bottom sheet for managing product units of measurement (pcs, kg, litre, etc.)
/// Allows users to view all available units, add new custom units, rename, or delete units.
class UnitManagementSheet extends StatefulWidget {
  final String? initialSelectedUnit;

  const UnitManagementSheet({super.key, this.initialSelectedUnit});

  @override
  State<UnitManagementSheet> createState() => _UnitManagementSheetState();
}

class _UnitManagementSheetState extends State<UnitManagementSheet> {
  late final UnitUseCases _unitUseCases;
  final TextEditingController _addController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    final db = Get.find<AppDatabase>();
    _unitUseCases = UnitUseCases(db);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addNewUnit() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final now = DateTime.now().toUtc();
      final newUnit = await _unitUseCases.create(
        shopId: defaultShopId,
        name: name,
        now: now,
      );
      _addController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('unitCreated'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _showRenameDialog(ProductUnit unit) async {
    final editController = TextEditingController(text: unit.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('editUnit'.tr),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'unitName'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && editController.text.trim().isNotEmpty) {
      final newName = editController.text.trim();
      final now = DateTime.now().toUtc();
      await _unitUseCases.rename(
        id: unit.id,
        shopId: defaultShopId,
        name: newName,
        now: now,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('unitUpdated'.tr)),
        );
      }
    }
  }

  Future<void> _showDeleteConfirm(ProductUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${'deleteUnit'.tr}: ${unit.name}?'),
        content: Text('deleteUnitConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final now = DateTime.now().toUtc();
      await _unitUseCases.delete(
        id: unit.id,
        shopId: defaultShopId,
        now: now,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('unitDeleted'.tr)),
        );
      }
    }
  }

  Future<void> _restoreDefaultUnits() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('restoreDefaultUnits'.tr),
        content: Text('restoreDefaultsConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final now = DateTime.now().toUtc();
      await _unitUseCases.restoreDefaults(shopId: defaultShopId, now: now);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('defaultsRestored'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Icon(
                    Icons.straighten,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'manageUnits'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    tooltip: 'restoreDefaultUnits'.tr,
                    onPressed: _restoreDefaultUnits,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Add New Unit Input Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      decoration: InputDecoration(
                        labelText: 'addUnit'.tr,
                        hintText: 'e.g. meter, bundle, bosta',
                        isDense: true,
                        prefixIcon: const Icon(Icons.add_box_outlined, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addNewUnit(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _isAdding ? null : _addNewUnit,
                    child: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('add'.tr),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Units List
              Flexible(
                child: StreamBuilder<List<ProductUnit>>(
                  stream: _unitUseCases.watchAll(defaultShopId),
                  builder: (context, snapshot) {
                    final units = snapshot.data ?? [];
                    if (units.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text('noUnitsYet'.tr),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final unit = units[index];
                        final isSelected = widget.initialSelectedUnit != null &&
                            unit.name.toLowerCase() ==
                                widget.initialSelectedUnit!.toLowerCase();
                        final isDefault = UnitDao.defaultUnitNames
                            .contains(unit.name.toLowerCase());

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              unit.name.substring(0, unit.name.length > 2 ? 2 : unit.name.length).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            unit.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: isDefault
                              ? Text(
                                  'Standard Unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                              : Text(
                                  'Custom Unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'editUnit'.tr,
                                onPressed: () => _showRenameDialog(unit),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                tooltip: 'deleteUnit'.tr,
                                onPressed: () => _showDeleteConfirm(unit),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop(unit.name);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
