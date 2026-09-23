import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/apple_glass_nav_bar.dart';
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
      const SizedBox.shrink(), // Reels is a dedicated full-screen page
      const AccountView(),
    ];

    const navItems = [
      AppleGlassNavItem(
        activeIcon: IconsaxPlusBold.home_2,
        inactiveIcon: IconsaxPlusLinear.home_2,
      ),
      AppleGlassNavItem(
        activeIcon: IconsaxPlusBold.heart,
        inactiveIcon: IconsaxPlusLinear.heart,
      ),
      AppleGlassNavItem(
        activeIcon: IconsaxPlusBold.box,
        inactiveIcon: IconsaxPlusLinear.box,
      ),
      AppleGlassNavItem(
        activeIcon: IconsaxPlusBold.video_play,
        inactiveIcon: IconsaxPlusLinear.video_play,
      ),
      AppleGlassNavItem(
        activeIcon: IconsaxPlusBold.user,
        inactiveIcon: IconsaxPlusLinear.user,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Obx(() {
        final selectedIdx = controller.currentIndex.value;

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true, // Allows translucent glass effect to float seamlessly over content
          body: Stack(
            children: [
              IndexedStack(
                index: selectedIdx,
                children: screens,
              ),

              // Floating WhatsApp Action Button on the RIGHT (above bottom glass bar)
              if (selectedIdx != 3) // Hide during full-screen video reels for uninterrupted viewing
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom > 0 ? 84 : 90,
                  right: 18,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
                    child: InkWell(
                      onTap: controller.showWhatsAppDialog,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            IconsaxPlusBold.messages_2,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Apple TV / iOS Floating Glassmorphic Pill Navigation Bar (Icons Only)
          bottomNavigationBar: AppleGlassNavBar(
            selectedIndex: selectedIdx,
            onTabSelected: (index) => controller.onTabTapped(index),
            items: navItems,
            badgeCounts: [
              0,
              0,
              Get.isRegistered<NotificationService>()
                  ? Get.find<NotificationService>().unreadCount.value
                  : 0,
              0,
              0,
            ],
          ),
        );
      }),
    );
  }
}
