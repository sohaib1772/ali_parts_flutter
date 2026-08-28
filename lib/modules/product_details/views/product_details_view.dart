import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsView extends GetView<ProductDetailsController> {
  const ProductDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value || controller.product.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final product = controller.product.value!;

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar with Image Carousel
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: true,
                    backgroundColor: AppColors.navyDark,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    actions: [
                      Obx(() => IconButton(
                        icon: Icon(
                          controller.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: controller.isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: controller.toggleFavorite,
                      )),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: AppColors.imageBg,
                            child: PageView.builder(
                              itemCount: product.images.isNotEmpty ? product.images.length : 1,
                              onPageChanged: (i) => controller.selectedImageIndex.value = i,
                              itemBuilder: (ctx, i) {
                                final img = product.images.isNotEmpty ? product.images[i] : '';
                                return CachedNetworkImage(
                                  imageUrl: Formatters.thumbUrl(img, width: 800),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.imageBg),
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(Icons.settings_outlined, color: Color(0xFFCBD5E1), size: 64),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Dot indicator
                          if (product.images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Obx(() => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  product.images.length,
                                  (idx) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: controller.selectedImageIndex.value == idx ? 16 : 6,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: controller.selectedImageIndex.value == idx ? AppColors.gold : Colors.black26,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              )),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Product Body Details
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Condition & Availability Chips
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isUsed ? AppColors.usedBadge : AppColors.newBadge,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.isUsed ? 'مستعمل تفصيخ' : 'جديد أصلية',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isAvailable
                                      ? AppColors.inStock.withValues(alpha: 0.12)
                                      : AppColors.outOfStock.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: product.isAvailable ? AppColors.inStock : AppColors.outOfStock,
                                  ),
                                ),
                                child: Text(
                                  product.isAvailable ? 'متوفر بالمخزن (${product.stockQty} قطعة)' : 'نفدت الكمية',
                                  style: TextStyle(
                                    color: product.isAvailable ? AppColors.inStock : AppColors.outOfStock,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Product Title
                          Text(
                            product.nameAr,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Price Row (Dynamic when PAIR is selected)
                          Obx(() => Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.formatIQD(controller.unitPrice),
                                style: const TextStyle(
                                  color: AppColors.navyDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (controller.selectedSide.value == 'PAIR')
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '(سعر التخم)',
                                    style: TextStyle(
                                      color: AppColors.goldDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (product.hasDiscount && controller.selectedSide.value != 'PAIR') ...[
                                const SizedBox(width: 10),
                                Text(
                                  Formatters.formatIQD(product.comparePriceIqd),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          )),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: 12),

                          // Side Selection Section
                          const Text(
                            'تحديد الجهة (اختياري):',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            final currentSide = controller.selectedSide.value;
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSideOption('LH · يسار', 'LH', currentSide),
                                  const SizedBox(width: 4),
                                  _buildSideOption('RH · يمين', 'RH', currentSide),
                                  const SizedBox(width: 4),
                                  _buildSideOption('تخم (يمين + يسار)', 'PAIR', currentSide),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),

                          // OEM Number
                          if (product.oemNumber != null && product.oemNumber!.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('رقم القطعة OEM:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                Text(
                                  product.oemNumber!,
                                  style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Description
                          if (product.descriptionAr != null && product.descriptionAr!.isNotEmpty) ...[
                            const Text('الوصف والمواصفات:', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(
                              product.descriptionAr!,
                              style: const TextStyle(color: AppColors.textBody, fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Quantity Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الكمية المطلوبة:', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: AppColors.textDark, size: 18),
                                      onPressed: controller.decrementQty,
                                    ),
                                    Obx(() => Text(
                                      controller.quantity.value.toString(),
                                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15),
                                    )),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: AppColors.navyDark, size: 18),
                                      onPressed: controller.incrementQty,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // WhatsApp Inquiry Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: controller.askViaWhatsApp,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.whatsApp),
                              label: const Text('استفسار مباشر عن القطعة عبر واتساب'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.whatsApp, width: 1.5),
                                foregroundColor: AppColors.whatsApp,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Add-to-Cart Fixed Bar with Dynamic Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.cardWhite,
                border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: product.isAvailable ? controller.addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF0F172A)),
                    label: Text(
                      product.isAvailable
                          ? 'إضافة إلى السلة (${Formatters.formatIQD(controller.totalPrice)})'
                          : 'غير متوفر حالياً',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSideOption(String label, String sideCode, String? currentSide) {
    final isSelected = currentSide == sideCode;

    return GestureDetector(
      onTap: () {
        controller.setSide(isSelected ? null : sideCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
