import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../../../core/utils/responsive_grid_helper.dart';
import '../../products/widgets/product_card_widget.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesService>();

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.background,
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'المفضلة',
              ),
              Expanded(
                child: Stack(
                  children: [
                    Obx(() {
                      if (favorites.favoriteProducts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cardWhite,
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: const Icon(IconsaxPlusBold.heart, color: AppColors.gold, size: 54),
                              ),
                              const SizedBox(height: 16),
                              const Text('قائمة المفضلة فارغة', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('احفظ قطع الغيار المفضلة لديك بالضغط على رمز القلب', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: favorites.favoriteProducts.length,
                        gridDelegate: ResponsiveGridHelper.getProductGridDelegate(context),
                        itemBuilder: (ctx, i) {
                          return ProductCardWidget(product: favorites.favoriteProducts[i]);
                        },
                      );
                    }),

                    // Floating Glass Scroll To Top Button
                    GlassScrollToTopButton(
                      scrollController: _scrollController,
                      bottom: 90,
                      left: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
