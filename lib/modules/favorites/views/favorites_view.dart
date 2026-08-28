import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../products/widgets/product_card_widget.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

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
                showBack: false,
              ),
              Expanded(
                child: Obx(() {
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
                            child: const Icon(Icons.favorite_border_rounded, color: AppColors.gold, size: 54),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: favorites.favoriteProducts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (ctx, i) {
                      return ProductCardWidget(product: favorites.favoriteProducts[i]);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
