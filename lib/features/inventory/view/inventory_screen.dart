import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/inventory_controller.dart';
import 'widgets/product_card.dart';
import 'widgets/product_form.dart';
import 'widgets/filter_bar.dart';

class InventoryScreen extends GetView<InventoryController> {
  final VoidCallback? onMenuTap;
  const InventoryScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.menu_1, color: Colors.white),
            onPressed:
                onMenuTap ?? () => Get.find<ShellController>().openDrawer(),
          ),
          title: shopLogo(size: 20, color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'stock'.tr),
              Tab(text: 'assets'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStockTab(context),
            Center(
              child: Text(
                'fixedAssets'.tr,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
        floatingActionButton: Obx(
          () => FloatingActionButton(
            backgroundColor: kTeal,
            foregroundColor: Colors.white,
            onPressed: () => controller.showForm.toggle(),
            child: Icon(
              controller.showForm.value ? Iconsax.close_circle : Iconsax.add,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockTab(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FilterBar(),
              const SizedBox(height: 14),
              _buildSummaryCards(),
              const SizedBox(height: 10),
              Obx(() {
                final list = controller.filteredProducts;
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.box,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'noProducts'.tr,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => ProductCard(product: list[i]),
                );
              }),
            ],
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: controller.showForm.value ? 0 : -600,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: const Center(
                child: SingleChildScrollView(child: ProductForm()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final s = controller.summary;
      if (s['count'] == 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTeal.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('products'.tr, '${s['count']!.toInt()}'),
            _summaryItem('value'.tr, '৳${s['value']!.toStringAsFixed(2)}'),
            _summaryItem(
              'profit'.tr,
              '৳${s['profit']!.toStringAsFixed(2)}',
              isProfit: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryItem(String label, String value, {bool isProfit = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green : kTeal,
            ),
          ),
        ],
      ),
    );
  }
}
