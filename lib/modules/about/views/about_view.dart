import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'من نحن',
                showBack: true,
              ),

              // Scrollable Body Content
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
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

                      const SizedBox(height: 14),

                      // 3. Contact & Social Channels
                      Container(
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
                              'تواصل معنا',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildContactTile(
                              icon: Icons.phone_in_talk_rounded,
                              iconBg: const Color(0xFFEFF6FF),
                              iconColor: const Color(0xFF2563EB),
                              title: 'الهاتف المباشر',
                              subtitle: settings.storePhone,
                              onTap: () => _launch('tel:${settings.storePhone}'),
                            ),
                            const Divider(height: 16, color: Color(0xFFF1F5F9)),
                            _buildContactTile(
                              icon: Icons.chat_bubble_outline_rounded,
                              iconBg: const Color(0xFFECFDF5),
                              iconColor: const Color(0xFF10B981),
                              title: 'واتساب خدمة العملاء',
                              subtitle: settings.whatsappNumber,
                              onTap: () => _launch(Formatters.generateWhatsAppUrl(phone: settings.whatsappNumber)),
                            ),
                            const Divider(height: 16, color: Color(0xFFF1F5F9)),
                            _buildContactTile(
                              icon: Icons.location_on_outlined,
                              iconBg: const Color(0xFFFFFBEB),
                              iconColor: const Color(0xFFD97706),
                              title: 'عنوان المحل / المستودع',
                              subtitle: settings.storeAddress.isNotEmpty ? settings.storeAddress : 'اربيل',
                              onTap: () {},
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
