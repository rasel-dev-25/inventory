import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design/tokens.dart';
import '../../../../domain/entities/customer.dart';
import '../../controller/daily_sales_controller.dart';

/// Rich, professional customer selector for sale sheets:
/// - Supports selecting an existing customer with live dues tag
/// - Quick "+ New Customer" inline creation without leaving the sale screen
/// - Warns if selected customer has previous unpaid dues or is blocked/suspicious
class SaleCustomerSection extends StatefulWidget {
  final DailySalesController controller;
  final String? selectedCustomerId;
  final bool isRequired;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onClearFocus;

  const SaleCustomerSection({
    required this.controller,
    required this.selectedCustomerId,
    required this.isRequired,
    required this.onCustomerChanged,
    required this.onClearFocus,
    super.key,
  });

  @override
  State<SaleCustomerSection> createState() => _SaleCustomerSectionState();
}

class _SaleCustomerSectionState extends State<SaleCustomerSection> {
  bool _isAddingNew = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _quickFormKey = GlobalKey<FormState>();
  bool _isSavingQuick = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveQuickCustomer() async {
    if (!_quickFormKey.currentState!.validate()) return;
    setState(() => _isSavingQuick = true);
    final created = await widget.controller.createQuickCustomer(
      name: _nameCtrl.text,
      contact: _phoneCtrl.text,
      address: _addressCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSavingQuick = false);
    if (created != null) {
      widget.onCustomerChanged(created.id);
      setState(() {
        _isAddingNew = false;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _addressCtrl.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('customerCreated'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCustomer = widget.selectedCustomerId == null
        ? null
        : widget.controller.customerById(widget.selectedCustomerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header & Action Row ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: widget.isRequired
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isRequired
                      ? 'selectCustomerRequired'.tr
                      : 'selectCustomerOptional'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.isRequired ? theme.colorScheme.primary : null,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (selectedCustomer == null && !_isAddingNew)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: Text('addNewCustomer'.tr),
                onPressed: () {
                  widget.onClearFocus();
                  setState(() => _isAddingNew = true);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── Quick Add Customer Inline Form ───────────────────────────────
        if (_isAddingNew)
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _quickFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'quickAddCustomer'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _isAddingNew = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${'customerName'.tr} *',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'nameRequired'.tr
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'phoneOrMobile'.tr,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'address'.tr,
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isAddingNew = false),
                          child: Text('cancel'.tr),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: _isSavingQuick ? null : _saveQuickCustomer,
                          child: _isSavingQuick
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('save'.tr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        // ── Selected Customer Card with Due Warning ───────────────────────
        else if (selectedCustomer != null)
          _buildSelectedCustomerCard(context, selectedCustomer)
        // ── Dropdown / Autocomplete to Select Existing Customer ───────────
        else
          Obx(() {
            final customersList = widget.controller.customers;
            final bool hasMatch =
                widget.selectedCustomerId != null &&
                customersList.any((c) => c.id == widget.selectedCustomerId);
            final String? safeValue = hasMatch
                ? widget.selectedCustomerId
                : null;

            return DropdownButtonFormField<String>(
              key: ValueKey(safeValue),
              initialValue: safeValue,
              decoration: InputDecoration(
                hintText: 'selectCustomer'.tr,
                prefixIcon: const Icon(Icons.people_outline, size: 20),
                isDense: true,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    widget.isRequired ? 'selectCustomer'.tr : 'none'.tr,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                for (final c in customersList)
                  DropdownMenuItem<String>(
                    value: c.id,
                    child: _customerDropdownItem(c),
                  ),
              ],
              onChanged: (v) {
                widget.onClearFocus();
                widget.onCustomerChanged(v);
              },
              validator: (v) => (widget.isRequired && (v == null || v.isEmpty))
                  ? 'customerRequiredForDue'.tr
                  : null,
            );
          }),
      ],
    );
  }

  Widget _customerDropdownItem(Customer c) {
    final prevDue = widget.controller.outstandingDueForCustomer(c.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            c.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (c.contact != null && c.contact!.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            '(${c.contact})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        if (prevDue.isPositive) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              '${'dueLabel'.tr}: ${prevDue.format()}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedCustomerCard(BuildContext context, Customer c) {
    final theme = Theme.of(context);
    final prevDue = widget.controller.outstandingDueForCustomer(c.id);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: prevDue.isPositive
              ? Colors.orange.shade300
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    c.name.trim().isEmpty
                        ? '?'
                        : c.name.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (c.contact != null && c.contact!.isNotEmpty)
                        Text(
                          c.contact!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'clearSelection'.tr,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => widget.onCustomerChanged(null),
                ),
              ],
            ),

            // ⚠️ Outstanding Previous Due Warning Alert
            if (prevDue.isPositive) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'customerPreviousDueWarning'.tr}: ${prevDue.format()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
