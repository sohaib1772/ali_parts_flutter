import 'dart:io';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/settings_service.dart';
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

    // Check for force update
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final settings = Get.find<SettingsService>();
      final minVersion = Platform.isIOS ? settings.minAppVersionIos : settings.minAppVersionAndroid;

      AppLogger.d('Force update check: platform=${Platform.isIOS ? "iOS" : "Android"}, '
          'current=$currentVersion, required=$minVersion, '
          'settingsLoaded=${settings.settings.length}');

      if (SettingsService.isVersionOutdated(currentVersion, minVersion)) {
        AppLogger.d('Force update required! Redirecting to update screen');
        Get.offAllNamed(AppRoutes.forceUpdate, arguments: {
          'currentVersion': currentVersion,
          'minVersion': minVersion,
        });
        return;
      }
    } catch (e) {
      AppLogger.e('Force update check failed', e);
    }

    Get.offAllNamed(AppRoutes.mainNav);
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().checkAndExecutePendingNotification();
    }
  }
}
