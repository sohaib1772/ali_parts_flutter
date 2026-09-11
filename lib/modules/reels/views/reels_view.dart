import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/banner_model.dart';
import '../controllers/reels_controller.dart';
import '../widgets/reels_comments_sheet.dart';

class ReelsView extends StatefulWidget {
  const ReelsView({super.key});

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> {
  final ReelsController controller = Get.put(ReelsController());
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: controller.currentIndex.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          if (controller.isLoading.value && controller.banners.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (controller.banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(IconsaxPlusBold.gallery, color: Colors.white54, size: 54),
                  const SizedBox(height: 14),
                  Text(
                    'لا توجد عروض حالياً',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A192F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text('الرجوع للرئيسية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // 1. Vertical Reels PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: controller.banners.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (ctx, i) {
                  final banner = controller.banners[i];
                  final isActive = controller.currentIndex.value == i;
                  return _ReelItemCard(
                    banner: banner,
                    isActive: isActive,
                    controller: controller,
                  );
                },
              ),

              // 2. Top Navigation & Header
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                      ),
                    ),

                    // Mute / Unmute Button
                    InkWell(
                      onTap: controller.toggleMute,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          controller.isMuted.value ? IconsaxPlusBold.volume_cross : IconsaxPlusBold.volume_high,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ReelItemCard extends StatefulWidget {
  final BannerModel banner;
  final bool isActive;
  final ReelsController controller;

  const _ReelItemCard({
    required this.banner,
    required this.isActive,
    required this.controller,
  });

  @override
  State<_ReelItemCard> createState() => _ReelItemCardState();
}

class _ReelItemCardState extends State<_ReelItemCard> {
  VideoPlayerController? _videoCtrl;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showHeartBurst = false;
  DateTime _lastTap = DateTime.now();

  bool get _hasVideo => widget.banner.videoUrl != null && widget.banner.videoUrl!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasVideo && _videoCtrl != null) {
      if (widget.isActive && !_videoCtrl!.value.isPlaying) {
        _videoCtrl!.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isActive && _videoCtrl!.value.isPlaying) {
        _videoCtrl!.pause();
        setState(() => _isPlaying = false);
      }
      _videoCtrl!.setVolume(widget.controller.isMuted.value ? 0 : 1);
    }
  }

  Future<void> _initVideo() async {
    final rawUrl = widget.banner.videoUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return;
    try {
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) return;

      final ctrl = VideoPlayerController.networkUrl(uri);
      _videoCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(widget.controller.isMuted.value ? 0 : 1);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        if (widget.isActive) {
          ctrl.play();
          setState(() => _isPlaying = true);
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing video player: $e');
      if (mounted) setState(() => _isVideoInitialized = false);
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 350) {
      // Double tap -> Like!
      widget.controller.toggleLike(widget.banner.id);
      setState(() => _showHeartBurst = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showHeartBurst = false);
      });
      return;
    }
    _lastTap = now;

    // Single tap -> Play / Pause
    if (_hasVideo && _videoCtrl != null && _isVideoInitialized) {
      if (_videoCtrl!.value.isPlaying) {
        _videoCtrl!.pause();
        setState(() => _isPlaying = false);
      } else {
        _videoCtrl!.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media Layer (Video or Image)
          if (_hasVideo)
            _buildVideoLayer()
          else
            _buildImageLayer(),

          // Double Tap Heart Burst Animation
          if (_showHeartBurst)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.2),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (ctx, val, child) {
                  return Transform.scale(
                    scale: val,
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 110,
                    ),
                  );
                },
              ),
            ),

          // Play/Pause subtle indicator on pause
          if (_hasVideo && !_isPlaying && _isVideoInitialized)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
              ),
            ),

          // Bottom Gradient Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Action Rail (Heart, Comments)
          Positioned(
            bottom: 110,
            left: 14,
            child: Obx(() {
              final isLiked = widget.controller.isLiked[widget.banner.id] ?? false;
              final likesCount = widget.controller.likesCount[widget.banner.id] ?? 0;
              final commentsCount = widget.controller.commentsCount[widget.banner.id] ?? 0;

              return Column(
                children: [
                  // Like Button with count
                  _buildRailButton(
                    icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: isLiked ? const Color(0xFFEF4444) : Colors.white,
                    label: '$likesCount',
                    onTap: () => widget.controller.toggleLike(widget.banner.id),
                  ),
                  const SizedBox(height: 18),

                  // Comments Button with count
                  _buildRailButton(
                    icon: IconsaxPlusBold.messages_2,
                    iconColor: Colors.white,
                    label: '$commentsCount',
                    onTap: () {
                      ReelsCommentsSheet.show(
                        context,
                        widget.banner.id,
                        onCommentAdded: () => widget.controller.onCommentAdded(widget.banner.id),
                        onCommentDeleted: () => widget.controller.onCommentDeleted(widget.banner.id),
                      );
                    },
                  ),
                ],
              );
            }),
          ),

          // Bottom Caption (Title, Subtitle, Shop Button)
          Positioned(
            bottom: 30,
            right: 18,
            left: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.banner.titleAr != null && widget.banner.titleAr!.isNotEmpty)
                  Text(
                    widget.banner.titleAr!,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                if (widget.banner.subtitleAr != null && widget.banner.subtitleAr!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.banner.subtitleAr!,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.3,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ],
                if (widget.banner.link != null && widget.banner.link!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.banner.link!.trim());
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A192F),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: const Icon(IconsaxPlusBold.shopping_cart, size: 16),
                    label: Text(
                      'تسوّق الآن',
                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_isVideoInitialized && _videoCtrl != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        ),
      );
    }

    if (widget.banner.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.banner.imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        errorWidget: (_, __, ___) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    );
  }

  Widget _buildImageLayer() {
    if (widget.banner.imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0A192F),
        child: const Center(
          child: Icon(IconsaxPlusBold.gallery, color: Colors.white24, size: 64),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.banner.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 54),
      ),
    );
  }

  Widget _buildRailButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
