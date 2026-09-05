import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/car_model_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class HomeController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  final ScrollController scrollController = ScrollController();

  final RxBool isLoading = true.obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<BrandModel> brands = <BrandModel>[].obs;
  final RxList<CarModelModel> carModels = <CarModelModel>[].obs;
  final RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> deals = <ProductModel>[].obs;
  final RxList<ProductModel> bestSellers = <ProductModel>[].obs;

  // Infinite Scroll All Products State
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt totalProductsCount = 0.obs;
  final RxBool showScrollToTop = false.obs;
  int _offset = 0;
  static const int _pageSize = 20;

  // Filter Bar State
  final Rx<String?> selectedCategoryId = Rx<String?>(null);
  final Rx<String?> selectedBrandId = Rx<String?>(null);
  final Rx<String?> selectedCarModelId = Rx<String?>(null);

  bool get isFilterActive =>
      selectedCategoryId.value != null ||
      selectedBrandId.value != null ||
      selectedCarModelId.value != null;

  String get activeFilterSummary {
    final List<String> parts = [];
    if (selectedBrandId.value != null && selectedBrandValueText != 'الكل') {
      parts.add(selectedBrandValueText);
    }
    if (selectedCarModelId.value != null && selectedCarModelValueText != 'الكل') {
      parts.add(selectedCarModelValueText);
    }
    if (selectedCategoryId.value != null && selectedCategoryValueText != 'الكل') {
      parts.add(selectedCategoryValueText);
    }
    return parts.isEmpty ? 'كل القطع' : parts.join(' · ');
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadHomeData(refreshMetadata: true);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.hasClients) {
      // Toggle scroll to top button
      final shouldShow = scrollController.position.pixels > 500;
      if (showScrollToTop.value != shouldShow) {
        showScrollToTop.value = shouldShow;
      }

      // Infinite scroll load more
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 400) {
        if (!isLoading.value && !isLoadingMore.value && hasMore.value) {
          loadMoreProducts();
        }
      }
    }
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> loadHomeData({bool refreshMetadata = false}) async {
    isLoading.value = true;
    _offset = 0;
    hasMore.value = true;
    try {
      if (categories.isEmpty || refreshMetadata) {
        final metaResults = await Future.wait([
          _productRepo.fetchCategories(),
          _productRepo.fetchBrands(),
          _productRepo.fetchCarModels(),
          _productRepo.fetchBanners(),
        ]);
        categories.assignAll(metaResults[0] as List<CategoryModel>);
        brands.assignAll(metaResults[1] as List<BrandModel>);
        carModels.assignAll(metaResults[2] as List<CarModelModel>);
        banners.assignAll(metaResults[3] as List<BannerModel>);
      }

      if (!isFilterActive) {
        final promoResults = await Future.wait([
          _productRepo.fetchFeaturedProducts(),
          _productRepo.fetchDeals(),
          _productRepo.fetchBestSellers(),
        ]);
        featuredProducts.assignAll(promoResults[0]);
        deals.assignAll(promoResults[1]);
        bestSellers.assignAll(promoResults[2]);
      }

      final queryRes = await _productRepo.fetchProducts(
        categoryId: selectedCategoryId.value,
        brandId: selectedBrandId.value,
        carModelId: selectedCarModelId.value,
        offset: 0,
        limit: _pageSize,
      );

      allProducts.assignAll(queryRes.products);
      totalProductsCount.value = queryRes.totalCount;
      _offset = queryRes.products.length;
      hasMore.value = allProducts.length < totalProductsCount.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final res = await _productRepo.fetchProducts(
        categoryId: selectedCategoryId.value,
        brandId: selectedBrandId.value,
        carModelId: selectedCarModelId.value,
        offset: _offset,
        limit: _pageSize,
      );
      allProducts.addAll(res.products);
      totalProductsCount.value = res.totalCount;
      _offset += res.products.length;
      hasMore.value = allProducts.length < totalProductsCount.value;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
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
    loadHomeData();
  }
}
