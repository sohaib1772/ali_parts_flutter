import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        Get.toNamed(AppRoutes.productDetails, arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight, width: 1),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Image Container with Light Blue-Gray background
            AspectRatio(
              aspectRatio: 1.08,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.imageBg,
                      child: product.mainImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: Formatters.thumbUrl(product.mainImage),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.settings_outlined,
                                  color: Color(0xFFCBD5E1),
                                  size: 42,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.settings_outlined,
                                color: Color(0xFFCBD5E1),
                                size: 42,
                              ),
                            ),
                    ),
                  ),

                  // Condition Chip (مستعمل / جديد) Top-Right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isUsed ? AppColors.usedBadge : AppColors.newBadge,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (product.isUsed ? AppColors.usedBadge : AppColors.newBadge).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product.isUsed ? 'مستعمل' : 'جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Favorite Button (White circle on Top-Left)
                  Positioned(
                    top: 6,
                    left: 6,
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
                            border: Border.all(color: AppColors.borderLight, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : const Color(0xFF475569),
                            size: 15,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Stock Remaining Badge (Bottom-Right of Image)
                  if (product.isAvailable)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: product.stockQty <= 5 ? AppColors.remainingBadge : AppColors.inStock,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          product.stockQty <= 5 ? 'متبقي ${product.stockQty}' : 'متوفر ${product.stockQty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name (2 Lines tight)
                  SizedBox(
                    height: 32,
                    child: Text(
                      product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price & Stock row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock in green
                      Text(
                        product.isAvailable ? 'متوفر · ${product.stockQty} قطعة' : 'غير متوفر',
                        style: TextStyle(
                          color: product.isAvailable ? AppColors.inStock : AppColors.outOfStock,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Price in IQD
                      Text(
                        Formatters.formatIQD(product.priceIqd),
                        style: const TextStyle(
                          color: AppColors.navyDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Action Buttons Row: [أضف للسلة] + [WhatsApp Icon]
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.whatsApp,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.whatsApp.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Add to Cart Navy Button
                      Expanded(
                        child: GestureDetector(
                          onTap: product.isAvailable ? () => cartService.addToCart(product) : null,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.isAvailable ? AppColors.navyDark : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDark.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'أضف للسلة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
