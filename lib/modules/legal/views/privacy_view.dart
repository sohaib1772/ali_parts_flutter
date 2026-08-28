import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

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
                            'سياسة الخصوصية',
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

              // Policy Content (LTR)
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Last updated: 20 July 2026',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '${settings.storeName} ("we", "us", "our") operates the online store at maktabali.com and its mobile applications (the "Service"). This policy explains what personal information we collect, why we collect it, and what we do with it.',
                              style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Data controller: ${settings.storeName}, ${settings.storeAddress.isNotEmpty ? settings.storeAddress : "Erbil, Iraq"}.',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),

                            const Divider(height: 32),

                            _buildSection(
                              '1. Information We Collect',
                              '• Account information: When you create an account you sign in using Google or Apple. From them we receive your email address, your name, and your profile picture if you have one. We never receive or store your Google or Apple password.\n\n'
                              '• Contact and delivery information: After signing in we ask for a phone number so we can contact you about your order. When you place an order you provide a delivery address. Please note we do not verify phone numbers.\n\n'
                              '• Order information: The products you order, quantities, prices, order status, delivery method, and your order history. Because we sell on a cash-on-delivery basis, we do not collect or store bank card or payment card details of any kind.\n\n'
                              '• Shopping activity: Items in your cart, products you save to favourites, and loyalty points earned on orders.',
                            ),

                            _buildSection(
                              '2. How We Use Your Information',
                              'We use your information to:\n'
                              '• Create and maintain your account\n'
                              '• Process, prepare and deliver your orders\n'
                              '• Contact you about an order, by phone or WhatsApp\n'
                              '• Show you parts compatible with your vehicle\n'
                              '• Handle replacement requests\n'
                              '• Send you order notifications, if you have enabled them\n'
                              '• Keep records of our sales',
                            ),

                            _buildSection(
                              '3. What We Do Not Do',
                              '• We do not sell, rent or trade your personal information to anyone.\n'
                              '• We do not use advertising networks or advertising trackers.\n'
                              '• We do not use analytics services that follow you across other websites.\n'
                              '• We do not collect payment card information. We accept cash on delivery only.',
                            ),

                            _buildSection(
                              '4. Who We Share Information With',
                              '• Sign-in providers: Google and Apple, solely to sign you in. Their handling of your data is governed by their own privacy policies.\n\n'
                              '• Delivery: We share your name, phone number and delivery address with the delivery service or driver bringing your order, only as needed to complete the delivery.\n\n'
                              '• Technical services: Our website and database run on secure dedicated servers with encrypted connections.',
                            ),

                            _buildSection(
                              '10. Changes to This Policy',
                              'We may update this policy from time to time. When we do, we will change the "Last updated" date at the top of this page. Your continued use of the Service after a change means you accept the updated policy.',
                            ),

                            _buildSection(
                              '11. Contact Us',
                              'If you have any questions about this policy or about your personal information, contact us:',
                            ),

                            const SizedBox(height: 8),

                            // Store Owner Info Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.storeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    settings.storeAddress.isNotEmpty ? settings.storeAddress : 'Erbil, Iraq',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${settings.supportEmail.isNotEmpty ? settings.supportEmail : "aliskida816@gmail.com"}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: ${settings.whatsappNumber}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'WhatsApp: ${settings.whatsappNumber}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final url = Formatters.generateWhatsAppUrl(phone: settings.whatsappNumber);
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                      label: const Text('Contact us on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0A192F),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
