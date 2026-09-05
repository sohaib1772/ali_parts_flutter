import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../products/widgets/product_card_widget.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsView extends GetView<ProductDetailsController> {
  const ProductDetailsView({super.key});

  void _openFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;

    final RxInt activeIdx = initialIndex.obs;
    final PageController galleryPageController = PageController(initialPage: initialIndex);

    Get.to(
      () => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Swipable Full Screen Images with Pinch-to-Zoom
                PageView.builder(
                  controller: galleryPageController,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    activeIdx.value = i;
                    controller.selectedImageIndex.value = i;
                    if (controller.pageController.hasClients) {
                      controller.pageController.jumpToPage(i);
                    }
                  },
                  itemBuilder: (ctx, i) {
                    final img = images[i];
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: Formatters.thumbUrl(img, width: 1600),
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.directions_car_filled_rounded, color: Color(0xFF475569), size: 64),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Top App Bar in Full Screen (Back on right in RTL, Index counter in middle)
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),

                      // Image Counter (e.g. 1 / 3)
                      if (images.length > 1)
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Text(
                            '${activeIdx.value + 1} / ${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),

                      // Share Button
                      GestureDetector(
                        onTap: () => controller.shareProduct(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Thumbnails Bar in Full Screen
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          return Obx(() {
                            final isSel = activeIdx.value == i;
                            return GestureDetector(
                              onTap: () {
                                activeIdx.value = i;
                                galleryPageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? AppColors.gold : Colors.white.withValues(alpha: 0.3),
                                    width: isSel ? 2.5 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: Formatters.thumbUrl(images[i], width: 200),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Obx(() {
          if (controller.isLoading.value || controller.product.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final product = controller.product.value!;

          return Stack(
            children: [
              // Main Scrollable Page Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Image Container & Thumbnails
                    Stack(
                      children: [
                        // Square Main Image Container (1:1 Aspect Ratio) with Tap-to-Fullscreen
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: GestureDetector(
                            onTap: () => _openFullScreenGallery(
                              context,
                              product.images,
                              controller.selectedImageIndex.value,
                            ),
                            child: Container(
                              color: Colors.white,
                              child: product.images.isNotEmpty
                                  ? PageView.builder(
                                      controller: controller.pageController,
                                      itemCount: product.images.length,
                                      onPageChanged: (i) => controller.selectedImageIndex.value = i,
                                      itemBuilder: (ctx, i) {
                                        final img = product.images[i];
                                        return CachedNetworkImage(
                                          imageUrl: Formatters.thumbUrl(img, width: 1200),
                                          fit: BoxFit.contain,
                                          placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                                          errorWidget: (_, __, ___) => const Center(
                                            child: Icon(Icons.directions_car_filled_rounded, color: Color(0xFFCBD5E1), size: 64),
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(Icons.directions_car_filled_rounded, color: Color(0xFFCBD5E1), size: 64),
                                    ),
                            ),
                          ),
                        ),

                        // Top Floating Action Buttons (Back on Right in RTL, Share on Left in RTL)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button (Right side in RTL)
                              GestureDetector(
                                onTap: () => Get.back(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF0F172A),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),

                              // Share button (Left side in RTL)
                              GestureDetector(
                                onTap: () => controller.shareProduct(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      IconsaxPlusLinear.share,
                                      color: Color(0xFF0F172A),
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Thumbnails Row (if multiple images)
                    if (product.images.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: product.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) {
                            return Obx(() {
                              final isSelected = controller.selectedImageIndex.value == i;
                              return GestureDetector(
                                onTap: () => controller.selectImage(i),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppColors.gold : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    imageUrl: Formatters.thumbUrl(product.images[i], width: 200),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],

                    // 2. Product Details Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product.nameAr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),

                          // OEM Pill
                          if (product.oemNumber != null && product.oemNumber!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OEM: ${product.oemNumber}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Price & Status Badges (Responsive Wrap to prevent overflow on long numbers)
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Formatted IQD Price
                              Obx(() => Text(
                                Formatters.formatIQD(controller.unitPrice),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navyDark,
                                  letterSpacing: -0.5,
                                ),
                              )),

                              // Badges Row
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Condition Badge (مستعمل / جديد)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: product.isUsed
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: product.isUsed
                                            ? const Color(0xFFFCD34D)
                                            : const Color(0xFF6EE7B7),
                                      ),
                                    ),
                                    child: Text(
                                      product.isUsed ? 'مستعمل' : 'جديد',
                                      style: TextStyle(
                                        color: product.isUsed
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF047857),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Stock Availability Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: product.isAvailable
                                          ? const Color(0xFFD1FAE5)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: product.isAvailable
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFFFCA5A5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          product.isAvailable
                                              ? Icons.check_circle_outline_rounded
                                              : Icons.cancel_outlined,
                                          size: 14,
                                          color: product.isAvailable
                                              ? const Color(0xFF047857)
                                              : const Color(0xFFB91C1C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.isAvailable
                                              ? 'متوفر · ${product.stockQty} قطعة'
                                              : 'غير متوفر',
                                          style: TextStyle(
                                            color: product.isAvailable
                                                ? const Color(0xFF047857)
                                                : const Color(0xFFB91C1C),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 3. Description Card
                          if (product.descriptionAr != null && product.descriptionAr!.trim().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الوصف',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product.descriptionAr!,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 4. Side Selection Card (الجهة - اختياري)
                          if (product.hasSideOptions) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Text(
                                            'الجهة',
                                            style: TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '(اختياري)',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Obx(() {
                                        if (controller.selectedSide.value == null) return const SizedBox.shrink();
                                        return GestureDetector(
                                          onTap: () => controller.setSide(null),
                                          child: const Text(
                                            'إلغاء الاختيار',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(() {
                                    final side = controller.selectedSide.value;
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildSideButton(
                                            title: 'LH · يسار',
                                            isSelected: side == 'LH',
                                            onTap: () => controller.setSide(side == 'LH' ? null : 'LH'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSideButton(
                                            title: 'RH · يمين',
                                            isSelected: side == 'RH',
                                            onTap: () => controller.setSide(side == 'RH' ? null : 'RH'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSideButton(
                                            title: 'تخم · طقم',
                                            isSelected: side == 'PAIR',
                                            isGoldPair: true,
                                            onTap: () => controller.setSide(side == 'PAIR' ? null : 'PAIR'),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 5. Compatible Cars Card (السيارات المتوافقة)
                          Obx(() {
                            if (controller.compatibleCarNames.isEmpty) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'السيارات المتوافقة',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: controller.compatibleCarNames.map((name) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0A192F),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // 6. Guarantee Grid Cards (2 Cards Side by Side)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.shield_outlined, color: AppColors.gold, size: 22),
                                      SizedBox(height: 6),
                                      Text(
                                        'قطع أصلية',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.local_shipping_outlined, color: AppColors.gold, size: 22),
                                      SizedBox(height: 6),
                                      Text(
                                        'توصيل سريع',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 7. Fast Delivery 72h Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.access_time_filled_rounded, color: Color(0xFF0A192F), size: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'التوصيل خلال 72 ساعة',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0A192F),
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'يصلك المنتج خلال 72 ساعة كحد أقصى من وقت تأكيد الطلب.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF475569),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 8. WhatsApp Support Inquiry Card
                          GestureDetector(
                            onTap: () => controller.askViaWhatsApp(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'عندك مشكلة أو استفسار؟',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'تواصل مع قسم المبيعات مباشرة عبر واتساب وسنساعدك فوراً.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF475569),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 9. Quantity & Action Controls Row
                          Row(
                            children: [
                              const Text(
                                'الكمية:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Stepper
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => controller.incrementQty(),
                                      icon: const Icon(Icons.add, size: 16),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Obx(() => SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${controller.quantity.value}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    )),
                                    IconButton(
                                      onPressed: () => controller.decrementQty(),
                                      icon: const Icon(Icons.remove, size: 16),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Favorite Button
                              Obx(() => GestureDetector(
                                onTap: () => controller.toggleFavorite(),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      controller.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: controller.isFavorite ? Colors.redAccent : const Color(0xFF0F172A),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )),
                              const SizedBox(width: 8),

                              // WhatsApp Action Button
                              GestureDetector(
                                onTap: () => controller.askViaWhatsApp(),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Return to Home Link
                          Center(
                            child: TextButton(
                              onPressed: () => Get.offAllNamed(AppRoutes.mainNav),
                              child: const Text(
                                'عد للرئيسية',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 10. Related Products Section (منتجات مشابهة)
                          Obx(() {
                            if (controller.relatedProducts.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppColors.gold,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'منتجات مشابهة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.58,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: controller.relatedProducts.length,
                                  itemBuilder: (ctx, i) {
                                    final relProd = controller.relatedProducts[i];
                                    return ProductCardWidget(
                                      product: relProd,
                                    );
                                  },
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 11. Sticky Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Stock Availability Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: product.isAvailable
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isAvailable
                                  ? IconsaxPlusBold.tick_circle
                                  : IconsaxPlusBold.close_circle,
                              size: 14,
                              color: product.isAvailable
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isAvailable ? '${product.stockQty} قطعة' : 'غير متوفر',
                              style: TextStyle(
                                color: product.isAvailable
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Add to Cart Button (Navy Outlined Button)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: product.isAvailable ? () => controller.addToCart() : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0A192F), width: 1.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              foregroundColor: const Color(0xFF0A192F),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IconsaxPlusBold.shopping_cart, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'أضف للسلة',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Buy Now Button (Gold Solid Button)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: product.isAvailable ? () => controller.buyNow() : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF0A192F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'اشترِ الآن',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Cairo', height: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSideButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isGoldPair = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? (isGoldPair ? AppColors.gold : const Color(0xFF0A192F))
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isGoldPair ? AppColors.gold : const Color(0xFF0A192F))
                : const Color(0xFFE2E8F0),
            width: 1.8,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isSelected
                  ? (isGoldPair ? const Color(0xFF0A192F) : Colors.white)
                  : const Color(0xFF0A192F),
            ),
          ),
        ),
      ),
    );
  }
}
