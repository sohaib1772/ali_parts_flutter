import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../app/config/api_constants.dart';
import '../../app/config/app_constants.dart';
import '../../data/models/product_model.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

class FavoritesService extends GetxService {
  final GetStorage _box = GetStorage();
  static const String _storageKey = 'favorite_product_ids';
  static const String _productsStorageKey = 'favorite_products_cache';

  final RxSet<String> favoriteIds = <String>{}.obs;
  final RxList<ProductModel> favoriteProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _checkAndSync();
  }

  void _checkAndSync() async {
    final sec = Get.find<SecureStorageService>();
    final userId = await sec.read(AppConstants.secureKeyUserId);
    if (userId != null && userId.isNotEmpty) {
      await syncWithServer(userId);
    }
  }

  Future<FavoritesService> init() async {
    final stored = _box.read<List>(_storageKey);
    if (stored != null) {
      favoriteIds.addAll(stored.cast<String>());
    }

    final storedProducts = _box.read<List>(_productsStorageKey);
    if (storedProducts != null) {
      try {
        favoriteProducts.assignAll(
          storedProducts.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        );
      } catch (e) {
        AppLogger.e('Error loading cached favorite products', e);
      }
    }
    return this;
  }

  bool isFavorite(String productId) => favoriteIds.contains(productId);

  void toggleFavorite(ProductModel product) {
    if (favoriteIds.contains(product.id)) {
      favoriteIds.remove(product.id);
      favoriteProducts.removeWhere((p) => p.id == product.id);
      _removeFromServer(product.id);
    } else {
      favoriteIds.add(product.id);
      if (!favoriteProducts.any((p) => p.id == product.id)) {
        favoriteProducts.add(product);
      }
      _addToServer(product.id);
    }
    _saveToStorage();
  }

  Future<void> syncWithServer(String userId) async {
    try {
      final dio = Get.find<DioClient>().dio;
      AppLogger.d('Syncing favorites with server for user $userId...');
      final res = await dio.get(
        ApiConstants.favorites,
        queryParameters: {
          'select': 'id,user_id,product_id,product:products(*)',
          'user_id': 'eq.$userId',
        },
      );
      AppLogger.d('Favorites sync response: ${res.statusCode}');

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final List<ProductModel> prods = [];
        final Set<String> ids = {};

        for (final item in res.data as List) {
          final m = item as Map<String, dynamic>;
          final pid = m['product_id'] as String?;
          if (pid != null) ids.add(pid);
          if (m['product'] != null) {
            prods.add(ProductModel.fromJson(m['product'] as Map<String, dynamic>));
          } else if (m['products'] != null) {
            prods.add(ProductModel.fromJson(m['products'] as Map<String, dynamic>));
          }
        }

        if (ids.isNotEmpty) {
          favoriteIds.assignAll(ids);
          favoriteProducts.assignAll(prods);
          _saveToStorage();
        } else if (favoriteIds.isNotEmpty) {
          for (final pid in favoriteIds) {
            _addToServer(pid);
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error syncing favorites with server', e);
    }
  }

  void _addToServer(String productId) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.post(
        ApiConstants.favorites,
        data: {'user_id': userId, 'product_id': productId},
        options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
      );
    } catch (e) {
      AppLogger.e('Error adding favorite to server', e);
    }
  }

  void _removeFromServer(String productId) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.delete(
        ApiConstants.favorites,
        queryParameters: {'user_id': 'eq.$userId', 'product_id': 'eq.$productId'},
      );
    } catch (e) {
      AppLogger.e('Error removing favorite from server', e);
    }
  }

  void clearLocalCache() {
    favoriteIds.clear();
    favoriteProducts.clear();
    _box.remove(_storageKey);
    _box.remove(_productsStorageKey);
  }

  void _saveToStorage() {
    _box.write(_storageKey, favoriteIds.toList());
    _box.write(_productsStorageKey, favoriteProducts.map((p) => p.toJson()).toList());
  }
}
