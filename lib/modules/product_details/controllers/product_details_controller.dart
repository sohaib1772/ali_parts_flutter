import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class ProductDetailsController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  final CartService _cartService = Get.find<CartService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final SettingsService _settingsService = Get.find<SettingsService>();

  final RxBool isLoading = true.obs;
  final Rx<ProductModel?> product = Rx<ProductModel?>(null);
  final RxInt selectedImageIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final Rx<String?> selectedSide = Rx<String?>(null); // 'LH' | 'RH' | 'PAIR' | null

  final RxList<String> compatibleCarNames = <String>[].obs;
  final RxList<ProductModel> relatedProducts = <ProductModel>[].obs;
  final RxBool isLoadingRelated = false.obs;

  late final PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    final args = Get.arguments;
    if (args is ProductModel) {
      product.value = args;
      isLoading.value = false;
      _loadMetadata(args);
    } else if (args is String) {
      loadProductById(args);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void selectImage(int index) {
    selectedImageIndex.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> loadProductById(String id) async {
    isLoading.value = true;
    try {
      final p = await _productRepo.fetchProductById(id);
      product.value = p;
      if (p != null) {
        _loadMetadata(p);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _loadMetadata(ProductModel p) {
    loadCompatibleModels(p.compatibleModels);
    if (p.categoryId != null && p.categoryId!.isNotEmpty) {
      loadRelatedProducts(p.categoryId!, p.id);
    }
  }

  Future<void> loadCompatibleModels(List<String> modelIds) async {
    if (modelIds.isEmpty) {
      compatibleCarNames.clear();
      return;
    }
    try {
      final allModels = await _productRepo.fetchCarModels();
      final matched = allModels
          .where((m) => modelIds.contains(m.id))
          .map((m) => m.nameAr)
          .toList();
      compatibleCarNames.assignAll(matched);
    } catch (_) {}
  }

  Future<void> loadRelatedProducts(String categoryId, String currentId) async {
    isLoadingRelated.value = true;
    try {
      final res = await _productRepo.fetchProducts(
        categoryId: categoryId,
        limit: 8,
      );
      final filtered = res.products.where((p) => p.id != currentId).take(6).toList();
      relatedProducts.assignAll(filtered);
    } catch (_) {
    } finally {
      isLoadingRelated.value = false;
    }
  }

  bool get isFavorite => product.value != null && _favoritesService.isFavorite(product.value!.id);

  void toggleFavorite() {
    if (product.value != null) {
      _favoritesService.toggleFavorite(product.value!);
    }
  }

  void incrementQty() {
    if (product.value != null && quantity.value < product.value!.stockQty) {
      quantity.value++;
    }
  }

  void decrementQty() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void setSide(String? side) {
    if (product.value?.hasSideOptions == false) {
      selectedSide.value = null;
      return;
    }
    selectedSide.value = side;
  }

  double get unitPrice => (selectedSide.value == 'PAIR' && product.value?.hasSideOptions != false)
      ? ((product.value?.priceIqd ?? 0.0) * 2)
      : (product.value?.priceIqd ?? 0.0);

  double get totalPrice => unitPrice * quantity.value;

  void addToCart() {
    if (product.value != null) {
      _cartService.addToCart(
        product.value!,
        quantity: quantity.value,
        side: product.value!.hasSideOptions ? selectedSide.value : null,
      );
      Get.snackbar(
        'تمت الإضافة',
        'تمت إضافة ${product.value!.nameAr} إلى السلة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.navyMedium,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        borderRadius: 12,
      );
    }
  }

  void buyNow() {
    if (product.value != null) {
      final actualSide = product.value!.hasSideOptions ? selectedSide.value : null;
      final inCart = _cartService.cartItems.any(
        (item) => item.productId == product.value!.id && item.side == actualSide,
      );

      if (!inCart) {
        _cartService.addToCart(
          product.value!,
          quantity: quantity.value,
          side: actualSide,
        );
      }

      Get.toNamed(AppRoutes.cart);
    }
  }

  Future<void> askViaWhatsApp() async {
    if (product.value == null) return;
    final p = product.value!;
    final url = Formatters.generateWhatsAppUrl(
      phone: _settingsService.whatsappNumber,
      productName: p.nameAr,
      oemNumber: p.oemNumber,
      productUrl: 'https://maktabali.com/product/${p.id}',
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void shareProduct(BuildContext context) {
    if (product.value == null) return;
    final p = product.value!;
    final productUrl = 'https://maktabali.com/product/${p.id}';
    final shareText = '${p.nameAr}${p.oemNumber != null ? ' (OEM: ${p.oemNumber})' : ''}\n$productUrl';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مشاركة المنتج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // WhatsApp
                _buildShareItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF25D366),
                  title: 'واتساب',
                  onTap: () async {
                    Get.back();
                    final waUrl = Formatters.generateWhatsAppUrl(
                      phone: '',
                      message: shareText,
                    );
                    final uri = Uri.parse(waUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                // Facebook
                _buildShareItem(
                  icon: Icons.facebook_rounded,
                  color: const Color(0xFF1877F2),
                  title: 'فيسبوك',
                  onTap: () async {
                    Get.back();
                    final fbUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(productUrl)}';
                    final uri = Uri.parse(fbUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                // Copy link
                _buildShareItem(
                  icon: Icons.copy_rounded,
                  color: const Color(0xFF0A192F),
                  title: 'نسخ الرابط',
                  onTap: () {
                    Get.back();
                    Clipboard.setData(ClipboardData(text: productUrl));
                    Get.snackbar(
                      'تم النسخ',
                      'تم نسخ رابط المنتج إلى الحافظة',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.navyMedium,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      borderRadius: 12,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildShareItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
