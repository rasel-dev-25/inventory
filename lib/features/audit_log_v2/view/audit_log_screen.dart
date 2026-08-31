import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../data/local/app_database.dart';
import '../controller/audit_log_controller.dart';

/// Clean, simple, and beautifully organized Audit Log screen.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final controller = Get.find<AuditLogController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('auditLogTitle'.tr),
        actions: [
          Obx(() {
            final hasFilter = controller.selectedEntity.value != 'all' ||
                controller.selectedAction.value != 'all' ||
                controller.searchQuery.value.isNotEmpty;
            if (!hasFilter) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () {
                _searchController.clear();
                controller.resetFilters();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text('auditFilterAll'.tr),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Header ─────────────────────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'auditSearchHint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                            },
                          )
                        : const SizedBox.shrink()),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  onChanged: controller.setSearchQuery,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Unified Filter Row: Action Badges + Entity Types
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Action Chips
                      _buildActionPills(theme),
                      Container(
                        height: 20,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: theme.colorScheme.outlineVariant,
                      ),
                      // Entity Chips
                      _buildEntityPills(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Timeline List of Audit Entries ─────────────────────────────────
          Expanded(
            child: Obx(() {
              final entries = controller.filteredEntries;
              if (entries.isEmpty) {
                return _buildEmptyState(theme);
              }

              final groups = _groupEntriesByDate(entries);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupKey = groups.keys.elementAt(index);
                  final groupEntries = groups[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Row(
                          children: [
                            Text(
                              groupKey,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '${groupEntries.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Entries in this date group
                      ...groupEntries.map((e) => _CleanAuditCard(entry: e)),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPills(ThemeData theme) {
    return Obx(() {
      final selected = controller.selectedAction.value;
      final actions = [
        {'key': 'all', 'label': 'auditFilterAll'.tr, 'icon': Icons.tune_rounded},
        {'key': 'delete', 'label': 'auditActionDelete'.tr, 'color': Colors.red.shade700},
        {'key': 'update', 'label': 'auditActionUpdate'.tr, 'color': Colors.orange.shade800},
        {'key': 'insert', 'label': 'auditActionInsert'.tr, 'color': Colors.green.shade700},
        {'key': 'restore', 'label': 'auditActionRestore'.tr, 'color': Colors.blue.shade700},
      ];

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((act) {
          final isSelected = selected == act['key'];
          final color = (act['color'] as Color?) ?? theme.colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(act['label'] as String),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: color.withValues(alpha: 0.15),
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => controller.setActionFilter(act['key'] as String),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildEntityPills(ThemeData theme) {
    final entities = [
      {'key': 'customers', 'label': 'auditFilterCustomers'.tr, 'icon': Icons.people_outline_rounded},
      {'key': 'products', 'label': 'auditFilterProducts'.tr, 'icon': Icons.inventory_2_outlined},
      {'key': 'sales', 'label': 'auditFilterSales'.tr, 'icon': Icons.point_of_sale_rounded},
      {'key': 'purchase_trips', 'label': 'auditFilterPurchases'.tr, 'icon': Icons.local_shipping_outlined},
      {'key': 'expenses', 'label': 'auditFilterExpenses'.tr, 'icon': Icons.payments_outlined},
      {'key': 'fixed_assets', 'label': 'auditFilterFixedAssets'.tr, 'icon': Icons.apartment_rounded},
      {'key': 'orders', 'label': 'auditFilterOrders'.tr, 'icon': Icons.shopping_bag_outlined},
      {'key': 'dues', 'label': 'auditFilterDues'.tr, 'icon': Icons.assignment_late_outlined},
      {'key': 'rent_transactions', 'label': 'auditFilterRent'.tr, 'icon': Icons.menu_book_rounded},
    ];

    return Obx(() {
      final selected = controller.selectedEntity.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: entities.map((item) {
          final isSelected = selected.toLowerCase() == item['key']!.toString().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              avatar: Icon(
                item['icon'] as IconData,
                size: 14,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(item['label'] as String),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (val) {
                controller.setEntityFilter(val ? item['key'] as String : 'all');
              },
            ),
          );
        }).toList(),
      );
    });
  }

  Map<String, List<AuditLogEntryRow>> _groupEntriesByDate(List<AuditLogEntryRow> entries) {
    final groups = <String, List<AuditLogEntryRow>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final entryDate = entry.timestamp.toLocal();
      final dateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);

      String header;
      if (dateOnly == today) {
        header = 'আজ (Today)';
      } else if (dateOnly == yesterday) {
        header = 'গতকাল (Yesterday)';
      } else {
        header = DateFormat('dd MMMM yyyy').format(entryDate);
      }

      groups.putIfAbsent(header, () => []).add(entry);
    }
    return groups;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              controller.searchQuery.value.isNotEmpty ||
                      controller.selectedEntity.value != 'all' ||
                      controller.selectedAction.value != 'all'
                  ? 'noMatchingAuditLogEntries'.tr
                  : 'noAuditLogEntries'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                controller.resetFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('auditFilterAll'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sleek, modern, uncluttered card for a single audit log row.
class _CleanAuditCard extends StatefulWidget {
  final AuditLogEntryRow entry;
  const _CleanAuditCard({required this.entry});

  @override
  State<_CleanAuditCard> createState() => _CleanAuditCardState();
}

class _CleanAuditCardState extends State<_CleanAuditCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final actionConfig = _getActionConfig(entry.action);
    final entityConfig = _getEntityConfig(entry.changedTableName);
    final parsedOld = _parseJson(entry.oldValueJson);
    final parsedNew = _parseJson(entry.newValueJson);
    final entityTitle = _extractTitle(parsedOld ?? parsedNew);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Card Header ───────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  // Action Icon Container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: actionConfig.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(actionConfig.icon, color: actionConfig.color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Title, Entity & Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Action Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: actionConfig.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                actionConfig.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: actionConfig.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Entity Name / Title
                            Expanded(
                              child: Text(
                                entityTitle.isNotEmpty ? entityTitle : entityConfig.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(entityConfig.icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              entityConfig.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              ' • ${_formatTime(entry.timestamp)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand Indicator
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: theme.colorScheme.outline,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Content (Clean Diff & Details) ────────────────────────
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.md)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Record ID & Copy
                  Row(
                    children: [
                      Text(
                        'ID: ',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          entry.recordId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: entry.recordId));
                          Get.snackbar(
                            'auditCopyId'.tr,
                            'auditCopied'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(Icons.copy_rounded, size: 14, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Content Diff for Updates OR Key-Value for Insert/Delete
                  if (entry.action == 'update' && parsedOld != null && parsedNew != null)
                    _buildCleanUpdateDiff(theme, parsedOld, parsedNew)
                  else if (parsedOld != null || parsedNew != null)
                    _buildCleanKeyValues(theme, (parsedNew ?? parsedOld)!),

                  const SizedBox(height: AppSpacing.sm),

                  // Minimal Raw JSON Accordion
                  _buildMinimalRawJson(theme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanUpdateDiff(ThemeData theme, Map<String, dynamic> oldMap, Map<String, dynamic> newMap) {
    final changedKeys = <String>[];
    final allKeys = {...oldMap.keys, ...newMap.keys};

    for (final key in allKeys) {
      if (key == 'updated_at' || key == 'synced_at' || key == 'created_at') continue;
      final oldVal = oldMap[key]?.toString();
      final newVal = newMap[key]?.toString();
      if (oldVal != newVal) {
        changedKeys.add(key);
      }
    }

    if (changedKeys.isEmpty) {
      return _buildCleanKeyValues(theme, newMap);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.change_circle_outlined, size: 15, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                'auditChangedFields'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...changedKeys.map((k) {
            final oldVal = oldMap[k]?.toString() ?? '-';
            final newVal = newMap[k]?.toString() ?? '-';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      _translateKey(k),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          oldVal,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.grey),
                        ),
                        Text(
                          newVal,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCleanKeyValues(ThemeData theme, Map<String, dynamic> map) {
    final visibleEntries = map.entries.where((e) {
      final k = e.key.toLowerCase();
      if (k == 'id' || k == 'shop_id' || k == 'created_at' || k == 'updated_at' || k == 'synced_at') {
        return false;
      }
      return e.value != null;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: visibleEntries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    _translateKey(e.key),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMinimalRawJson(ThemeData theme) {
    final rawText = widget.entry.newValueJson ?? widget.entry.oldValueJson ?? '{}';

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        'auditRawJson'.tr,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.outline,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SelectableText(
            rawText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _parseJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractTitle(Map<String, dynamic>? map) {
    if (map == null) return '';
    final name = map['name'] ?? map['title'] ?? map['item_name'] ?? map['description'];
    if (name != null && name.toString().isNotEmpty) {
      return name.toString();
    }
    final invoice = map['invoice_no'] ?? map['trip_number'];
    if (invoice != null) {
      return '#$invoice';
    }
    final amount = map['amount'] ?? map['total_amount'] ?? map['total'];
    if (amount != null) {
      return '৳$amount';
    }
    return '';
  }

  String _translateKey(String key) {
    final k = key.toLowerCase();
    switch (k) {
      case 'name':
      case 'title':
        return 'নাম:';
      case 'contact':
      case 'phone':
        return 'মোবাইল:';
      case 'address':
        return 'ঠিকানা:';
      case 'selling_price':
      case 'sell_price':
        return 'বিক্রয় মূল্য:';
      case 'cost_price':
      case 'purchase_price':
        return 'ক্রয় মূল্য:';
      case 'stock_qty':
      case 'quantity':
      case 'qty':
        return 'স্টক:';
      case 'category':
      case 'category_name':
        return 'ক্যাটাগরি:';
      case 'amount':
      case 'total_amount':
      case 'total':
        return 'টাকা:';
      case 'memo':
      case 'note':
      case 'notes':
        return 'নোট:';
      case 'status':
        return 'স্ট্যাটাস:';
      case 'deposit':
      case 'deposit_amount':
        return 'জামানত:';
      case 'rent_charge':
        return 'ভাড়া:';
      case 'payment_method':
        return 'মাধ্যম:';
      case 'suspicion_flag':
        return 'সন্দেহজনক:';
      case 'is_blocked':
        return 'ব্লকড:';
      default:
        return '$key:';
    }
  }

  ({String label, IconData icon, Color color}) _getActionConfig(String action) {
    final act = action.toLowerCase();
    if (act == 'delete' || act == 'trash') {
      return (
        label: 'auditActionDelete'.tr,
        icon: Icons.delete_outline_rounded,
        color: Colors.red.shade700,
      );
    }
    if (act == 'restore') {
      return (
        label: 'auditActionRestore'.tr,
        icon: Icons.restore_rounded,
        color: Colors.blue.shade700,
      );
    }
    if (act == 'update' || act == 'edit') {
      return (
        label: 'auditActionUpdate'.tr,
        icon: Icons.edit_outlined,
        color: Colors.orange.shade800,
      );
    }
    return (
      label: 'auditActionInsert'.tr,
      icon: Icons.add_circle_outline_rounded,
      color: Colors.green.shade700,
    );
  }

  ({String label, IconData icon}) _getEntityConfig(String table) {
    final t = table.toLowerCase();
    if (t.contains('customer')) {
      return (label: 'auditFilterCustomers'.tr, icon: Icons.people_outline_rounded);
    }
    if (t.contains('product')) {
      return (label: 'auditFilterProducts'.tr, icon: Icons.inventory_2_outlined);
    }
    if (t.contains('sale')) {
      return (label: 'auditFilterSales'.tr, icon: Icons.point_of_sale_rounded);
    }
    if (t.contains('purchase')) {
      return (label: 'auditFilterPurchases'.tr, icon: Icons.local_shipping_outlined);
    }
    if (t.contains('expense')) {
      return (label: 'auditFilterExpenses'.tr, icon: Icons.payments_outlined);
    }
    if (t.contains('asset')) {
      return (label: 'auditFilterFixedAssets'.tr, icon: Icons.apartment_rounded);
    }
    if (t.contains('order')) {
      return (label: 'auditFilterOrders'.tr, icon: Icons.shopping_bag_outlined);
    }
    if (t.contains('due')) {
      return (label: 'auditFilterDues'.tr, icon: Icons.assignment_late_outlined);
    }
    if (t.contains('rent')) {
      return (label: 'auditFilterRent'.tr, icon: Icons.menu_book_rounded);
    }
    return (label: table, icon: Icons.table_chart_outlined);
  }

  String _formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt.toLocal());
  }
}
