import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/investor.dart';

/// What [InvestorFormSheet] hands back on save — `InvestorScreen` decides
/// whether that means a create or an update, since only it knows whether
/// [InvestorFormSheet.existing] was passed. Same split of responsibility
/// as `ProductFormSheet`/`CustomerFormSheet`.
class InvestorFormResult {
  final String name;
  final String? contact;
  final InvestmentType investmentType;
  final double profitSharePercent;
  final int? capitalReturnTermDays;
  final ProfitPayoutCycle profitPayoutCycle;
  final String? notes;

  const InvestorFormResult({
    required this.name,
    required this.investmentType,
    required this.profitSharePercent,
    required this.profitPayoutCycle,
    this.contact,
    this.capitalReturnTermDays,
    this.notes,
  });
}

/// Create/edit form for a single [Investor]. Pure form state — validation
/// and the actual create/update call both live in `InvestorController`,
/// this widget only ever returns an [InvestorFormResult] via
/// `Navigator.pop`.
class InvestorFormSheet extends StatefulWidget {
  final Investor? existing;

  const InvestorFormSheet({super.key, this.existing});

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

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _profitShareController.dispose();
    _termDaysController.dispose();
    _notesController.dispose();
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
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'capitalReturnTermDays'.tr,
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
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: Text('save'.tr)),
            ],
          ),
        ),
      ),
    );
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
      ),
    );
  }
}
