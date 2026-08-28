import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/main_nav_controller.dart';
import '../../home/views/home_view.dart';
import '../../favorites/views/favorites_view.dart';
import '../../orders/views/orders_view.dart';
import '../../account/views/account_view.dart';

class MainNavView extends GetView<MainNavController> {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeView(),
      const FavoritesView(),
      const OrdersView(),
      const SizedBox.shrink(), // WhatsApp tab
      const AccountView(),
    ];

    final settings = Get.find<SettingsService>();

    return Obx(() {
      final selectedIdx = controller.currentIndex.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: selectedIdx,
          children: screens,
        ),

        // Floating WhatsApp Action Button (Above Bottom Navigation Bar)
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final url = Formatters.generateWhatsAppUrl(
              phone: settings.whatsappNumber,
              message: 'مرحباً، أحتاج استفسار من الدعم الفني لمكتب علي شوفرليت.',
            );
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          backgroundColor: AppColors.whatsApp,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        // White Luxury Bottom Navigation Bar with Gold Active Indicator
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            border: Border(
              top: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'الرئيسية', selectedIdx == 0),
                _buildNavItem(1, Icons.favorite_rounded, Icons.favorite_border_rounded, 'المفضلة', selectedIdx == 1),
                _buildNavItem(2, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'طلباتي', selectedIdx == 2),
                _buildNavItem(3, Icons.chat_rounded, Icons.chat_outlined, 'الرسائل', selectedIdx == 3),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'الحساب', selectedIdx == 4),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top indicator bar when active
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppColors.gold : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.navyDark : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
