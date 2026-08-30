import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';

/// What [InvestorFormSheet] hands back on save — `InvestorScreen` decides
/// whether that means a create or an update, since only it knows whether
/// [InvestorFormSheet.existing] was passed. Same split of responsibility
/// as `ProductFormSheet`/`CustomerFormSheet`.
///
/// [legacySettlement] is only ever non-null on a *create* result (see
/// `InvestorFormSheet`'s "has an old ledger-book account?" toggle, which
/// this form only shows when [InvestorFormSheet.existing] is null) —
/// `InvestorScreen` creates the investor first, then, only if this is
/// set, creates the matching [LegacySettlement] against the new
/// investor's id.
class InvestorFormResult {
  final String name;
  final String? contact;
  final InvestmentType investmentType;
  final double profitSharePercent;
  final int? capitalReturnTermDays;
  final ProfitPayoutCycle profitPayoutCycle;
  final String? notes;
  final LegacySettlementFormResult? legacySettlement;

  const InvestorFormResult({
    required this.name,
    required this.investmentType,
    required this.profitSharePercent,
    required this.profitPayoutCycle,
    this.contact,
    this.capitalReturnTermDays,
    this.notes,
    this.legacySettlement,
  });
}

/// The one-time §৬ fields, filled in only when the "has an old ledger-book
/// account?" toggle is on. [netSettlementAmount] is deliberately absent
/// here — `LegacySettlementUseCases.create` always computes it itself
/// from these two amounts, never trusts a UI-computed value.
class LegacySettlementFormResult {
  final Money totalHistoricalInvestment;
  final Money totalAlreadyReturned;
  final DateTime settlementDate;
  final String? notes;

  const LegacySettlementFormResult({
    required this.totalHistoricalInvestment,
    required this.totalAlreadyReturned,
    required this.settlementDate,
    this.notes,
  });
}

/// Create/edit form for a single [Investor]. Pure form state — validation
/// and the actual create/update call both live in `InvestorController`,
/// this widget only ever returns an [InvestorFormResult] via
/// `Navigator.pop`.
class InvestorFormSheet extends StatefulWidget {
  final Investor? existing;
  final bool includeLegacySettlement;

  const InvestorFormSheet({
    super.key,
    this.existing,
    this.includeLegacySettlement = true,
  });

  @override
  State<InvestorFormSheet> createState() => _InvestorFormSheetState();
}

