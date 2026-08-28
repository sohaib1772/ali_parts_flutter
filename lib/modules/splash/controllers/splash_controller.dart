import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/settings_service.dart';

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

    Get.offAllNamed(AppRoutes.mainNav);
  }
}
