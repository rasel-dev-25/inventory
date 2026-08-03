import 'package:flutter/material.dart';

import '../tokens.dart';

/// The single confirmation dialog for every destructive action in the app.
///
/// The audit of the old app found a shared `confirm_dialog.dart` helper
/// that was built once and then called from nowhere — three separate
/// screens (investor, customers, quick capture) each hand-rolled their own
/// `AlertDialog`, and three more destructive actions (delete sale, delete
/// purchase/expense, delete asset) had no confirmation at all. This widget
/// is the only sanctioned way to confirm a destructive action from M1
/// onward; if a delete/cancel/reverse action doesn't go through
/// [AppConfirmDialog.show], that is a review-blocking defect.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
  });

  /// Shows the dialog and resolves to `true` only if the user tapped the
  /// confirm action. Any dismissal (back button, tap outside, cancel)
  /// resolves to `false`, never `null` — callers should not need a
  /// null-check before deciding whether to proceed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.only(
        right: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
