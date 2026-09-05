import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive_grid_helper.dart';
import '../../../data/models/category_model.dart';

class HomeCategoriesGridWidget extends StatelessWidget {
  final List<CategoryModel> categories;

  const HomeCategoriesGridWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title "الأقسام ⊙"
          const Row(
            children: [
              Icon(Icons.radio_button_checked_rounded, color: AppColors.gold, size: 18),
              SizedBox(width: 6),
              Text(
                'الأقسام',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive Categories Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: ResponsiveGridHelper.getCategoryGridDelegate(context),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return GestureDetector(
                onTap: () {
                  Get.toNamed(AppRoutes.products, arguments: {'categoryId': cat.id, 'title': cat.nameAr});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Exact 1:1 Square Image Container (Identical size across all cards)
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.imageBg,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: Formatters.thumbUrl(cat.imageUrl, width: 250),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => Container(color: AppColors.imageBg),
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.settings_suggest_rounded,
                                      color: AppColors.gold,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.settings_suggest_rounded,
                                    color: AppColors.gold,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Fixed Category Title Container (Centered vertically for 1 or 2 lines)
                      Expanded(
                        child: Center(
                          child: Text(
                            cat.nameAr,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
