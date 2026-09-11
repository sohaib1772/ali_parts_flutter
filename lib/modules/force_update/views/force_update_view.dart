import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';

class ForceUpdateView extends StatelessWidget {
  final String? currentVersion;
  final String? minVersion;

  const ForceUpdateView({
    super.key,
    this.currentVersion,
    this.minVersion,
  });

  Future<void> _openStore() async {
    final settings = Get.find<SettingsService>();
    final url = Platform.isIOS ? settings.appStoreUrl : settings.playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final args = Get.arguments is Map ? Get.arguments as Map : null;
    final curr = currentVersion ?? args?['currentVersion']?.toString() ?? '1.0.0';
    final min = minVersion ?? args?['minVersion']?.toString() ?? (Platform.isIOS ? settings.minAppVersionIos : settings.minAppVersionAndroid);

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0A192F),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0A192F),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0A192F),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Rocket Update Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F1E36),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          IconsaxPlusBold.refresh_circle,
                          color: AppColors.gold,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title & Store Name
                    Text(
                      settings.storeName.isNotEmpty ? settings.storeName : 'مكتب علي شوفرليت',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'تحديث إجباري جديد متوفر 🚀',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E36),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            settings.forceUpdateMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13.5,
                              height: 1.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFF1E293B)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'الإصدار الحالي',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    curr,
                                    style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                              Column(
                                children: [
                                  const Text(
                                    'الإصدار المطلوب',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    min,
                                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Update Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openStore,
                        icon: const Icon(IconsaxPlusBold.direct_down, color: Color(0xFF0A192F), size: 20),
                        label: Text(
                          Platform.isIOS ? 'تحديث من App Store الآن' : 'تحديث من Google Play الآن',
                          style: const TextStyle(
                            color: Color(0xFF0A192F),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          shadowColor: AppColors.gold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'ملاحظة: لا يمكنك متابعة استخدام التطبيق دون التحديث لضمان التوافق والأمان.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
