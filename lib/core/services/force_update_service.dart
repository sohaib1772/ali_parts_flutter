import 'dart:io';
import 'package:flutter/material.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import 'settings_service.dart';

class ForceUpdateConfig {
  static const String iosAppStoreId = '6798370719';

  /// Creates a configured [ForceUpdateClient] using remote Supabase settings
  static ForceUpdateClient createClient() {
    return ForceUpdateClient(
      fetchRequiredVersion: () async {
        final settings = Get.isRegistered<SettingsService>()
            ? Get.find<SettingsService>()
            : null;
        if (settings != null) {
          if (settings.settings.isEmpty) {
            await settings.fetchSettings();
          }
          final minVer = Platform.isIOS
              ? settings.minAppVersionIos
              : settings.minAppVersionAndroid;
          final clean = minVer.split('+').first.trim();
          return clean.isNotEmpty ? clean : '1.0.0';
        }
        return '1.0.0';
      },
      iosAppStoreId: iosAppStoreId,
    );
  }

  /// Displays the branded Arabic force update dialog
  static Future<bool?> showForceUpdateDialog(
    BuildContext context,
    bool allowCancel,
  ) async {
    final settings = Get.isRegistered<SettingsService>()
        ? Get.find<SettingsService>()
        : null;
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final minVersion = Platform.isIOS
        ? (settings?.minAppVersionIos ?? '1.0.0')
        : (settings?.minAppVersionAndroid ?? '1.0.0');

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: allowCancel,
      builder: (ctx) => PopScope(
        canPop: allowCancel,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing rocket icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F1E36),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      IconsaxPlusBold.refresh_circle,
                      color: AppColors.gold,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  settings?.storeName.isNotEmpty == true
                      ? settings!.storeName
                      : 'مكتب علي شوفرليت',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'تحديث إجباري جديد متوفر 🚀',
                  style: GoogleFonts.cairo(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1E36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        settings?.forceUpdateMessage ??
                            'يتوفر تحديث جديد ومهم للتطبيق يحتوي على تحسينات ومميزات جديدة. يرجى التحديث للمتابعة.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'الإصدار الحالي',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentVersion,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFF1E293B),
                          ),
                          Column(
                            children: [
                              Text(
                                'الإصدار المطلوب',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                minVersion,
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(
                      IconsaxPlusBold.direct_down,
                      color: Color(0xFF0A192F),
                      size: 20,
                    ),
                    label: Text(
                      Platform.isIOS
                          ? 'تحديث من App Store الآن'
                          : 'تحديث من Google Play الآن',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF0A192F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ملاحظة: لا يمكنك متابعة استخدام التطبيق دون التحديث لضمان التوافق والأمان.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the store listing page
  static Future<void> launchStore(Uri fallbackStoreUrl) async {
    final settings = Get.isRegistered<SettingsService>()
        ? Get.find<SettingsService>()
        : null;
    final customUrl = Platform.isIOS
        ? settings?.appStoreUrl
        : settings?.playStoreUrl;
    final effectiveUri = (customUrl != null && customUrl.isNotEmpty)
        ? Uri.parse(customUrl)
        : fallbackStoreUrl;
    if (await canLaunchUrl(effectiveUri)) {
      await launchUrl(effectiveUri, mode: LaunchMode.externalApplication);
    }
  }
}
