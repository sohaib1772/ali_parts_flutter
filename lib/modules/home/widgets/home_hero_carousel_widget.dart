import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/banner_model.dart';

class HomeHeroCarouselWidget extends StatefulWidget {
  final List<BannerModel> banners;

  const HomeHeroCarouselWidget({super.key, required this.banners});

  @override
  State<HomeHeroCarouselWidget> createState() => _HomeHeroCarouselWidgetState();
}

class _HomeHeroCarouselWidgetState extends State<HomeHeroCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_pageController.hasClients) {
          final next = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onBannerTap(BannerModel banner, int index) {
    Get.toNamed(
      AppRoutes.reels,
      arguments: {
        'banners': widget.banners,
        'initialIndex': index,
        'targetBannerId': banner.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = (screenWidth * 0.42).clamp(175.0, 320.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Container(
            height: bannerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: widget.banners.length,
              itemBuilder: (ctx, i) {
                final banner = widget.banners[i];
                final hasVideo = banner.videoUrl != null && banner.videoUrl!.isNotEmpty;

                return GestureDetector(
                  onTap: () => _onBannerTap(banner, i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Image or Video Card
                      if (banner.imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: Formatters.thumbUrl(banner.imageUrl, width: 900),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF0F1E36),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF0F1E36),
                            child: const Icon(Icons.broken_image_rounded, color: AppColors.gold, size: 36),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0A192F), Color(0xFF1E293B)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(IconsaxPlusBold.video_play, color: AppColors.gold, size: 44),
                          ),
                        ),

                      // Gradient Overlay for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top Exclusive Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A192F).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconsaxPlusBold.star_1, size: 12, color: AppColors.gold),
                              SizedBox(width: 4),
                              Text(
                                'عرض خاص',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Video Play Indicator if Video is attached
                      if (hasVideo)
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF0A192F),
                              size: 28,
                            ),
                          ),
                        ),

                      // Bottom Text Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (banner.titleAr != null && banner.titleAr!.isNotEmpty)
                                Text(
                                  banner.titleAr!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (banner.subtitleAr != null && banner.subtitleAr!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  banner.subtitleAr!,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Indicator Dots
          if (widget.banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.gold : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
