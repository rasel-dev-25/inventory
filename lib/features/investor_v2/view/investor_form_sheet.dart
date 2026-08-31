import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';

/// What [InvestorFormSheet] hands back on save.
class InvestorFormResult {
  final String name;
  final String? contact;
  final InvestmentType investmentType;
  final double profitSharePercent;
  final int? capitalReturnTermDays;
  final ProfitPayoutCycle profitPayoutCycle;
  final Money initialCashInvestment;
  final String? notes;
  final LegacySettlementFormResult? legacySettlement;

  const InvestorFormResult({
    required this.name,
    required this.investmentType,
    required this.profitSharePercent,
    required this.profitPayoutCycle,
    this.initialCashInvestment = Money.zeroBdt,
    this.contact,
    this.capitalReturnTermDays,
    this.notes,
    this.legacySettlement,
  });
}

/// The one-time §৬ fields, filled in only when the "has an old ledger-book
/// account?" toggle is on.
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

/// Create/edit form for a single [Investor].
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
  late final _cashInvestmentController = TextEditingController(
    text: widget.existing == null || widget.existing!.initialCashInvestment.isZero
        ? ''
        : widget.existing!.initialCashInvestment.format(showSymbol: false),
  );
  late final _profitShareController = TextEditingController(
    text: widget.existing?.profitSharePercent.toString() ?? '0',
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes,
  );

  int? _selectedTermDays;
  late final _termDaysController = TextEditingController();

  late InvestmentType _investmentType =
      widget.existing?.investmentType ?? InvestmentType.cashMudaraba;
  late ProfitPayoutCycle _profitPayoutCycle =
      widget.existing?.profitPayoutCycle ?? ProfitPayoutCycle.monthly;

  // ── Legacy Settlement (Old Ledger) State ──────────────────────────────────
  bool _hasLegacySettlement = false;
  final _legacyTotalController = TextEditingController();
  final _legacyReturnedController = TextEditingController(text: '0');
  final _legacyNotesController = TextEditingController();
  DateTime _legacySettlementDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedTermDays = widget.existing?.capitalReturnTermDays;
    _updateTermDaysText();
  }

  void _updateTermDaysText() {
    if (_selectedTermDays != null && _selectedTermDays! > 0) {
      final targetDate = DateTime.now().add(Duration(days: _selectedTermDays!));
      _termDaysController.text =
          '${DateFormat('dd MMM yyyy').format(targetDate)} ($_selectedTermDays ${'daysLater'.tr})';
    } else {
      _termDaysController.text = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _cashInvestmentController.dispose();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    final sheetDecoration = BoxDecoration(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: sheetDecoration,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Drag Handle ──────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),

                    // ── Title Bar ────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.existing == null ? 'addInvestor'.tr : 'editInvestor'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Investor Name ────────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '${'investorName'.tr} *',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'nameRequired'.tr : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Phone / Contact ──────────────────────────────────────
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'phone'.tr,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Cash Investment Amount (মূলধন গ্রহণ) ─────────────────
                    TextFormField(
                      controller: _cashInvestmentController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'cashInvestmentAmount'.tr,
                        prefixText: '৳ ',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calculate_outlined, size: 20),
                          tooltip: 'calculator'.tr,
                          onPressed: () async {
                            final res = await showCalculatorModal(
                              context,
                              initialValue: _cashInvestmentController.text,
                              title: 'cashInvestmentAmount'.tr,
                            );
                            if (res != null) {
                              _cashInvestmentController.text = res;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Investment Type ──────────────────────────────────────
                    DropdownButtonFormField<InvestmentType>(
                      initialValue: _investmentType,
                      decoration: InputDecoration(
                        labelText: 'investmentType'.tr,
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: InvestmentType.cashMudaraba,
                          child: Text('mudaraba'.tr),
                        ),
                        DropdownMenuItem(
                          value: InvestmentType.cashMusharaka,
                          child: Text('musharaka'.tr),
                        ),
                        DropdownMenuItem(
                          value: InvestmentType.cashLoan,
                          child: Text('cashLoan'.tr),
                        ),
                        DropdownMenuItem(
                          value: InvestmentType.goodsInKind,
                          child: Text('productConsignment'.tr),
                        ),
                      ],
                      onChanged: (v) => setState(() => _investmentType = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Profit Share (%) (if not cashLoan) ───────────────────
                    if (_investmentType != InvestmentType.cashLoan) ...[
                      TextFormField(
                        controller: _profitShareController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '${'profitShare'.tr} (%)',
                          prefixIcon: const Icon(Icons.percent_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calculate_outlined, size: 20),
                            tooltip: 'calculator'.tr,
                            onPressed: () async {
                              final res = await showCalculatorModal(
                                context,
                                initialValue: _profitShareController.text,
                                title: 'profitShare'.tr,
                                currencySymbol: '',
                                unitLabel: '%',
                              );
                              if (res != null) {
                                _profitShareController.text = res;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        validator: (v) =>
                            double.tryParse(v ?? '') == null ? 'invalidQty'.tr : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── Capital Return Date / Term ───────────────────────────
                    TextFormField(
                      controller: _termDaysController,
                      readOnly: true,
                      onTap: _pickCapitalReturnDate,
                      decoration: InputDecoration(
                        labelText: 'capitalReturnTermDays'.tr,
                        hintText: 'selectDateOptional'.tr,
                        prefixIcon: const Icon(Icons.event_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedTermDays != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedTermDays = null;
                                    _updateTermDaysText();
                                  });
                                },
                              ),
                            IconButton(
                              tooltip: 'date'.tr,
                              icon: const Icon(Icons.calendar_month_outlined),
                              onPressed: _pickCapitalReturnDate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Profit Payout Cycle ──────────────────────────────────
                    DropdownButtonFormField<ProfitPayoutCycle>(
                      initialValue: _profitPayoutCycle,
                      decoration: InputDecoration(
                        labelText: 'profitPayoutCycle'.tr,
                        prefixIcon: const Icon(Icons.repeat_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ProfitPayoutCycle.monthly,
                          child: Text('monthly'.tr),
                        ),
                        DropdownMenuItem(
                          value: ProfitPayoutCycle.daily,
                          child: Text('daily'.tr),
                        ),
                        DropdownMenuItem(
                          value: ProfitPayoutCycle.perContract,
                          child: Text('perContract'.tr),
                        ),
                      ],
                      onChanged: (v) => setState(() => _profitPayoutCycle = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Notes ────────────────────────────────────────────────
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr,
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),
                    ),

                    // ── Legacy Settlement (Old Ledger) Toggle ────────────────
                    if (widget.existing == null && widget.includeLegacySettlement) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _hasLegacySettlement
                              ? Colors.amber.withValues(alpha: 0.08)
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _hasLegacySettlement
                                ? Colors.amber.shade400
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'hasLegacySettlement'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              value: _hasLegacySettlement,
                              onChanged: (v) => setState(() => _hasLegacySettlement = v),
                            ),
                            if (_hasLegacySettlement) ...[
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'legacySettlementSectionTitle'.tr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _legacyTotalController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: '${'totalHistoricalInvestment'.tr} *',
                                  prefixText: '৳ ',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calculate_outlined, size: 20),
                                    onPressed: () async {
                                      final res = await showCalculatorModal(
                                        context,
                                        initialValue: _legacyTotalController.text,
                                        title: 'totalHistoricalInvestment'.tr,
                                      );
                                      if (res != null) {
                                        _legacyTotalController.text = res;
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                                validator: (v) => !_hasLegacySettlement
                                    ? null
                                    : (_parseMoneyOrNull(v ?? '') == null
                                        ? 'invalidQty'.tr
                                        : null),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _legacyReturnedController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'totalAlreadyReturned'.tr,
                                  prefixText: '৳ ',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calculate_outlined, size: 20),
                                    onPressed: () async {
                                      final res = await showCalculatorModal(
                                        context,
                                        initialValue: _legacyReturnedController.text,
                                        title: 'totalAlreadyReturned'.tr,
                                      );
                                      if (res != null) {
                                        _legacyReturnedController.text = res;
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                                validator: (v) => !_hasLegacySettlement
                                    ? null
                                    : (_parseMoneyOrNull(v ?? '') == null
                                        ? 'invalidQty'.tr
                                        : null),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.calendar_today_outlined, size: 20),
                                title: Text('settlementDate'.tr),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy').format(_legacySettlementDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: TextButton(
                                  onPressed: _pickSettlementDate,
                                  child: Text('selectDate'.tr),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _legacyNotesController,
                                decoration: InputDecoration(
                                  labelText: 'legacySettlementNotes'.tr,
                                  hintText: 'e.g. আব্বার খাতা পৃষ্ঠা ১২',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // ── Save Button ──────────────────────────────────────────
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          'save'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final initialDate = _selectedTermDays != null && _selectedTermDays! > 0
        ? today.add(Duration(days: _selectedTermDays!))
        : today.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? initialDate : today,
      firstDate: today,
      lastDate: DateTime(today.year + 20),
    );
    if (picked == null) return;
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(picked.year, picked.month, picked.day);
    final diffDays = end.difference(start).inDays;
    setState(() {
      _selectedTermDays = diffDays;
      _updateTermDaysText();
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
            : (double.tryParse(_profitShareController.text) ?? 0),
        initialCashInvestment: _parseMoneyOrNull(_cashInvestmentController.text) ?? Money.zeroBdt,
        capitalReturnTermDays: _selectedTermDays,
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

Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
