import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  final VoidCallback? onMenuTap;
  const DashboardScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.grid_2, color: Colors.white),
          onPressed:
              onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
        ),
        backgroundColor: kTeal,
        title: Row(
          children: [
            shopLogo(size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AL ASHAB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Obx(
                  () => Text(
                    controller.currentDate.value,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: controller.pickDate,
          ),
          Obx(
            () => IconButton(
              icon: Icon(
                controller.showOtherActivities.value
                    ? Iconsax.category
                    : Iconsax.activity,
                color: Colors.white,
              ),
              onPressed: controller.toggleView,
              tooltip: 'toggleView'.tr,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.loadDashboard,
          color: Colors.white,
          backgroundColor: kTeal,
          child: controller.showOtherActivities.value
              ? _buildOtherActivities()
              : _buildCardsGrid(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        onPressed: () => Get.toNamed(AppRoutes.quickCapture),
        child: const Icon(Iconsax.bookmark, size: 22),
      ),
    );
  }

  // --- 12-card grid view ---
  Widget _buildCardsGrid() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.85,
        children: [
          _gradientCard(
            'totalCash'.tr,
            controller.totalCash.value,
            Iconsax.wallet,
            const Color(0xFFE3F2FD),
            const Color(0xFFBBDEFB),
            const Color(0xFF1565C0),
          ),
          _gradientCard(
            'stockValue'.tr,
            controller.stockValue.value,
            Iconsax.box,
            const Color(0xFFF3E5F5),
            const Color(0xFFE1BEE7),
            const Color(0xFF6A1B9A),
          ),
          _gradientCard(
            controller.netProfit.value >= 0 ? 'netProfit'.tr : 'netLoss'.tr,
            controller.netProfit.value,
            controller.netProfit.value >= 0
                ? Iconsax.trend_up
                : Iconsax.trend_down,
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
            const Color(0xFF2E7D32),
          ),
          _gradientCard(
            'expense'.tr,
            controller.totalExpense.value,
            Iconsax.money_recive,
            const Color(0xFFFFEBEE),
            const Color(0xFFFFCDD2),
            const Color(0xFFC62828),
          ),
          _gradientCard(
            'totalBuy'.tr,
            controller.totalBuy.value,
            Iconsax.bag,
            const Color(0xFFFCE4EC),
            const Color(0xFFF8BBD0),
            const Color(0xFFAD1457),
          ),
          _gradientCard(
            'totalSell'.tr,
            controller.totalSell.value,
            Iconsax.shop,
            const Color(0xFFE0F2F1),
            const Color(0xFFB2DFDB),
            const Color(0xFF00695C),
          ),
          _gradientCard(
            'due'.tr,
            controller.totalDue.value,
            Iconsax.add_circle,
            const Color(0xFFECEFF1),
            const Color(0xFFCFD8DC),
            const Color(0xFF37474F),
          ),
          _gradientCard(
            'duePaid'.tr,
            controller.duePaid.value,
            Iconsax.tick_circle,
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
            const Color(0xFF2E7D32),
          ),
          _gradientCard(
            'rentDue'.tr,
            controller.rentDue.value,
            Iconsax.wallet,
            const Color(0xFFFFEBEE),
            const Color(0xFFFFCDD2),
            const Color(0xFFB71C1C),
          ),
          _gradientCard(
            'rentPaid'.tr,
            controller.rentPaid.value,
            Iconsax.book,
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
            const Color(0xFF1B5E20),
          ),
          _gradientCard(
            'totalAssets'.tr,
            controller.totalAssets.value,
            Iconsax.buildings,
            const Color(0xFFECEFF1),
            const Color(0xFFCFD8DC),
            const Color(0xFF455A64),
          ),
          _gradientCard(
            'toGiveAway'.tr,
            controller.toGiveAway.value,
            Iconsax.export_1,
            const Color(0xFFF3E5F5),
            const Color(0xFFE1BEE7),
            const Color(0xFF4A148C),
          ),
        ],
      ),
    );
  }

  // --- Other Activities view ---
  Widget _buildOtherActivities() {
    final hasAny =
        controller.dateExpenses.isNotEmpty ||
        controller.datePurchases.isNotEmpty ||
        controller.dateInvestorRepayments.isNotEmpty ||
        controller.dateCustomerActivity.isNotEmpty;

    if (!hasAny) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.activity, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'noActivitiesToday'.tr,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (controller.dateExpenses.isNotEmpty)
          _activitySection(
            Iconsax.money_recive,
            Colors.red,
            'expenses'.tr,
            controller.dateExpenses
                .map(
                  (e) =>
                      '${e['title']}: ৳${(e['amount'] as double).toStringAsFixed(0)}${(e['note'] as String).isNotEmpty ? ' (${e['note']})' : ''}',
                )
                .toList(),
          ),
        if (controller.datePurchases.isNotEmpty)
          _activitySection(
            Iconsax.bag,
            Colors.orange,
            'stockPurchases'.tr,
            controller.datePurchases
                .map(
                  (p) =>
                      '${p['itemName']} × ${(p['quantity'] as double).toStringAsFixed(0)}: ৳${(p['amount'] as double).toStringAsFixed(0)}',
                )
                .toList(),
          ),
        if (controller.dateInvestorRepayments.isNotEmpty)
          _activitySection(
            Iconsax.building,
            Colors.teal,
            'investorRepayments'.tr,
            controller.dateInvestorRepayments
                .map(
                  (r) =>
                      '${r['investor']}: ৳${(r['amount'] as double).toStringAsFixed(0)}',
                )
                .toList(),
          ),
        if (controller.dateCustomerActivity.isNotEmpty)
          _activitySection(
            Iconsax.people,
            Colors.blue,
            'customerActivity'.tr,
            controller.dateCustomerActivity.map((a) {
              final prefix = a['type'] == 'purchase'
                  ? '[Purchase]'
                  : a['type'] == 'order'
                  ? '[Order]'
                  : a['type'] == 'rental_taken'
                  ? '[Rental]'
                  : '[Return]';
              return '$prefix ${a['customer']}: ${a['detail']}';
            }).toList(),
          ),
      ],
    );
  }

  Widget _activitySection(
    IconData icon,
    Color color,
    String title,
    List<String> lines,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Gradient card widget ---
  Widget _gradientCard(
    String label,
    double value,
    IconData icon,
    Color bgStart,
    Color bgEnd,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '৳ ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
