import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/notification_bell_action.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fixed_asset.dart';
import '../controller/fixed_asset_controller.dart';

/// Upgraded Fixed Asset screen — view overview metrics, filter assets,
/// capture/view photo attachments, and add new assets via direct purchase
/// or convert-from-stock in a modern, keyboard-safe bottom sheet.
class FixedAssetScreen extends StatefulWidget {
  const FixedAssetScreen({super.key});

  @override
  State<FixedAssetScreen> createState() => _FixedAssetScreenState();
}

class _FixedAssetScreenState extends State<FixedAssetScreen> {
  String _filter = 'all'; // 'all', 'direct', 'stock'

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FixedAssetController>();

    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'fixedAssets'.tr),
        actions: const [
          NotificationBellAction(),
          SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final assets = controller.assets;
        final totalCount = controller.totalCount;
        final totalValue = controller.totalValue;
        final directCount = controller.directPurchaseCount;
        final directValue = controller.directPurchaseValue;
        final stockCount = controller.convertedCount;
        final stockValue = controller.convertedValue;

        final filteredAssets = assets.where((a) {
          if (_filter == 'direct') {
            return a.sourceType == FixedAssetSource.shopCashPurchase;
          }
          if (_filter == 'stock') {
            return a.sourceType == FixedAssetSource.convertedFromStock;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Top Metrics Summary Grid ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AssetMetricCard(
                    title: 'মোট স্থায়ী সম্পদ',
                    value: '$totalCountটি সম্পদ',
                    icon: Icons.business_center_outlined,
                    color: Colors.indigo.shade700,
                    bgColor: Colors.indigo.shade50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AssetMetricCard(
                    title: 'সম্পদের মোট মূল্য',
                    value: totalValue.format(),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.teal.shade800,
                    bgColor: Colors.teal.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AssetMetricCard(
                    title: 'সরাসরি কেনা ($directCount)',
                    value: directValue.format(),
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.blue.shade800,
                    bgColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AssetMetricCard(
                    title: 'স্টক থেকে কনভার্ট ($stockCount)',
                    value: stockValue.format(),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.purple.shade800,
                    bgColor: Colors.purple.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 2. Filter Chips Bar ─────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('সব সম্পদ ($totalCount)'),
                    selected: _filter == 'all',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text('সরাসরি ক্রয় ($directCount)'),
                    selected: _filter == 'direct',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'direct');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('স্টক থেকে ($stockCount)'),
                    selected: _filter == 'stock',
                    onSelected: (val) {
                      if (val) setState(() => _filter = 'stock');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3. Asset List ───────────────────────────────────────────────
            if (filteredAssets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filter == 'all'
                            ? 'এখনো কোনো স্থায়ী সম্পদ যোগ করা হয়নি'
                            : 'এই ক্যাটাগরিতে কোনো সম্পদ নেই',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => _openAddAssetSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('নতুন সম্পদ যোগ করুন'),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final asset in filteredAssets)
                _FixedAssetCard(
                  asset: asset,
                  onDelete: () => _confirmDelete(context, controller, asset),
                ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fixed_asset_fab',
        onPressed: () => _openAddAssetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('সম্পদ যোগ করুন'),
      ),
    );
  }

  void _openAddAssetSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFixedAssetSheet(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FixedAssetController controller,
    FixedAsset asset,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সম্পদ মুছে ফেলবেন?'),
        content: Text(
          'আপনি কি নিশ্চিত যে "${asset.name}" সম্পদটি মুছে ফেলতে চান?\n\n'
          'মূল্য: ${asset.value.format()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await controller.deleteAsset(asset.id);
      if (success) {
        Get.snackbar(
          'সম্পদ মুছে ফেলা হয়েছে',
          '${asset.name} সফলভাবে তালিকা থেকে মুছে ফেলা হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────
class _AssetMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _AssetMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fixed Asset Card ────────────────────────────────────────────────────────
class _FixedAssetCard extends StatelessWidget {
  final FixedAsset asset;
  final VoidCallback onDelete;

  const _FixedAssetCard({
    required this.asset,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FixedAssetController>();
    final theme = Theme.of(context);
    final isFromStock = asset.sourceType == FixedAssetSource.convertedFromStock;
    final imageRow = controller.primaryImageFor(asset.id);
    final imageSource = imageRow != null ? controller.imageSourceFor(imageRow) : null;
    final dateFmt = DateFormat('dd MMM, yyyy').format(asset.dateAcquired);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFromStock ? Colors.purple.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Photo with Zoom
            _buildThumbnail(context, imageSource),
            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red.shade400,
                        ),
                        onPressed: onDelete,
                        tooltip: 'মুছুন',
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFromStock ? Colors.purple.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isFromStock ? Colors.purple.shade200 : Colors.blue.shade200,
                          ),
                        ),
                        child: Text(
                          isFromStock ? '📦 স্টক থেকে কনভার্ট' : '🛒 সরাসরি কেনা',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFromStock ? Colors.purple.shade800 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📅 $dateFmt',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'মূল্য: ${asset.value.format()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, String? imageSource) {
    if (imageSource != null && imageSource.trim().isNotEmpty) {
      return GestureDetector(
        onTap: () => showFullScreenImageViewer(
          context,
          imagePath: imageSource,
          title: asset.name,
        ),
        child: SafeImage(
          source: imageSource,
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
          fallbackWidget: _placeholderIcon(),
        ),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    final isFromStock = asset.sourceType == FixedAssetSource.convertedFromStock;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isFromStock ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isFromStock ? Icons.inventory_2_outlined : Icons.apartment_rounded,
        color: isFromStock ? Colors.purple.shade700 : Colors.blue.shade700,
        size: 28,
      ),
    );
  }
}

// ── Add Fixed Asset Bottom Sheet ────────────────────────────────────────────
class _AddFixedAssetSheet extends StatefulWidget {
  const _AddFixedAssetSheet();

  @override
  State<_AddFixedAssetSheet> createState() => _AddFixedAssetSheetState();
}

class _AddFixedAssetSheetState extends State<_AddFixedAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  FixedAssetController get controller => Get.find<FixedAssetController>();

  bool _isDirectPurchase = true;
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  String? _selectedProductId;
  String? _photoLocalPath;
  DateTime _dateAcquired = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onProductSelected(String? productId) {
    setState(() {
      _selectedProductId = productId;
      if (productId != null) {
        final product = controller.productById(productId);
        if (product != null) {
          _nameController.text = product.name;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    bool ok = false;
    if (_isDirectPurchase) {
      final value = _parseMoneyOrNull(_valueController.text);
      if (value == null) return;

      ok = await controller.createFromCashPurchase(
        name: _nameController.text.trim(),
        value: value,
        dateAcquired: _dateAcquired,
        photoLocalPath: _photoLocalPath,
      );
    } else {
      if (_selectedProductId == null) return;
      final qty = double.tryParse(_qtyController.text.trim()) ?? 1.0;

      ok = await controller.createFromStock(
        productId: _selectedProductId!,
        qty: qty,
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        photoLocalPath: _photoLocalPath,
      );
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
      Get.snackbar(
        'সম্পদ সংরক্ষিত',
        '${_nameController.text.trim()} সফলভাবে স্থায়ী সম্পদে যুক্ত করা হয়েছে।',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'স্থায়ী সম্পদ যুক্ত করুন',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Source Segmented Toggle ──
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.shopping_bag_outlined, size: 16),
                        label: Text('সরাসরি ক্রয়'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.inventory_2_outlined, size: 16),
                        label: Text('স্টক থেকে কনভার্ট'),
                      ),
                    ],
                    selected: {_isDirectPurchase},
                    onSelectionChanged: (s) {
                      setState(() {
                        _isDirectPurchase = s.first;
                        _nameController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Mode: Direct Purchase ──
                  if (_isDirectPurchase) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'সম্পদের নাম *',
                        hintText: 'যেমন: টেবিল, চেয়ার, ফ্যান, শোকেস',
                        prefixIcon: const Icon(Icons.apartment_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'সম্পদের নাম লিখুন' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'সম্পদের ক্রয়মূল্য *',
                        hintText: '5000',
                        prefixText: '৳ ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          _parseMoneyOrNull(v ?? '') == null ? 'সঠিক মূল্য লিখুন' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: const Icon(Icons.calendar_today_outlined, size: 20),
                      title: Text(
                        'অর্জনের তারিখ: ${DateFormat('dd MMM, yyyy').format(_dateAcquired)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateAcquired,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dateAcquired = picked);
                        }
                      },
                    ),
                  ] else ...[
                    // ── Mode: Convert from Stock ──
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      decoration: InputDecoration(
                        labelText: 'পণ্য নির্বাচন করুন *',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        for (final p in controller.products)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (স্টকে আছে: ${p.qty})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                      onChanged: _onProductSelected,
                      validator: (v) => v == null ? 'পণ্য নির্বাচন করুন' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'রূপান্তরের পরিমাণ *',
                              hintText: '1',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) {
                              final num = double.tryParse(v ?? '');
                              if (num == null || num <= 0) return 'সঠিক সংখ্যা দিন';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'সম্পদের নাম',
                              hintText: 'ঐচ্ছিক (পণ্য নাম ব্যবহার হবে)',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),

                  // ── Photo Attachment Button & Preview ──
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final path = await controller.captureFixedAssetPhoto();
                          if (path != null) {
                            setState(() => _photoLocalPath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(
                          _photoLocalPath == null ? 'ছবি তুলুন / আপলোড' : 'ছবি পরিবর্তন',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_photoLocalPath != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.red),
                          tooltip: 'ছবি মুছুন',
                          onPressed: () => setState(() => _photoLocalPath = null),
                        ),
                      ],
                    ],
                  ),
                  if (_photoLocalPath case final path?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => showFullScreenImageViewer(
                        context,
                        imagePath: path,
                        title: _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'সম্পদের ছবি',
                      ),
                      child: SafeImage(
                        source: path,
                        height: 120,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(10),
                        fallbackIcon: Icons.broken_image_outlined,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // ── Error Message ──
                  Obx(
                    () => controller.errorMessage.value != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              controller.errorMessage.value!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Submit Button ──
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('সম্পদ সংরক্ষণ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
