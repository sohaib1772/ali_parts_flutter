import '../../../core/widgets/app_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card_widget.dart';

class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.background,
          child: Column(
            children: [
              Obx(() => AppHeaderWidget(
                title: controller.pageTitle.value.isNotEmpty ? controller.pageTitle.value : 'المنتجات',
                showBack: true,
                customActions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.gold),
                    onPressed: () => _showFilterBottomSheet(context),
                  ),
                ],
              )),
              Expanded(
                child: Stack(
                  children: [
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                      }

                      if (controller.products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cardWhite,
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: AppColors.gold, size: 48),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'لا توجد منتجات مطابقة للبحث',
                                style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.gold,
                        backgroundColor: Colors.white,
                        onRefresh: controller.loadProducts,
                        child: CustomScrollView(
                          controller: controller.scrollController,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.58,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => ProductCardWidget(product: controller.products[i]),
                                  childCount: controller.products.length,
                                ),
                              ),
                            ),
                            if (controller.isLoadingMore.value)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    // Floating Glass Scroll To Top Button
                    GlassScrollToTopButton(
                      scrollController: controller.scrollController,
                      bottom: 20,
                      left: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلترة حسب الحالة',
              style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() => Row(
              children: [
                _buildChoiceChip('الكل', 'all', controller.selectedCondition.value, (val) {
                  controller.setCondition(val);
                  Get.back();
                }),
                const SizedBox(width: 8),
                _buildChoiceChip('جديد فقط', 'new', controller.selectedCondition.value, (val) {
                  controller.setCondition(val);
                  Get.back();
                }),
                const SizedBox(width: 8),
                _buildChoiceChip('مستعمل تفصيخ', 'used', controller.selectedCondition.value, (val) {
                  controller.setCondition(val);
                  Get.back();
                }),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, String currentVal, Function(String) onSelect) {
    final isSelected = value == currentVal;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.navyDark : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
