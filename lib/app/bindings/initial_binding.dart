import 'package:get/get.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/replacement_repository.dart';
import '../../data/repositories/reels_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final secureStorage = Get.find<SecureStorageService>();

    // Dio Client
    final dioClient = DioClient(secureStorage);
    Get.put<DioClient>(dioClient, permanent: true);

    // Services
    final settingsService = SettingsService(dioClient);
    Get.put<SettingsService>(settingsService, permanent: true);

    final cartService = CartService();
    Get.put<CartService>(cartService, permanent: true);

    final favoritesService = FavoritesService();
    Get.put<FavoritesService>(favoritesService, permanent: true);

    // Repositories
    Get.put<ProductRepository>(ProductRepository(dioClient), permanent: true);
    Get.put<OrderRepository>(OrderRepository(dioClient), permanent: true);
    Get.put<ReplacementRepository>(ReplacementRepository(dioClient), permanent: true);
    Get.put<ReelsRepository>(ReelsRepository(), permanent: true);
  }
}
