import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class ProductsController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  final ScrollController scrollController = ScrollController();

  final products = <ProductModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final totalCount = 0.obs;
  final pageTitle = 'المنتجات'.obs;
  final selectedCondition = 'all'.obs;

  String? categoryId;
  String? brandId;
  String? carModelId;
  String? searchQuery;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      categoryId = args['categoryId'] as String?;
      brandId = args['brandId'] as String?;
      carModelId = args['carModelId'] as String?;
      searchQuery = args['searchQuery'] as String?;
      if (args['title'] != null) {
        pageTitle.value = args['title'] as String;
      }
    }
    loadProducts();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 300) {
      if (!isLoading.value && !isLoadingMore.value && hasMore.value) {
        loadMoreProducts();
      }
    }
  }

  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      _offset = 0;
      hasMore.value = true;
      final res = await _productRepo.fetchProducts(
        categoryId: categoryId,
        brandId: brandId,
        carModelId: carModelId,
        condition: selectedCondition.value,
        searchQuery: searchQuery,
        offset: 0,
        limit: _pageSize,
      );
      products.assignAll(res.products);
      totalCount.value = res.totalCount;
      _offset = res.products.length;
      hasMore.value = products.length < totalCount.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    try {
      isLoadingMore.value = true;
      final res = await _productRepo.fetchProducts(
        categoryId: categoryId,
        brandId: brandId,
        carModelId: carModelId,
        condition: selectedCondition.value,
        searchQuery: searchQuery,
        offset: _offset,
        limit: _pageSize,
      );
      products.addAll(res.products);
      totalCount.value = res.totalCount;
      _offset += res.products.length;
      hasMore.value = products.length < totalCount.value;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setCondition(String cond) {
    selectedCondition.value = cond;
    loadProducts();
  }
}
