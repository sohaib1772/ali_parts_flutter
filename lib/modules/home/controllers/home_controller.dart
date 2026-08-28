import 'package:get/get.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/car_model_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class HomeController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();

  final RxBool isLoading = true.obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<BrandModel> brands = <BrandModel>[].obs;
  final RxList<CarModelModel> carModels = <CarModelModel>[].obs;
  final RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> deals = <ProductModel>[].obs;
  final RxList<ProductModel> bestSellers = <ProductModel>[].obs;

  // Filter Bar State
  final Rx<String?> selectedCategoryId = Rx<String?>(null);
  final Rx<String?> selectedBrandId = Rx<String?>(null);
  final Rx<String?> selectedCarModelId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _productRepo.fetchCategories(),
        _productRepo.fetchBrands(),
        _productRepo.fetchCarModels(),
        _productRepo.fetchBanners(),
        _productRepo.fetchFeaturedProducts(),
        _productRepo.fetchDeals(),
        _productRepo.fetchBestSellers(),
      ]);

      categories.assignAll(results[0] as List<CategoryModel>);
      brands.assignAll(results[1] as List<BrandModel>);
      carModels.assignAll(results[2] as List<CarModelModel>);
      banners.assignAll(results[3] as List<BannerModel>);
      featuredProducts.assignAll(results[4] as List<ProductModel>);
      deals.assignAll(results[5] as List<ProductModel>);
      bestSellers.assignAll(results[6] as List<ProductModel>);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  String get selectedCategoryName {
    if (selectedCategoryId.value == null) return 'التصنيف: الكل';
    final cat = categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value);
    return cat != null ? 'التصنيف: ${cat.nameAr}' : 'التصنيف: الكل';
  }

  String get selectedCategoryValueText {
    if (selectedCategoryId.value == null) return 'الكل';
    final cat = categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value);
    return cat != null ? cat.nameAr : 'الكل';
  }

  String get selectedBrandName {
    if (selectedBrandId.value == null) return 'الماركة: الكل';
    final b = brands.firstWhereOrNull((item) => item.id == selectedBrandId.value);
    return b != null ? 'الماركة: ${b.nameAr}' : 'الماركة: الكل';
  }

  String get selectedBrandValueText {
    if (selectedBrandId.value == null) return 'الكل';
    final b = brands.firstWhereOrNull((item) => item.id == selectedBrandId.value);
    return b != null ? b.nameAr : 'الكل';
  }

  String get selectedCarModelName {
    if (selectedCarModelId.value == null) return 'السيارة: الكل';
    final m = carModels.firstWhereOrNull((item) => item.id == selectedCarModelId.value);
    return m != null ? 'السيارة: ${m.nameAr}' : 'السيارة: الكل';
  }

  String get selectedCarModelValueText {
    if (selectedCarModelId.value == null) return 'الكل';
    final m = carModels.firstWhereOrNull((item) => item.id == selectedCarModelId.value);
    return m != null ? m.nameAr : 'الكل';
  }

  void selectCategory(String? id) {
    selectedCategoryId.value = id;
    applyFilters();
  }

  void selectBrand(String? brandId) {
    selectedBrandId.value = brandId;
    if (brandId != null && selectedCarModelId.value != null) {
      final m = carModels.firstWhereOrNull((item) => item.id == selectedCarModelId.value);
      if (m != null && m.brandId != null && m.brandId != brandId) {
        selectedCarModelId.value = null;
      }
    }
    applyFilters();
  }

  void selectCarModel(String? modelId) {
    selectedCarModelId.value = modelId;
    if (modelId != null) {
      final m = carModels.firstWhereOrNull((item) => item.id == modelId);
      if (m != null && m.brandId != null && m.brandId!.isNotEmpty) {
        selectedBrandId.value = m.brandId;
      }
    }
    applyFilters();
  }

  void clearFilters() {
    selectedCategoryId.value = null;
    selectedBrandId.value = null;
    selectedCarModelId.value = null;
    loadHomeData();
  }

  void applyFilters() {
    // If any filter is active, fetch filtered products for featured/best-sellers
    loadHomeData();
  }
}
