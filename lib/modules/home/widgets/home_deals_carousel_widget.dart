import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../products/widgets/product_card_widget.dart';

class HomeDealsCarouselWidget extends StatefulWidget {
  final List<ProductModel> deals;

  const HomeDealsCarouselWidget({super.key, required this.deals});

  @override
  State<HomeDealsCarouselWidget> createState() => _HomeDealsCarouselWidgetState();
}

class _HomeDealsCarouselWidgetState extends State<HomeDealsCarouselWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  int _currentScrollIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.deals.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_scrollController.hasClients) {
        _currentScrollIndex = (_currentScrollIndex + 1) % widget.deals.length;
        final targetOffset = _currentScrollIndex * 170.0;

        if (targetOffset > _scrollController.position.maxScrollExtent) {
          _currentScrollIndex = 0;
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: [عرض الكل >] on left, [عروض لفترة محدودة] on right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title on Right
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عروض لفترة محدودة',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'أسعار خاصة لفترة قصيرة',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  // See All Link on Left
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.products, arguments: {'title': 'عروض لفترة محدودة'}),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الكل',
                          style: TextStyle(
                            color: AppColors.goldDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.goldDark, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Deals Auto-Scrolling List (280 height gives ample room for cards)
            SizedBox(
              height: 280,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: widget.deals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  return SizedBox(
                    width: 158,
                    child: ProductCardWidget(product: widget.deals[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
