import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/database/app_database.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/investor_controller.dart';

class InvestorScreen extends GetView<InvestorController> {
  final VoidCallback? onMenuTap;
  const InvestorScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1, color: Colors.white),
          onPressed:
              onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
        ),
        backgroundColor: kTeal,
        title: shopLogo(size: 20, color: Colors.white),
      ),
      body: Obx(
        () => controller.investors.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.buildings,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'noInvestors'.tr,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'autoTracked'.tr,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.investors.length,
                itemBuilder: (ctx, i) =>
                    _InvestorCard(investor: controller.investors[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(),
        child: const Icon(Iconsax.add),
      ),
    );
  }

  void _showAddDialog({Investor? edit}) {
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final amountCtrl = TextEditingController(
      text: edit?.cashInvested.toString() ?? '',
    );
    final durationCtrl = TextEditingController(
      text: edit?.durationMonths.toString() ?? '',
    );
    final profitCtrl = TextEditingController(
      text: edit?.profitPercentage.toString() ?? '',
    );
    String contractType = edit?.contractType ?? 'profitShare';
    String investType = edit?.investmentType ?? 'cash';

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            edit != null ? 'editInvestor'.tr : 'addInvestor'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'investorName'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: contractType,
                  decoration: InputDecoration(
                    labelText: 'contractType'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'loan', child: Text('cashLoan'.tr)),
                    DropdownMenuItem(
                      value: 'consignment',
                      child: Text('productConsignment'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'profitShare',
                      child: Text('profitSplit'.tr),
                    ),
                  ],
                  onChanged: (v) => setDlgState(() {
                    contractType = v ?? 'profitShare';
                    if (contractType == 'consignment') investType = 'products';
                  }),
                ),
                const SizedBox(height: 14),
                if (contractType != 'consignment')
                  DropdownButtonFormField<String>(
                    initialValue: investType,
                    decoration: InputDecoration(
                      labelText: 'investmentType'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('cashInvestment'.tr),
                      ),
                      DropdownMenuItem(value: 'mixed', child: Text('mixed'.tr)),
                    ],
                    onChanged: (v) =>
                        setDlgState(() => investType = v ?? 'cash'),
                  ),
                if (investType == 'cash' && contractType != 'consignment') ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'cashAmount'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'durationMonths'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: profitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'profitShare'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                final cash = double.tryParse(amountCtrl.text) ?? 0;
                if (edit != null) {
                  controller.updateInvestor(
                    edit,
                    name: nameCtrl.text,
                    investedAmount: cash,
                    durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                    profitPercentage: double.tryParse(profitCtrl.text) ?? 0,
                    contractType: contractType,
                    investmentType: investType,
                    cashInvested: cash,
                  );
                } else {
                  controller.addInvestor(
                    name: nameCtrl.text,
                    investedAmount: cash,
                    durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                    profitPercentage: double.tryParse(profitCtrl.text) ?? 0,
                    contractType: contractType,
                    investmentType: investType,
                    cashInvested: cash,
                  );
                }
                Get.back();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestorCard extends GetView<InvestorController> {
  final Investor investor;
  const _InvestorCard({required this.investor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.buildings, color: kTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.contractLabel(investor.contractType)} • ${controller.investLabel(investor.investmentType)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showEditDialog();
                    if (v == 'repay') _showRepayDialog();
                    if (v == 'delete') _confirmDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('edit'.tr)),
                    PopupMenuItem(value: 'repay', child: Text('repay'.tr)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'delete'.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metric('totalInvested'.tr, investor.investedAmount),
                  _metric('bought'.tr, investor.totalBought),
                  _metric('sold'.tr, investor.totalSold),
                  _metric('profit'.tr, investor.totalProfit, isProfit: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'remainingBalance'.tr}:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  '৳${investor.remainingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: investor.remainingBalance > 0
                        ? Colors.red.shade700
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, double value, {bool isProfit = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          '৳${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isProfit ? Colors.green : kTeal,
          ),
        ),
      ],
    );
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'delete'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          '${'delete'.tr} "${investor.name}"? ${'cannotBeUndone'.tr}.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.deleteInvestor(investor.id);
              Get.back();
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: investor.name);
    final amountCtrl = TextEditingController(
      text: investor.cashInvested.toString(),
    );
    final durationCtrl = TextEditingController(
      text: investor.durationMonths.toString(),
    );
    final profitCtrl = TextEditingController(
      text: investor.profitPercentage.toString(),
    );
    String contractType = investor.contractType;
    String investType = investor.investmentType;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            'editInvestor'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'investorName'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: contractType,
                  decoration: InputDecoration(
                    labelText: 'contractType'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'loan', child: Text('cashLoan'.tr)),
                    DropdownMenuItem(
                      value: 'consignment',
                      child: Text('productConsignment'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'profitShare',
                      child: Text('profitSplit'.tr),
                    ),
                  ],
                  onChanged: (v) => setDlgState(() {
                    contractType = v ?? 'profitShare';
                    if (contractType == 'consignment') investType = 'products';
                  }),
                ),
                const SizedBox(height: 14),
                if (contractType != 'consignment')
                  DropdownButtonFormField<String>(
                    initialValue: investType,
                    decoration: InputDecoration(
                      labelText: 'investmentType'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('cashInvestment'.tr),
                      ),
                      DropdownMenuItem(value: 'mixed', child: Text('mixed'.tr)),
                    ],
                    onChanged: (v) =>
                        setDlgState(() => investType = v ?? 'cash'),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'cashAmount'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'durationMonths'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: profitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'profitShare'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final cash = double.tryParse(amountCtrl.text) ?? 0;
                controller.updateInvestor(
                  investor,
                  name: nameCtrl.text,
                  investedAmount: cash,
                  durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                  profitPercentage: double.tryParse(profitCtrl.text) ?? 0,
                  contractType: contractType,
                  investmentType: investType,
                  cashInvested: cash,
                );
                Get.back();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepayDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(
          'addRepayment'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'repaymentAmount'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'noteOptional'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (amt > 0) {
                controller.addRepayment(investor.id, amt, noteCtrl.text);
              }
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
