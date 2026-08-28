import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
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
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: Colors.white,
              onRefresh: controller.loadHomeData,
              child: Column(
                children: [
                  // Deep Navy Sticky Top AppHeader
                  const HomeHeaderWidget(),

                  // Scrollable Light Body Content
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.gold),
                        );
                      }

                      return CustomScrollView(
                        slivers: [
                          // Filter Bar
                          const SliverToBoxAdapter(
                            child: HomeFilterBarWidget(),
                          ),

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
                                  childAspectRatio: 0.60, // Perfectly tight and snug
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
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.60,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => ProductCardWidget(product: controller.bestSellers[i]),
                                  childCount: controller.bestSellers.length,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
