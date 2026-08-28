import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ProductModel) {
      product.value = args;
      isLoading.value = false;
    } else if (args is String) {
      loadProductById(args);
    }
  }

  Future<void> loadProductById(String id) async {
    isLoading.value = true;
    try {
      final p = await _productRepo.fetchProductById(id);
      product.value = p;
    } catch (_) {
    } finally {
      isLoading.value = false;
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
    selectedSide.value = side;
  }

  double get unitPrice => (selectedSide.value == 'PAIR')
      ? ((product.value?.priceIqd ?? 0.0) * 2)
      : (product.value?.priceIqd ?? 0.0);

  double get totalPrice => unitPrice * quantity.value;

  void addToCart() {
    if (product.value != null) {
      _cartService.addToCart(
        product.value!,
        quantity: quantity.value,
        side: selectedSide.value,
      );
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
}
