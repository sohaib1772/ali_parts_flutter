import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/widgets/common_filter_bar_widget.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/car_model_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../../products/widgets/product_card_widget.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _productRepo = Get.find<ProductRepository>();
  final _settings = Get.find<SettingsService>();
  final _cart = Get.find<CartService>();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _showScrollToTop = false;
  int _offset = 0;
  int _totalCount = 0;
  static const int _pageSize = 20;

  List<ProductModel> _results = [];

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<CarModelModel> _carModels = [];

  String? _selectedCategoryId;
  String? _selectedBrandId;
  String? _selectedCarModelId;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 350;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _loadMetadata() async {
    // Instant pre-population from HomeController cache if available
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      if (homeCtrl.categories.isNotEmpty) _categories = homeCtrl.categories.toList();
      if (homeCtrl.brands.isNotEmpty) _brands = homeCtrl.brands.toList();
      if (homeCtrl.carModels.isNotEmpty) _carModels = homeCtrl.carModels.toList();
    }

    try {
      final cats = await _productRepo.fetchCategories();
      final brs = await _productRepo.fetchBrands();
      final mods = await _productRepo.fetchCarModels();
      if (mounted) {
        setState(() {
          _categories = cats;
          _brands = brs;
          _carModels = mods;
        });
      }
    } catch (_) {}
  }

  void _triggerSearch() async {
    final q = _searchController.text.trim();
    final hasAnyFilter = q.isNotEmpty || _selectedCategoryId != null || _selectedBrandId != null || _selectedCarModelId != null;

    if (!hasAnyFilter) {
      setState(() {
        _results = [];
        _offset = 0;
        _totalCount = 0;
        _hasMore = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
      _results = [];
    });

    try {
      final res = await _productRepo.fetchProducts(
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        carModelId: _selectedCarModelId,
        searchQuery: q.isNotEmpty ? q : null,
        offset: 0,
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _results = res.products;
          _totalCount = res.totalCount;
          _offset = res.products.length;
          _hasMore = _results.length < _totalCount;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadMore() async {
    final q = _searchController.text.trim();
    setState(() => _isLoadingMore = true);

    try {
      final res = await _productRepo.fetchProducts(
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        carModelId: _selectedCarModelId,
        searchQuery: q.isNotEmpty ? q : null,
        offset: _offset,
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _results.addAll(res.products);
          _totalCount = res.totalCount;
          _offset += res.products.length;
          _hasMore = _results.length < _totalCount;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyFilter = _searchController.text.trim().isNotEmpty ||
        _selectedCategoryId != null ||
        _selectedBrandId != null ||
        _selectedCarModelId != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navyDark, // Dark status bar
        floatingActionButton: AnimatedScale(
          scale: _showScrollToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: FloatingActionButton(
            heroTag: 'search_scroll_to_top',
            onPressed: _scrollToTop,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navyDark,
            elevation: 8,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.gold, width: 1.8),
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.navyDark,
              size: 30,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // 1. Fixed Top AppHeader: Store Avatar + "بحث" + Cart Icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.navyDark,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Store Circular Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF102A43),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_filled_rounded,
                              color: AppColors.gold,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title "بحث" & Tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'بحث',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _settings.storeTagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Icon (Active indicator)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF132B45),
                        ),
                        child: const Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: 8),

                      // Notification Bell
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.orders),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF132B45),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Shopping Cart
                      Obx(() {
                        final count = _cart.cartCount.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.cart),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF132B45),
                                ),
                                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEAB308),
                                    border: Border.all(color: AppColors.navyDark, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                // 2. Full-Page Unified Scrollable Area
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // A. Search Input Field (Scrolls with page)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.gold, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: false,
                                    onChanged: (_) => _triggerSearch(),
                                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'ابحث عن قطعة، اسم أو رقم OEM...',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _triggerSearch();
                                    },
                                    child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // B. Common Filter Bar & Active Chips (Scrolls with page)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Builder(
                            builder: (context) {
                              final availableModels = _selectedBrandId != null
                                  ? _carModels.where((m) => m.brandId == _selectedBrandId).toList()
                                  : _carModels;

                              return CommonFilterBarWidget(
                                categories: _categories,
                                brands: _brands,
                                carModels: availableModels.isNotEmpty ? availableModels : _carModels,
                                selectedCategoryId: _selectedCategoryId,
                                selectedBrandId: _selectedBrandId,
                                selectedCarModelId: _selectedCarModelId,
                                onCategoryChanged: (id) {
                                  setState(() => _selectedCategoryId = id);
                                  _triggerSearch();
                                },
                                onBrandChanged: (brandId) {
                                  setState(() {
                                    _selectedBrandId = brandId;
                                    if (brandId != null && _selectedCarModelId != null) {
                                      final m = _carModels.firstWhereOrNull((item) => item.id == _selectedCarModelId);
                                      if (m != null && m.brandId != null && m.brandId != brandId) {
                                        _selectedCarModelId = null;
                                      }
                                    }
                                  });
                                  _triggerSearch();
                                },
                                onCarModelChanged: (modelId) {
                                  setState(() {
                                    _selectedCarModelId = modelId;
                                    if (modelId != null) {
                                      final m = _carModels.firstWhereOrNull((item) => item.id == modelId);
                                      if (m != null && m.brandId != null && m.brandId!.isNotEmpty) {
                                        _selectedBrandId = m.brandId;
                                      }
                                    }
                                  });
                                  _triggerSearch();
                                },
                                onClearAll: () {
                                  setState(() {
                                    _selectedCategoryId = null;
                                    _selectedBrandId = null;
                                    _selectedCarModelId = null;
                                  });
                                  _triggerSearch();
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // C. Loading / Empty State / No Results / Result Counter
                      if (_isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AppColors.gold),
                            ),
                          ),
                        )
                      else if (!hasAnyFilter)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.cardWhite,
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFFCBD5E1),
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ابحث عن القطع أو اختر تصنيفاً',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'اختر التصنيف، الماركة أو نوع السيارة من الفلاتر أعلاه، أو اكتب اسم القطعة أو رقمها.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (_results.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.cardWhite,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(
                                      Icons.sentiment_dissatisfied_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 44,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد نتائج مطابقة',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'جرّب تغيير الصنف أو نوع السيارة أو البحث برقم الـ OEM، أو تواصل معنا مباشرة عبر واتساب للمساعدة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Results Count Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              '$_totalCount نتيجة بحث',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // 2-Column Product Grid
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.60,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => ProductCardWidget(product: _results[i]),
                              childCount: _results.length,
                            ),
                          ),
                        ),

                        // Loading More Spinner at bottom
                        if (_isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
