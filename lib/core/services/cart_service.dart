import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../app/config/api_constants.dart';
import '../../app/config/app_constants.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

class CartService extends GetxService {
  final GetStorage _box = GetStorage();
  static const String _storageKey = 'local_cart_items';

  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxInt cartCount = 0.obs;
  final RxBool cartBump = false.obs;

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

  Future<CartService> init() async {
    final stored = _box.read<List>(_storageKey);
    if (stored != null) {
      try {
        final items = stored
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        cartItems.assignAll(items);
        _updateCount();
      } catch (e) {
        AppLogger.e('Error reading cart from storage', e);
      }
    }
    return this;
  }

  void _updateCount() {
    cartCount.value = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  void triggerBump() {
    cartBump.value = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      cartBump.value = false;
    });
  }

  void addToCart(ProductModel product, {int quantity = 1, String? side, String? note}) async {
    final existingIndex = cartItems.indexWhere(
      (item) => item.productId == product.id && item.side == side,
    );

    if (existingIndex != -1) {
      final current = cartItems[existingIndex];
      final newQty = current.quantity + quantity;
      final updated = current.copyWith(
        quantity: newQty,
        product: product,
      );
      cartItems[existingIndex] = updated;
      _updateQuantityOnServer(current.id, newQty);
    } else {
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      final newItem = CartItemModel(
        id: localId,
        productId: product.id,
        quantity: quantity,
        side: side,
        note: note,
        product: product,
      );
      cartItems.add(newItem);
      _addItemToServer(product.id, quantity, side, note);
    }

    _updateCount();
    _save();
    triggerBump();
    Get.snackbar(
      'تمت الإضافة',
      'تمت إضافة ${product.nameAr} إلى السلة',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.navyMedium,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
    );
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updated = cartItems[index].copyWith(quantity: newQuantity);
      cartItems[index] = updated;
      _updateCount();
      _save();
      _updateQuantityOnServer(itemId, newQuantity);
    }
  }

  void updateSide(String itemId, String? newSide) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final current = cartItems[index];
    if (current.side == newSide) return;

    final existingIndex = cartItems.indexWhere(
      (item) => item.id != itemId && item.productId == current.productId && item.side == newSide,
    );

    if (existingIndex != -1) {
      final existing = cartItems[existingIndex];
      final merged = existing.copyWith(quantity: existing.quantity + current.quantity);
      cartItems[existingIndex] = merged;
      cartItems.removeAt(index);
      _deleteItemFromServer(current.id);
      _updateQuantityOnServer(existing.id, merged.quantity);
    } else {
      final updated = current.copyWith(side: newSide);
      cartItems[index] = updated;
      _updateSideOnServer(itemId, newSide);
    }

    _updateCount();
    _save();
  }

  void updateNote(String itemId, String? note) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final trimmed = note == null || note.trim().isEmpty ? null : note.trim();
      final updated = cartItems[index].copyWith(note: trimmed);
      cartItems[index] = updated;
      _save();
      _updateNoteOnServer(itemId, trimmed);
    }
  }

  void removeItem(String itemId) {
    cartItems.removeWhere((item) => item.id == itemId);
    _updateCount();
    _save();
    _deleteItemFromServer(itemId);
  }

  void clearCart() async {
    cartItems.clear();
    _updateCount();
    _save();

    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.delete(
        ApiConstants.cartItems,
        queryParameters: {'user_id': 'eq.$userId'},
      );
    } catch (e) {
      AppLogger.e('Error clearing server cart', e);
    }
  }

  void clearLocalCache() {
    cartItems.clear();
    _updateCount();
    _save();
  }

  double get subtotalIqd => cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFeeIqd => cartItems.isNotEmpty ? 5000.0 : 0.0;
  double get totalIqd => subtotalIqd + deliveryFeeIqd;

  Future<void> syncWithServer(String userId) async {
    try {
      final dio = Get.find<DioClient>().dio;
      AppLogger.d('Syncing cart with server for user $userId...');
      final res = await dio.get(
        ApiConstants.cartItems,
        queryParameters: {
          'select': 'id,user_id,product_id,quantity,side,note,product:products(*)',
          'user_id': 'eq.$userId',
        },
      );
      AppLogger.d('Cart sync response: ${res.statusCode}');

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final remoteList = (res.data as List).map((e) {
          final m = e as Map<String, dynamic>;
          ProductModel? prod;
          if (m['product'] != null) {
            prod = ProductModel.fromJson(m['product'] as Map<String, dynamic>);
          } else if (m['products'] != null) {
            prod = ProductModel.fromJson(m['products'] as Map<String, dynamic>);
          }
          return CartItemModel(
            id: m['id'] as String? ?? '',
            userId: m['user_id'] as String?,
            productId: m['product_id'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toInt() ?? 1,
            side: m['side'] as String?,
            note: m['note'] as String?,
            product: prod,
          );
        }).toList();

        cartItems.assignAll(remoteList);
        _updateCount();
        _save();
      }
    } catch (e) {
      AppLogger.e('Error syncing cart with server', e);
    }
  }

  void _addItemToServer(String productId, int quantity, String? side, String? note) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      // Use RPC add_cart_item
      await dio.post(
        ApiConstants.rpcAddCartItem,
        data: {
          'p_product_id': productId,
          'p_quantity': quantity,
          if (side != null) 'p_side': side,
        },
      );

      // Refresh to get the real server item id
      await syncWithServer(userId);
    } catch (e) {
      AppLogger.e('Error adding item to server cart', e);
    }
  }

  void _updateQuantityOnServer(String itemId, int quantity) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        ApiConstants.cartItems,
        queryParameters: {'id': 'eq.$itemId'},
        data: {'quantity': quantity},
      );
    } catch (e) {
      AppLogger.e('Error updating quantity on server', e);
    }
  }

  void _updateSideOnServer(String itemId, String? side) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        ApiConstants.cartItems,
        queryParameters: {'id': 'eq.$itemId'},
        data: {'side': side},
      );
    } catch (e) {
      AppLogger.e('Error updating side on server', e);
    }
  }

  void _updateNoteOnServer(String itemId, String? note) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        ApiConstants.cartItems,
        queryParameters: {'id': 'eq.$itemId'},
        data: {'note': note},
      );
    } catch (e) {
      AppLogger.e('Error updating note on server', e);
    }
  }

  void _deleteItemFromServer(String itemId) async {
    try {
      final sec = Get.find<SecureStorageService>();
      final userId = await sec.read(AppConstants.secureKeyUserId);
      if (userId == null || userId.isEmpty) return;

      final dio = Get.find<DioClient>().dio;
      await dio.delete(
        ApiConstants.cartItems,
        queryParameters: {'id': 'eq.$itemId'},
      );
    } catch (e) {
      AppLogger.e('Error deleting cart item from server', e);
    }
  }

  void _save() {
    _box.write(
      _storageKey,
      cartItems.map((item) => {
        'id': item.id,
        'product_id': item.productId,
        'quantity': item.quantity,
        'side': item.side,
        'note': item.note,
        'products': item.product?.toJson(),
      }).toList(),
    );
  }
}
