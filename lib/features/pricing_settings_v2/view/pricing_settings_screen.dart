import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/calculator_keypad.dart';
import '../controller/pricing_settings_controller.dart';

/// The Settings-page UI for `notes/business_logic.md`'s "প্রাইসিং
/// রেকমেন্ডেশন ইঞ্জিন" — configuring `OverheadSettings` (monthly shop
/// rent, owner salary), reviewing/overriding the auto-computed average
/// mokam trip cost, and reviewing/overriding the auto-refreshed monthly
/// sales-revenue estimate the whole suggestion is built on. See
/// `CatalogScreen`'s doc comment for why this reads/writes the v2
/// database only.
///
/// A [StatefulWidget], not a plain `GetView`, purely so [initState] can
/// call `checkForMonthlyRefresh()` — an extra month-boundary check on top
/// of the one `PricingSettingsController.onInit` already runs, so opening
/// this screen after a month has turned over refreshes the numbers even
/// if no new sale has happened yet in the new month to trigger the
/// controller's own reactive check.
class PricingSettingsScreen extends StatefulWidget {
  const PricingSettingsScreen({super.key});

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  late final PricingSettingsController controller =
      Get.find<PricingSettingsController>();

  @override
  void initState() {
    super.initState();
    controller.checkForMonthlyRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('pricingSettingsTitle'.tr)),
      body: Obx(() {
        final settings = controller.overheadSettings;
        final markup = controller.overheadMarkupPercent;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _StatusCard(
              bootstrapped: controller.isBootstrapped,
              markup: markup,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'overheadSectionTitle'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyEditRow(
              label: 'monthlyShopRent'.tr,
              value: settings.monthlyShopRent,
              onSave: controller.setMonthlyShopRent,
            ),
            const SizedBox(height: AppSpacing.md),
            _MoneyEditRow(
              label: 'monthlyOwnerSalary'.tr,
              value: settings.monthlyOwnerSalary,
              onSave: controller.setMonthlyOwnerSalary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'averageMonthlyTripCost'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              controller.isTripCostManual
                  ? 'manuallySet'.tr
                  : 'autoAveragedFromTrips'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyEditRow(
              label: 'averageMonthlyTripCost'.tr,
              value: settings.averageMonthlyTripCost,
              onSave: controller.setManualAverageMonthlyTripCost,
              onRevertToAuto: controller.isTripCostManual
                  ? () => controller.setManualAverageMonthlyTripCost(null)
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'estimatedMonthlySalesRevenue'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              !controller.isBootstrapped
                  ? 'estimatedMonthlySalesRevenueNotSetYet'.tr
                  : controller.isSalesRevenueManual
                  ? 'manuallySet'.tr
                  : 'autoRefreshedFromLastMonth'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MoneyEditRow(
              label: 'estimatedMonthlySalesRevenue'.tr,
              value: settings.estimatedMonthlySalesRevenue ?? Money.zero(),
              onSave: controller.setManualEstimatedMonthlySalesRevenue,
            ),
          ],
        );
      }),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool bootstrapped;
  final double? markup;
  const _StatusCard({required this.bootstrapped, required this.markup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMarkup = markup;
    if (!bootstrapped) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('pricingEngineBootstrapPeriodNotice'.tr),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'overheadMarkupPercentLabel'.tr,
              style: theme.textTheme.labelMedium,
            ),
            Text(
              currentMarkup == null
                  ? '—'
                  : '${(currentMarkup * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.headlineSmall,
            ),
            if (currentMarkup == null) ...[
              const SizedBox(height: 4),
              Text(
                'pricingEngineNoRevenueYetNotice'.tr,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A label + current [value] + an inline "edit" affordance that opens a
/// small dialog to type a new amount. [onRevertToAuto], when non-null,
/// shows a second action to drop back to the auto-computed value instead
/// of a manual one.
class _MoneyEditRow extends StatelessWidget {
  final String label;
  final Money value;
  final void Function(Money) onSave;
  final VoidCallback? onRevertToAuto;

  const _MoneyEditRow({
    required this.label,
    required this.value,
    required this.onSave,
    this.onRevertToAuto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value.format(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (onRevertToAuto != null)
          IconButton(
            tooltip: 'useAutoValue'.tr,
            icon: const Icon(Icons.refresh),
            onPressed: onRevertToAuto,
          ),
        IconButton(
          tooltip: 'edit'.tr,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _editMoneyDialog(
            context: context,
            label: label,
            value: value,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}

Future<void> _editMoneyDialog({
  required BuildContext context,
  required String label,
  required Money value,
  required void Function(Money) onSave,
}) async {
  final res = await showCalculatorModal(
    context,
    initialValue: value.format(showSymbol: false),
    title: label,
  );
  if (res != null) {
    final parsed = _parseMoneyOrNull(res);
    if (parsed != null) {
      onSave(parsed);
    }
  }
}

/// Same pattern as every other live-input `Money` field in the app —
/// `Money` has no `tryParse`.
Money? _parseMoneyOrNull(String text) {
  if (text.trim().isEmpty) return null;
  try {
    return Money.parse(text);
  } on MoneyException {
    return null;
  }
}
