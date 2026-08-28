import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/settings_service.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final cart = Get.find<CartService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top AppHeader
              Container(
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
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF102A43),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'من نحن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.storeTagline,
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

                    // Search Icon
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

                    // Notification Bell
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

                    // Cart Icon with Badge
                    Obx(() {
                      final count = cart.cartCount.value;
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
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEAB308),
                                  border: Border.all(color: const Color(0xFF0A192F), width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Scrollable Body Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    // 1. Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A192F), Color(0xFF102A43)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            settings.storeAbout.isNotEmpty
                                ? settings.storeAbout
                                : 'متجر علي لقطع غيار السيارات متخصص بتوفير قطع غيار شفروليه، جي إم سي، وكاديلاك الأصلية والمستعملة بحالة ممتازة. نوفر أسعار منافسة، جودة مضمونة، وشحن إلى جميع محافظات العراق مع خدمة عملاء سريعة وموثوق / اربيل',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. 2x2 Highlights Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.25,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.access_time_rounded,
                          title: '${settings.storeYears}+ سنوات خبرة',
                          desc: 'في سوق قطع غيار السيارات',
                        ),
                        _buildFeatureCard(
                          icon: Icons.diamond_outlined,
                          title: 'جودة عالية',
                          desc: 'قطع أصلية ومكافئة للمواصفات',
                        ),
                        _buildFeatureCard(
                          icon: Icons.verified_outlined,
                          title: 'ضمان حقيقي',
                          desc: 'ضمان على كل قطعة تشريها',
                        ),
                        _buildFeatureCard(
                          icon: Icons.storefront_outlined,
                          title: 'موقع متميز',
                          desc: settings.storeAddress.isNotEmpty ? settings.storeAddress : 'اربيل',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. Storefront Image Section
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'واجهة المحل',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: settings.storeFrontImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: settings.storeFrontImage,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Image.asset(
                                'assets/images/banner_placeholder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF0A192F),
                                  child: const Center(
                                    child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 48),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF0A192F),
                              child: const Center(
                                child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 48),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Store Location Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFBEB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_outlined, color: Color(0xFFD97706), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'موقع المحل',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settings.storeAddress.isNotEmpty ? settings.storeAddress : 'اربيل',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final url = settings.storeLocationLink.isNotEmpty
                                    ? settings.storeLocationLink
                                    : 'https://maps.google.com/?q=Erbil';
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('فتح الموقع على الخريطة', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A192F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. 2x2 Values Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.25,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.shield_outlined,
                          title: 'قطع أصلية 100%',
                          desc: 'نضمن أصالة كل قطعة نبيعها',
                        ),
                        _buildFeatureCard(
                          icon: Icons.local_shipping_outlined,
                          title: 'توصيل سريع',
                          desc: 'لكل محافظات العراق',
                        ),
                        _buildFeatureCard(
                          icon: Icons.military_tech_outlined,
                          title: 'خبرة موثوقة',
                          desc: 'سنوات في مجال قطع الغيار',
                        ),
                        _buildFeatureCard(
                          icon: Icons.people_outline_rounded,
                          title: 'خدمة عملاء 7/24',
                          desc: 'دائماً بجانبك عبر واتساب',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