class _InvestorFormSheetState extends State<InvestorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name,
  );
  late final _contactController = TextEditingController(
    text: widget.existing?.contact,
  );
  late final _profitShareController = TextEditingController(
    text: widget.existing?.profitSharePercent.toString() ?? '0',
  );
  late final _termDaysController = TextEditingController(
    text: widget.existing?.capitalReturnTermDays?.toString(),
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes,
  );
  late InvestmentType _investmentType =
      widget.existing?.investmentType ?? InvestmentType.cashMudaraba;
  late ProfitPayoutCycle _profitPayoutCycle =
      widget.existing?.profitPayoutCycle ?? ProfitPayoutCycle.monthly;

  // ── business_logic.md §৬ — only ever shown/used when creating a brand
  // new investor (see the `if (widget.existing == null)` guard in build()
  // below); an already-existing investor already went through this
  // decision once, at their own creation time.
  bool _hasLegacySettlement = false;
  final _legacyTotalController = TextEditingController();
  final _legacyReturnedController = TextEditingController(text: '0');
  final _legacyNotesController = TextEditingController();
  DateTime _legacySettlementDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _profitShareController.dispose();
    _termDaysController.dispose();
    _notesController.dispose();
    _legacyTotalController.dispose();
    _legacyReturnedController.dispose();
    _legacyNotesController.dispose();
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
                widget.existing == null ? 'addInvestor'.tr : 'editInvestor'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'investorName'.tr),
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
              DropdownButtonFormField<InvestmentType>(
                initialValue: _investmentType,
                decoration: InputDecoration(labelText: 'investmentType'.tr),
                items: [
                  DropdownMenuItem(
                    value: InvestmentType.cashLoan,
                    child: Text('cashLoan'.tr),
                  ),
                  DropdownMenuItem(
                    value: InvestmentType.cashMudaraba,
                    child: Text('mudaraba'.tr),
                  ),
                  DropdownMenuItem(
                    value: InvestmentType.cashMusharaka,
                    child: Text('musharaka'.tr),
                  ),
                  DropdownMenuItem(
                    value: InvestmentType.goodsInKind,
                    child: Text('productConsignment'.tr),
                  ),
                ],
                onChanged: (v) => setState(() => _investmentType = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_investmentType != InvestmentType.cashLoan)
                TextFormField(
                  controller: _profitShareController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: 'profitShare'.tr),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'invalidQty'.tr : null,
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _termDaysController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'capitalReturnTermDays'.tr,
                  suffixIcon: IconButton(
                    tooltip: 'date'.tr,
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickCapitalReturnDate,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ProfitPayoutCycle>(
                initialValue: _profitPayoutCycle,
                decoration: InputDecoration(labelText: 'profitPayoutCycle'.tr),
                items: [
                  DropdownMenuItem(
                    value: ProfitPayoutCycle.daily,
                    child: Text('daily'.tr),
                  ),
                  DropdownMenuItem(
                    value: ProfitPayoutCycle.monthly,
                    child: Text('monthly'.tr),
                  ),
                  DropdownMenuItem(
                    value: ProfitPayoutCycle.perContract,
                    child: Text('perContract'.tr),
                  ),
                ],
                onChanged: (v) => setState(() => _profitPayoutCycle = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'notes'.tr),
              ),
              if (widget.existing == null &&
                  widget.includeLegacySettlement) ...[
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('hasLegacySettlement'.tr),
                  value: _hasLegacySettlement,
                  onChanged: (v) => setState(() => _hasLegacySettlement = v),
                ),
                if (_hasLegacySettlement) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'legacySettlementSectionTitle'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _legacyTotalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'totalHistoricalInvestment'.tr,
                    ),
                    validator: (v) => !_hasLegacySettlement
                        ? null
                        : (_parseMoneyOrNull(v ?? '') == null
                              ? 'invalidQty'.tr
                              : null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _legacyReturnedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'totalAlreadyReturned'.tr,
                    ),
                    validator: (v) => !_hasLegacySettlement
                        ? null
                        : (_parseMoneyOrNull(v ?? '') == null
                              ? 'invalidQty'.tr
                              : null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('settlementDate'.tr),
                    subtitle: Text(
                      _legacySettlementDate.toLocal().toString().split(' ')[0],
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickSettlementDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _legacyNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'legacySettlementNotes'.tr,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: Text('save'.tr)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSettlementDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _legacySettlementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _legacySettlementDate = picked);
    }
  }

  Future<void> _pickCapitalReturnDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(
        Duration(days: int.tryParse(_termDaysController.text) ?? 30),
      ),
      firstDate: today,
      lastDate: DateTime(today.year + 20),
    );
    if (picked == null) return;
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _termDaysController.text = end.difference(start).inDays.toString();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      InvestorFormResult(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        investmentType: _investmentType,
        profitSharePercent: _investmentType == InvestmentType.cashLoan
            ? 0
            : double.parse(_profitShareController.text),
        capitalReturnTermDays: int.tryParse(_termDaysController.text),
        profitPayoutCycle: _profitPayoutCycle,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        legacySettlement: !_hasLegacySettlement
            ? null
            : LegacySettlementFormResult(
                totalHistoricalInvestment: _parseMoneyOrNull(
                  _legacyTotalController.text,
                )!,
                totalAlreadyReturned:
                    _parseMoneyOrNull(_legacyReturnedController.text) ??
                    Money.zero(),
                settlementDate: _legacySettlementDate,
                notes: _legacyNotesController.text.trim().isEmpty
                    ? null
                    : _legacyNotesController.text.trim(),
              ),
      ),
    );
  }
}

/// Same pattern as every other live-input `Money` field in the app —
/// `Money` has no `tryParse`, see `daily_sales_v2`'s doc comment for why
/// every screen wraps `Money.parse` like this.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
