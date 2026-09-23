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
    // Handled via handleScrollNotification
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollMetricsNotification) {
      return false;
    }

    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return false;
    }

    final m = notification.metrics;
    if (m.axis != Axis.vertical || m.maxScrollExtent <= 0) {
      return false;
    }

    // 1. Actively scrolling downwards (finger drag or momentum fling)
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null && delta > 0) {
        if (m.pixels >= m.maxScrollExtent - 350 && m.pixels > 150) {
          loadMoreProducts();
        }
      }
    }
    // 2. iOS Bouncing physics: overscroll at the bottom (user pulling up past end)
    else if (notification is OverscrollNotification) {
      if (notification.overscroll > 0 && m.pixels > 150) {
        loadMoreProducts();
      }
    }
    // 3. Fling inertia or gesture ended near bottom
    else if (notification is ScrollEndNotification) {
      if (m.pixels >= m.maxScrollExtent - 350 && m.pixels > 150) {
        loadMoreProducts();
      }
    }

    return false;
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
    if (isLoadingMore.value || !hasMore.value) return;
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
