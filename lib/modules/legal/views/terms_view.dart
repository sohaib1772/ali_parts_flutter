import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

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
                            'الشروط والأحكام',
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

              // Terms Content (LTR)
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
                              'Terms and Conditions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Last updated: 21 July 2026',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Welcome to the ${settings.storeName} app. By using the app you agree to the following terms and conditions. Please read them carefully; if you do not agree to any provision, please do not use the app.',
                              style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF334155)),
                            ),

                            const Divider(height: 32),

                            _buildSection(
                              '1. Definitions',
                              '• "The App": the ${settings.storeName} application on mobile and web.\n'
                              '• "The User": any person who creates an account or uses the App.\n'
                              '• "The Order": any purchase submitted through the App.',
                            ),

                            _buildSection(
                              '2. Use of the App',
                              '• You must be 18 years of age or older to create an account.\n'
                              '• You undertake to provide true and accurate information about your identity and address.\n'
                              '• Using the App for any unlawful purpose, or for any purpose contrary to Apple App Store or Google Play policies, is prohibited.',
                            ),

                            _buildSection(
                              '3. Orders and Prices',
                              '• All prices are in Iraqi Dinars and cover what is stated on the product page.\n'
                              '• Prices are subject to change at any time without prior notice.\n'
                              '• Product availability depends on stock.',
                            ),

                            _buildSection(
                              '4. Payment and Delivery',
                              '• Payment is made on delivery, in cash, in Iraqi Dinars.\n'
                              '• Delivery time and cost vary by governorate, as shown on the shipping page.\n'
                              '• The User has the right to inspect the part in front of the delivery agent before paying.',
                            ),

                            _buildSection(
                              '5. Replacement and Returns',
                              '• A part bought from stock may be replaced or returned within three (3) days of the date of receipt, provided it is in its original condition, not installed and not used, and in its complete packaging.\n'
                              '• Replacement does not cover electrical parts once the packaging has been opened.\n'
                              '• A part with a manufacturing defect is replaced free of charge after inspection.',
                            ),

                            _buildSection(
                              '11. Governing Law and Dispute Resolution',
                              'These Terms are governed by the laws of the Republic of Iraq. Any dispute arising from use of the App shall first be the subject of efforts to resolve it amicably; failing that, it shall be referred to the competent Iraqi courts.',
                            ),

                            _buildSection(
                              '12. Changes to These Terms',
                              'The Operator may amend these Terms at any time. Any amendment will be published within the App together with an updated "Last updated" date.',
                            ),

                            _buildSection(
                              '13. Contact',
                              'For any enquiry or legal complaint:',
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
