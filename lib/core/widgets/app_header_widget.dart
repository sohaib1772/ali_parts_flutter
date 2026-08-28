import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../services/cart_service.dart';
import '../services/settings_service.dart';

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool? showBack;
  final VoidCallback? onBackPressed;
  final bool showSearch;
  final bool showNotifications;
  final bool showCart;
  final List<Widget>? customActions;

  const AppHeaderWidget({
    super.key,
    this.title,
    this.subtitle,
    this.showBack,
    this.onBackPressed,
    this.showSearch = true,
    this.showNotifications = true,
    this.showCart = true,
    this.customActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final cart = Get.find<CartService>();

    final displayTitle = (title != null && title!.isNotEmpty)
        ? title!
        : (settings.storeName.isNotEmpty ? settings.storeName : 'مكتب علي شوفرليت');

    final displaySubtitle = subtitle ?? (settings.storeTagline.isNotEmpty ? settings.storeTagline : 'قطع أصلية · العراق');

    // Auto-detect if screen can be popped/navigated back unless explicitly overridden
    final canGoBack = showBack ?? Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A192F),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button if screen is poppable or showBack is true
          if (canGoBack) ...[
            GestureDetector(
              onTap: onBackPressed ?? () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Get.back();
                }
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF132B45),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],

          // Store Circular Avatar / Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF102A43),
              border: Border.all(color: AppColors.gold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: settings.storeLogo.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: settings.storeLogo,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_filled_rounded,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.directions_car_filled_rounded,
                      color: AppColors.gold,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Screen Title & Store Gold Tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Custom Actions or Standard Icons
          if (customActions != null)
            ...customActions!
          else ...[
            // Search Icon
            if (showSearch) ...[
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF132B45),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Notification Bell
            if (showNotifications) ...[
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.notifications),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF132B45),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Cart Icon with live Badge
            if (showCart)
              Obx(() {
                final count = cart.cartCount.value;
                final isBumping = cart.cartBump.value;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.cart),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF132B45),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: AnimatedScale(
                          scale: isBumping ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEAB308), // Gold/Amber
                              border: Border.all(color: const Color(0xFF0A192F), width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
          ],
        ],
      ),
    );
  }
}
