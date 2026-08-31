import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/notification_bell_action.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/shop_app_bar_title.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/quick_capture.dart';
import '../controller/quick_capture_controller.dart';

/// The v2 Quick Capture screen — jot now, formalize later, per
/// `notes/business_logic.md`'s QuickCapture addition, backed by
/// [QuickCaptureController].
class QuickCaptureScreen extends GetView<QuickCaptureController> {
  const QuickCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShopAppBarTitle(pageTitle: 'quickCaptures'.tr),
        actions: const [
          NotificationBellAction(),
          SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final pending = controller.pending;
        final converted = controller.converted;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('pending'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('noPendingCaptures'.tr),
              )
            else
              for (final capture in pending) _PendingCard(capture: capture),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'converted'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (converted.isEmpty)
              Text('noConvertedCaptures'.tr)
            else
              for (final capture in converted) _ConvertedRow(capture: capture),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'quick_capture_fab',
        onPressed: () => _openCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    QuickCaptureType type = QuickCaptureType.voiceNote;
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? photoPath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('quickCaptures'.tr),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<QuickCaptureType>(
                      segments: [
                        ButtonSegment(
                          value: QuickCaptureType.voiceNote,
                          label: Text('voiceNote'.tr),
                        ),
                        ButtonSegment(
                          value: QuickCaptureType.photoNote,
                          label: Text('photoNote'.tr),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setState(() => type = s.first),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (type == QuickCaptureType.photoNote) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = await controller.capturePhoto();
                          if (path != null && dialogContext.mounted) {
                            setState(() => photoPath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text('takePhoto'.tr),
                      ),
                      if (photoPath != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () => showFullScreenImageViewer(
                            context,
                            imagePath: photoPath!,
                            title: 'photoPreview'.tr,
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              SafeImage(
                                source: photoPath!,
                                height: 140,
                                width: double.infinity,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                fallbackIcon: Icons.photo_camera_outlined,
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
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextFormField(
                      controller: noteController,
                      autofocus: type == QuickCaptureType.voiceNote,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'writeQuickNote'.tr,
                      ),
                      validator: (v) =>
                          type == QuickCaptureType.photoNote &&
                              (photoPath == null &&
                                  (v == null || v.trim().isEmpty))
                          ? 'takePhoto'.tr
                          : type == QuickCaptureType.voiceNote &&
                                (v == null || v.trim().isEmpty)
                          ? 'nameRequired'.tr
                          : null,
                    ),
                    Obx(() {
                      final error = controller.errorMessage.value;
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.createCapture(
                      type: type,
                      note: noteController.text,
                      fileLocalPath: photoPath,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PendingCard extends GetView<QuickCaptureController> {
  final QuickCapture capture;
  const _PendingCard({required this.capture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photo = capture.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();
    final noteText = capture.note;
    final displayTitle = noteText.isNotEmpty
        ? noteText
        : (capture.type == QuickCaptureType.photoNote ? 'photoNote'.tr : 'voiceNote'.tr);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  capture.type == QuickCaptureType.voiceNote
                      ? Icons.mic
                      : Icons.photo_camera,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    displayTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(capture.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (hasPhoto) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => showFullScreenImageViewer(
                  context,
                  imagePath: photo,
                  title: displayTitle,
                  subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(capture.createdAt.toLocal()),
                  heroTag: 'quick_capture_pending_${capture.id}',
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Hero(
                      tag: 'quick_capture_pending_${capture.id}',
                      child: SafeImage(
                        source: photo,
                        height: 180,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        fallbackIcon: Icons.photo_camera_outlined,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'fullView'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('সম্পাদনা', style: TextStyle(fontSize: 12)),
                  onPressed: () => _openEditSheet(context),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('মুছুন', style: TextStyle(fontSize: 12)),
                  onPressed: () => _confirmDelete(context),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.transform, size: 16),
                  onPressed: () => _openConvertChoice(context),
                  label: Text('convertTo'.tr, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final noteController = TextEditingController(text: capture.note);
    final formKey = GlobalKey<FormState>();
    String? photoPath = capture.photoPath;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
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
                                'নোট সম্পাদনা',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'নোটের বিবরণ',
                              hintText: 'এখানে লিখুন...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) &&
                                    (photoPath == null || photoPath!.isEmpty)
                                ? 'কিছু লিখুন অথবা ছবি সংযুক্ত করুন'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final path = await controller.capturePhoto();
                                  if (path != null) {
                                    setState(() => photoPath = path);
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: Text(photoPath == null ? 'ছবি তুলুন' : 'ছবি পরিবর্তন'),
                              ),
                              if (photoPath != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                                  tooltip: 'ছবি মুছুন',
                                  onPressed: () => setState(() => photoPath = null),
                                ),
                              ],
                            ],
                          ),
                          if (photoPath != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            SafeImage(
                              source: photoPath!,
                              height: 120,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(10),
                              fallbackIcon: Icons.photo_camera_outlined,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final ok = await controller.updateCapture(
                                id: capture.id,
                                note: noteController.text.trim(),
                                fileLocalPath: photoPath,
                              );
                              if (ok && sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                                Get.snackbar(
                                  'নোট আপডেট হয়েছে',
                                  'দ্রুত নোটটি সফলভাবে আপডেট করা হয়েছে।',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('আপডেট সংরক্ষণ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নোট মুছে ফেলবেন?'),
        content: Text(
          capture.note.isNotEmpty
              ? 'আপনি কি নিশ্চিত যে "${capture.note}" নোটটি মুছে ফেলতে চান?'
              : 'আপনি কি নিশ্চিত এই নোটটি মুছে ফেলতে চান?',
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
      final success = await controller.deleteCapture(capture.id);
      if (success) {
        Get.snackbar(
          'নোট মুছে ফেলা হয়েছে',
          'দ্রুত নোটটি সফলভাবে মুছে ফেলা হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _openConvertChoice(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: Text('dailySales'.tr),
              onTap: () => Navigator.of(context).pop('sale'),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text('purchaseEntry'.tr),
              onTap: () => Navigator.of(context).pop('purchase'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('expenses'.tr),
              onTap: () => Navigator.of(context).pop('expense'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'sale':
        await _openSaleForm(context);
      case 'purchase':
        await _openPurchaseForm(context);
      case 'expense':
        await _openExpenseForm(context);
    }
  }

  Future<void> _openExpenseForm(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: capture.note,
    );
    ExpenseCategory category = ExpenseCategory.dailyOther;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('addExpense'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<ExpenseCategory>(
                        segments: [
                          ButtonSegment(
                            value: ExpenseCategory.monthlyRent,
                            label: Text('monthlyRent'.tr),
                          ),
                          ButtonSegment(
                            value: ExpenseCategory.dailyOther,
                            label: Text('dailyOther'.tr),
                          ),
                        ],
                        selected: {category},
                        onSelectionChanged: (s) =>
                            setState(() => category = s.first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: amountController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'amount'.tr,
                          prefixText: '৳ ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calculate_outlined, size: 20),
                            tooltip: 'calculator'.tr,
                            onPressed: () async {
                              final res = await showCalculatorModal(
                                context,
                                initialValue: amountController.text,
                                title: 'amount'.tr,
                              );
                              if (res != null) {
                                amountController.text = res;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        validator: (v) => _parseMoneyOrNull(v ?? '') == null
                            ? 'invalidQty'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'description'.tr,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<PaymentMethod>(
                        segments: [
                          ButtonSegment(
                            value: PaymentMethod.cash,
                            label: Text('cash'.tr),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.mobileBanking,
                            label: Text('mobile'.tr),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.bankTransfer,
                            label: Text('bank'.tr),
                          ),
                        ],
                        selected: {method},
                        onSelectionChanged: (s) =>
                            setState(() => method = s.first),
                      ),
                      Obx(
                        () => controller.errorMessage.value == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  controller.errorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToExpense(
                      captureId: capture.id,
                      category: category,
                      amount: _parseMoneyOrNull(amountController.text)!,
                      paymentMethod: method,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSaleForm(BuildContext context) async {
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final receivedController = TextEditingController();
    String? customerId;
    PaymentMethod method = PaymentMethod.cash;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('dailySales'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: productId,
                          decoration: InputDecoration(
                            labelText: 'selectProduct'.tr,
                          ),
                          items: [
                            for (final p in controller.products)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            productId = v;
                            final product = controller.productById(v ?? '');
                            if (product != null &&
                                priceController.text.isEmpty) {
                              priceController.text = product.suggestedSellPrice
                                  .format(showSymbol: false);
                            }
                          }),
                          validator: (v) =>
                              v == null ? 'selectProduct'.tr : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'qty'.tr,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calculate_outlined, size: 20),
                                  tooltip: 'calculator'.tr,
                                  onPressed: () async {
                                    final res = await showCalculatorModal(
                                      context,
                                      initialValue: qtyController.text,
                                      title: 'qty'.tr,
                                      currencySymbol: '',
                                    );
                                    if (res != null) {
                                      qtyController.text = res;
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'sellPriceLabel'.tr,
                                prefixText: '৳ ',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calculate_outlined, size: 20),
                                  tooltip: 'calculator'.tr,
                                  onPressed: () async {
                                    final res = await showCalculatorModal(
                                      context,
                                      initialValue: priceController.text,
                                      title: 'sellPriceLabel'.tr,
                                    );
                                    if (res != null) {
                                      priceController.text = res;
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              validator: (v) =>
                                  _parseMoneyOrNull(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: receivedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'cashAmount'.tr,
                          prefixText: '৳ ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calculate_outlined, size: 20),
                            tooltip: 'calculator'.tr,
                            onPressed: () async {
                              final res = await showCalculatorModal(
                                context,
                                initialValue: receivedController.text,
                                title: 'cashAmount'.tr,
                              );
                              if (res != null) {
                                receivedController.text = res;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: customerId,
                          decoration: InputDecoration(
                            labelText: 'customerName'.tr,
                          ),
                          items: [
                            for (final c in controller.customers)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => customerId = v),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<PaymentMethod>(
                        segments: [
                          ButtonSegment(
                            value: PaymentMethod.cash,
                            label: Text('cash'.tr),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.mobileBanking,
                            label: Text('mobile'.tr),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.bankTransfer,
                            label: Text('bank'.tr),
                          ),
                        ],
                        selected: {method},
                        onSelectionChanged: (s) =>
                            setState(() => method = s.first),
                      ),
                      Obx(
                        () => controller.errorMessage.value == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  controller.errorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToSale(
                      captureId: capture.id,
                      productId: productId!,
                      qty: double.parse(qtyController.text),
                      actualSellPrice: _parseMoneyOrNull(priceController.text)!,
                      amountReceivedNow:
                          _parseMoneyOrNull(receivedController.text) ??
                          Money.zero(),
                      paymentMethod: method,
                      customerId: customerId,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openPurchaseForm(BuildContext context) async {
    final shopNameController = TextEditingController();
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    bool fundedByInvestor = false;
    String? investorId;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('purchaseEntry'.tr),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: shopNameController,
                        decoration: InputDecoration(
                          labelText: 'shopNameLabel'.tr,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'nameRequired'.tr
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: productId,
                          decoration: InputDecoration(
                            labelText: 'selectProduct'.tr,
                          ),
                          items: [
                            for (final p in controller.products)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => productId = v),
                          validator: (v) =>
                              v == null ? 'selectProduct'.tr : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'qty'.tr,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calculate_outlined, size: 20),
                                  tooltip: 'calculator'.tr,
                                  onPressed: () async {
                                    final res = await showCalculatorModal(
                                      context,
                                      initialValue: qtyController.text,
                                      title: 'qty'.tr,
                                      currencySymbol: '',
                                    );
                                    if (res != null) {
                                      qtyController.text = res;
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'buyPricePer'.tr,
                                prefixText: '৳ ',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calculate_outlined, size: 20),
                                  tooltip: 'calculator'.tr,
                                  onPressed: () async {
                                    final res = await showCalculatorModal(
                                      context,
                                      initialValue: priceController.text,
                                      title: 'buyPricePer'.tr,
                                    );
                                    if (res != null) {
                                      priceController.text = res;
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              validator: (v) =>
                                  _parseMoneyOrNull(v ?? '') == null
                                  ? 'invalidQty'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('fundedByInvestor'.tr),
                        value: fundedByInvestor,
                        onChanged: (v) => setState(() => fundedByInvestor = v),
                      ),
                      if (fundedByInvestor)
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: investorId,
                            decoration: InputDecoration(
                              labelText: 'selectInvestor'.tr,
                            ),
                            items: [
                              for (final i in controller.investors)
                                DropdownMenuItem(
                                  value: i.id,
                                  child: Text(i.name),
                                ),
                            ],
                            onChanged: (v) => setState(() => investorId = v),
                            validator: (v) => (fundedByInvestor && v == null)
                                ? 'nameRequired'.tr
                                : null,
                          ),
                        ),
                      Obx(
                        () => controller.errorMessage.value == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  controller.errorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.convertToPurchase(
                      captureId: capture.id,
                      shopName: shopNameController.text.trim(),
                      productId: productId!,
                      qty: double.parse(qtyController.text),
                      unitPrice: _parseMoneyOrNull(priceController.text)!,
                      fundSource: fundedByInvestor
                          ? FundSource.investor(investorId!)
                          : FundSource.shop(),
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ConvertedRow extends StatelessWidget {
  final QuickCapture capture;
  const _ConvertedRow({required this.capture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photo = capture.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();
    final noteText = capture.note;
    final displayTitle = noteText.isNotEmpty
        ? noteText
        : (capture.type == QuickCaptureType.photoNote ? 'photoNote'.tr : 'voiceNote'.tr);

    String convertedLabel = 'converted'.tr;
    if (capture.convertedToType != null) {
      if (capture.convertedToType == 'sale') convertedLabel = 'dailySales'.tr;
      if (capture.convertedToType == 'purchase') convertedLabel = 'purchaseEntry'.tr;
      if (capture.convertedToType == 'expense') convertedLabel = 'expenses'.tr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        dense: true,
        leading: hasPhoto
            ? GestureDetector(
                onTap: () => showFullScreenImageViewer(
                  context,
                  imagePath: photo,
                  title: displayTitle,
                  subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(capture.createdAt.toLocal()),
                  heroTag: 'quick_capture_conv_${capture.id}',
                ),
                child: Hero(
                  tag: 'quick_capture_conv_${capture.id}',
                  child: SafeImage(
                    source: photo,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    fallbackIcon: Icons.photo_camera_outlined,
                  ),
                ),
              )
            : CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  capture.type == QuickCaptureType.voiceNote
                      ? Icons.mic
                      : Icons.photo_camera,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
        title: Text(
          displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(capture.createdAt.toLocal()),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                convertedLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade500),
              tooltip: 'মুছুন',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = Get.find<QuickCaptureController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নোট মুছে ফেলবেন?'),
        content: Text(
          capture.note.isNotEmpty
              ? 'আপনি কি নিশ্চিত যে "${capture.note}" নোটটি মুছে ফেলতে চান?'
              : 'আপনি কি নিশ্চিত এই নোটটি মুছে ফেলতে চান?',
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
      final success = await controller.deleteCapture(capture.id);
      if (success) {
        Get.snackbar(
          'নোট মুছে ফেলা হয়েছে',
          'নোটটি সফলভাবে মুছে ফেলা হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

/// Same pattern as every other v2 form field — `Money` has no `tryParse`,
/// see `daily_sales_v2`'s doc comment for why every live-input field
/// wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
