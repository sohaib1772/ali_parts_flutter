import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/home_hero_carousel_widget.dart';
import '../widgets/home_categories_grid_widget.dart';
import '../widgets/home_deals_carousel_widget.dart';
import '../../products/widgets/product_card_widget.dart';
import '../../../core/utils/responsive_grid_helper.dart';

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

                          return NotificationListener<ScrollNotification>(
                            onNotification: controller.handleScrollNotification,
                            child: CustomScrollView(
                              controller: controller.scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
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
                                      gridDelegate: ResponsiveGridHelper.getProductGridDelegate(context),
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
                                      gridDelegate: ResponsiveGridHelper.getProductGridDelegate(context),
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
                                      gridDelegate: ResponsiveGridHelper.getProductGridDelegate(context),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => ProductCardWidget(product: controller.allProducts[i]),
                                        childCount: controller.allProducts.length,
                                      ),
                                    ),
                                  ),
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
                                child: SizedBox(height: 120),
                              ),
                            ],
                          ));
                        }),
                      ),
                    ],
                  ),
                ),

                // Reusable Glassmorphic Animated "Scroll to Top" Button on the LEFT
                GlassScrollToTopButton(
                  scrollController: controller.scrollController,
                  bottom: 90,
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
