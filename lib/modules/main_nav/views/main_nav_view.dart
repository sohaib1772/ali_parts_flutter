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
      const SizedBox.shrink(), // WhatsApp tab
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
        activeIcon: IconsaxPlusBold.messages_2,
        inactiveIcon: IconsaxPlusLinear.messages_2,
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
          body: IndexedStack(
            index: selectedIdx,
            children: screens,
          ),

          // Apple TV / iOS Floating Glassmorphic Pill Navigation Bar (Icons Only)
          bottomNavigationBar: AppleGlassNavBar(
            selectedIndex: selectedIdx,
            onTabSelected: (index) => controller.changeTab(index),
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
