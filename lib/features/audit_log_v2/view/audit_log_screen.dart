import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../data/local/app_database.dart';
import '../controller/audit_log_controller.dart';

/// The v2 Audit Log screen — read-only, per `AuditLogController`'s own
/// doc comment on exactly which actions are recorded today.
class AuditLogScreen extends GetView<AuditLogController> {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auditLogTitle'.tr)),
      body: Obx(() {
        final entries = controller.entries;
        if (entries.isEmpty) {
          return Center(child: Text('noAuditLogEntries'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: entries.length,
          itemBuilder: (context, index) => _AuditEntryCard(entries[index]),
        );
      }),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  final AuditLogEntryRow entry;
  const _AuditEntryCard(this.entry);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        leading: Icon(_iconFor(entry.action)),
        title: Text(
          '${_actionLabel(entry.action)} · ${entry.changedTableName}',
        ),
        subtitle: Text(_formatTimestamp(entry.timestamp)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'recordIdLabel'.tr}${entry.recordId}',
                  style: theme.textTheme.bodySmall,
                ),
                if (entry.oldValueJson != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('oldValueLabel'.tr, style: theme.textTheme.labelMedium),
                  Text(entry.oldValueJson!, style: theme.textTheme.bodySmall),
                ],
                if (entry.newValueJson != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('newValueLabel'.tr, style: theme.textTheme.labelMedium),
                  Text(entry.newValueJson!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'delete':
        return Icons.delete_outline;
      case 'restore':
        return Icons.restore;
      case 'update':
        return Icons.edit_outlined;
      default:
        return Icons.add_circle_outline;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'delete':
        return 'auditActionDelete'.tr;
      case 'restore':
        return 'auditActionRestore'.tr;
      case 'update':
        return 'auditActionUpdate'.tr;
      default:
        return 'auditActionInsert'.tr;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
