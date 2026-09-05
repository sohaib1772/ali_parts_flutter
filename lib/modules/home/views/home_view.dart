import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/home_filter_bar_widget.dart';
import '../widgets/home_hero_carousel_widget.dart';
import '../widgets/home_categories_grid_widget.dart';
import '../widgets/home_deals_carousel_widget.dart';
import '../../products/widgets/product_card_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navyDark, // Dark navy status bar
        body: SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.background, // Light body background
            child: Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: Colors.white,
                  onRefresh: controller.loadHomeData,
                  child: Column(
                    children: [
                      // Deep Navy Sticky Top AppHeader
                      const HomeHeaderWidget(),

                      // Scrollable Light Body Content with Infinite Scroll
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.gold),
                            );
                          }

                          return CustomScrollView(
                            controller: controller.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Filter Bar
                              const SliverToBoxAdapter(
                                child: HomeFilterBarWidget(),
                              ),

                              // ─── Case A: Filter is Active (Show Filtered Results Grid like Search) ───
                              if (controller.isFilterActive) ...[
                                // Active Filter Header
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(IconsaxPlusBold.filter_search, color: AppColors.gold, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'نتائج الفلترة (${controller.totalProductsCount.value} منتج)',
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: controller.clearFilters,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1F2),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFFFECDD3)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(IconsaxPlusBold.close_circle, size: 14, color: Color(0xFFDC2626)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'مسح الفلترة',
                                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontFamily: 'Cairo'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Filter Summary Chip
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusBold.car, size: 16, color: Color(0xFF0A192F)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              controller.activeFilterSummary,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Empty State if No Products Match Filter
                                if (controller.allProducts.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1F5F9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(IconsaxPlusBold.search_status, color: Color(0xFF94A3B8), size: 36),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'لا توجد قطع غيار مطابقة',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'لم يتم العثور على قطع غيار لـ (${controller.activeFilterSummary}). جرب اختيار خيارات أخرى أو مسح الفلترة.',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF64748B),
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: controller.clearFilters,
                                            icon: const Icon(IconsaxPlusBold.refresh, size: 16),
                                            label: const Text('مسح الفلترة وعرض كل المنتجات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0A192F),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  // Grid of Filtered Products
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.58,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => ProductCardWidget(product: controller.allProducts[i]),
                                        childCount: controller.allProducts.length,
                                      ),
                                    ),
                                  ),
                              ] else ...[
                                // ─── Case B: No Filter Active (Show Full Rich Home Page) ───
                                // Hero Carousel (Banners)
                                if (controller.banners.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: HomeHeroCarouselWidget(banners: controller.banners),
                                  ),

                                // Categories Grid (3 Columns)
                                SliverToBoxAdapter(
                                  child: HomeCategoriesGridWidget(categories: controller.categories),
                                ),

                                // Limited Time Deals Carousel (Auto-Scrolling Slider)
                                if (controller.deals.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: HomeDealsCarouselWidget(deals: controller.deals),
                                  ),

                                // Featured Products Section Title "منتجات مميزة ✦"
                                if (controller.featuredProducts.isNotEmpty) ...[
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'منتجات مميزة',
                                            style: TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.58,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => ProductCardWidget(product: controller.featuredProducts[i]),
                                        childCount: controller.featuredProducts.length,
                                      ),
                                    ),
                                  ),
                                ],

                                // Best Sellers Section Title
                                if (controller.bestSellers.isNotEmpty) ...[
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                                      child: Row(
                                        children: [
                                          Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'الأكثر طلباً ومبيعاً',
                                            style: TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.58,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => ProductCardWidget(product: controller.bestSellers[i]),
                                        childCount: controller.bestSellers.length,
                                      ),
                                    ),
                                  ),
                                ],

                                // Infinite Scroll: All Products Section Title
                                if (controller.allProducts.isNotEmpty) ...[
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                                      child: Row(
                                        children: [
                                          Icon(Icons.grid_view_rounded, color: AppColors.gold, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'جميع المنتجات',
                                            style: TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.58,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => ProductCardWidget(product: controller.allProducts[i]),
                                        childCount: controller.allProducts.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                              // Loading More Indicator (Bottom of Infinite Scroll)
                              if (controller.isLoadingMore.value)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppColors.gold),
                                    ),
                                  ),
                                ),

                              // Bottom space for floating bottom navigation bar
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 95),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Reusable Glassmorphic Animated "Scroll to Top" Button on the LEFT
                GlassScrollToTopButton(
                  scrollController: controller.scrollController,
                  bottom: 82,
                  left: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
