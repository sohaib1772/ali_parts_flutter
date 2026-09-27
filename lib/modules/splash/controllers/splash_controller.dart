import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/force_update_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _startApp();
  }

  Future<void> _startApp() async {
    // Initialize fast services in parallel
    await Future.wait([
      Get.find<SettingsService>().init(),
      Get.find<CartService>().init(),
      Get.find<FavoritesService>().init(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    // Check for force update via force_update_helper client
    try {
      final client = ForceUpdateConfig.createClient();
      final isRequired = await client.isAppUpdateRequired();
      if (isRequired) {
        AppLogger.d('Force update required! ForceUpdateWidget will display the prompt.');
        return;
      }
    } catch (e) {
      AppLogger.e('Force update check failed', e);
    }

    Get.offAllNamed(AppRoutes.mainNav);
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().checkAndExecutePendingNotification();
    }
    if (Get.isRegistered<AuthService>()) {
      Get.find<AuthService>().checkAndExecutePendingDeepLink();
    }
  }
}
