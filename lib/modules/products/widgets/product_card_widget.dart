import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductModel product;

  const ProductCardWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartService = Get.find<CartService>();
    final favoritesService = Get.find<FavoritesService>();
    final settingsService = Get.find<SettingsService>();

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.productDetails,
          arguments: product,
          preventDuplicates: false,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Image Container (Square 1:1 Aspect Ratio)
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF1F5F9),
                    child: product.mainImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: Formatters.thumbUrl(product.mainImage, width: 400),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.directions_car_filled_rounded,
                                color: Color(0xFFCBD5E1),
                                size: 36,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.directions_car_filled_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 36,
                            ),
                          ),
                  ),

                  // Top-Start: Favorite Button (Right in RTL)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Obx(() {
                      final isFav = favoritesService.isFavorite(product.id);
                      return GestureDetector(
                        onTap: () => favoritesService.toggleFavorite(product),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.92),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                            color: isFav ? Colors.redAccent : const Color(0xFF0F172A),
                            size: 15,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Top-End: Condition & Deal Badges (Left in RTL)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.isDeal) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'عرض',
                              style: TextStyle(
                                color: Color(0xFF0A192F),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: product.isUsed ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            product.isUsed ? 'مستعمل' : 'جديد',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-Start: Stock Remaining Badge (Right in RTL)
                  if (product.isAvailable)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.stockQty <= 5 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(
                          product.stockQty <= 5 ? 'متبقي ${product.stockQty}' : 'متوفر · ${product.stockQty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Unavailable Overlay
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF0A192F).withValues(alpha: 0.65),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'غير متوفر',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Body Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title & OEM
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                        if (product.oemNumber != null && product.oemNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'OEM: ${product.oemNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Price & Stock Row + Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatIQD(product.priceIqd),
                              style: const TextStyle(
                                color: Color(0xFF0A192F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              product.isAvailable ? 'متوفر · ${product.stockQty} قطعة' : 'غير متوفر',
                              style: TextStyle(
                                color: product.isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Action Buttons: [أضف للسلة] + [WhatsApp]
                        Row(
                          children: [
                            // WhatsApp Button
                            GestureDetector(
                              onTap: () async {
                                final url = Formatters.generateWhatsAppUrl(
                                  phone: settingsService.whatsappNumber,
                                  productName: product.nameAr,
                                  oemNumber: product.oemNumber,
                                  productUrl: 'https://maktabali.com/product/${product.id}',
                                );
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    IconsaxPlusBold.messages_2,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),

                            // Add to Cart Button
                            Expanded(
                              child: GestureDetector(
                                onTap: product.isAvailable ? () => cartService.addToCart(product) : null,
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: product.isAvailable ? const Color(0xFF0A192F) : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(IconsaxPlusBold.shopping_cart, color: Colors.white, size: 13),
                                          SizedBox(width: 4),
                                          Text(
                                            'أضف للسلة',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
