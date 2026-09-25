import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/youtube_helper.dart';
import '../../../data/models/banner_model.dart';
import '../../main_nav/controllers/main_nav_controller.dart';
import '../controllers/reels_controller.dart';
import '../widgets/reels_comments_sheet.dart';

class ReelsView extends StatefulWidget {
  final bool isInsideNavBar;
  const ReelsView({super.key, this.isInsideNavBar = false});

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> with WidgetsBindingObserver {
  final ReelsController controller = Get.put(ReelsController());
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.setTabVisible(true);
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      controller.handleNewArguments(args);
    } else {
      controller.refreshBanners();
    }
    _pageController = PageController(
      initialPage: controller.currentIndex.value,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.setTabVisible(false);
    } else if (state == AppLifecycleState.resumed) {
      controller.setTabVisible(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.setTabVisible(false);
    _pageController.dispose();
    super.dispose();
  }

  void _onVideoFinished(int index) {
    if (index != controller.currentIndex.value) return;
    if (controller.currentIndex.value < controller.banners.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else if (controller.banners.length > 1) {
      // Loop back to the first video
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
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
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && Get.isRegistered<MainNavController>()) {
            Get.find<MainNavController>().changeTab(0);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }

            if (controller.banners.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      IconsaxPlusBold.gallery,
                      color: Colors.white54,
                      size: 54,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'لا توجد عروض حالياً',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Get.back();
                        } else {
                          Get.offAllNamed(AppRoutes.mainNav);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0A192F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        'الرجوع للرئيسية',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
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
                    final isCurrentPage = controller.currentIndex.value == i;
                    final isEffectiveActive =
                        isCurrentPage && controller.isTabVisible.value;
                    return _ReelItemCard(
                      banner: banner,
                      isActive: isEffectiveActive,
                      isInsideNavBar: false,
                      controller: controller,
                      onVideoFinished: () => _onVideoFinished(i),
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
                      // Back Button (returns to Home tab)
                      InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Get.back();
                          } else {
                            Get.offAllNamed(AppRoutes.mainNav);
                          }
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      // Mute / Unmute Button
                      Obx(
                        () => InkWell(
                          onTap: controller.toggleMute,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              controller.isMuted.value
                                  ? IconsaxPlusBold.volume_cross
                                  : IconsaxPlusBold.volume_high,
                              color: Colors.white,
                              size: 19,
                            ),
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
      ),
    );
  }
}

class _ReelItemCard extends StatefulWidget {
  final BannerModel banner;
  final bool isActive;
  final bool isInsideNavBar;
  final ReelsController controller;
  final VoidCallback onVideoFinished;

  const _ReelItemCard({
    required this.banner,
    required this.isActive,
    required this.isInsideNavBar,
    required this.controller,
    required this.onVideoFinished,
  });

  @override
  State<_ReelItemCard> createState() => _ReelItemCardState();
}

class _ReelItemCardState extends State<_ReelItemCard>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoCtrl;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  Worker? _muteWorker;
  Worker? _tabWorker;
  bool _didTriggerEnd = false;

  // Video progress / seek bar
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _wasPlayingBeforeScrub = false;

  // Double tap to like heart animation
  late AnimationController _heartAnimCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  bool get _hasVideo =>
      widget.banner.videoUrl != null &&
      widget.banner.videoUrl!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _heartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_heartAnimCtrl);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_heartAnimCtrl);

    _muteWorker = ever(widget.controller.isMuted, (bool muted) {
      _videoCtrl?.setVolume(muted ? 0 : 1);
    });

    _tabWorker = ever(widget.controller.isTabVisible, (bool visible) {
      if (!visible) {
        _videoCtrl?.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else if (widget.isActive) {
        if (_videoCtrl != null && _isVideoInitialized) {
          if (_videoCtrl!.value.isCompleted ||
              (_totalDuration > Duration.zero &&
                  _currentPosition >=
                      _totalDuration - const Duration(milliseconds: 500))) {
            _videoCtrl!.seekTo(Duration.zero);
          }
          _videoCtrl!.play();
          if (mounted) setState(() => _isPlaying = true);
        }
      }
    });

    if (_hasVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasVideo && _videoCtrl != null) {
      if (widget.isActive && !oldWidget.isActive) {
        _didTriggerEnd = false;
        if (_videoCtrl!.value.isCompleted ||
            (_totalDuration > Duration.zero &&
                _currentPosition >=
                    _totalDuration - const Duration(milliseconds: 500))) {
          _videoCtrl!.seekTo(Duration.zero);
        }
        _videoCtrl!.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isActive && oldWidget.isActive) {
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
      String playUrl = rawUrl;
      if (YouTubeHelper.isYouTubeUrl(rawUrl)) {
        final streamUrl = await YouTubeHelper.resolveStreamUrl(rawUrl);
        if (streamUrl != null && streamUrl.isNotEmpty) {
          playUrl = streamUrl;
        } else {
          AppLogger.w(
            'Could not resolve stream URL for YouTube video: $rawUrl',
          );
        }
      }

      final uri = Uri.tryParse(playUrl);
      if (uri == null) return;

      final ctrl = VideoPlayerController.networkUrl(uri);
      _videoCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(
        false,
      ); // DO NOT loop so it triggers onVideoFinished
      await ctrl.setVolume(widget.controller.isMuted.value ? 0 : 1);
      ctrl.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _totalDuration = ctrl.value.duration;
          _currentPosition = ctrl.value.position;
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

  void _videoListener() {
    if (!mounted || _videoCtrl == null) return;
    final val = _videoCtrl!.value;
    if (!val.isInitialized) return;

    if (!_isScrubbing) {
      setState(() {
        _currentPosition = val.position;
        _totalDuration = val.duration;
        _isPlaying = val.isPlaying;
      });
    }

    // Detect video end & auto-advance
    if (widget.isActive && !_isScrubbing && !_didTriggerEnd) {
      final pos = val.position;
      final dur = val.duration;
      if (dur > const Duration(milliseconds: 500) &&
          (val.isCompleted || (pos >= dur && pos > Duration.zero))) {
        _didTriggerEnd = true;
        if (widget.controller.banners.length <= 1) {
          // If only 1 video in total, replay it
          _videoCtrl?.seekTo(Duration.zero);
          _videoCtrl?.play();
          _didTriggerEnd = false;
        } else {
          widget.onVideoFinished();
        }
      }
    } else if (_didTriggerEnd &&
        val.position < val.duration - const Duration(milliseconds: 500)) {
      _didTriggerEnd = false;
    }
  }

  @override
  void dispose() {
    _muteWorker?.dispose();
    _tabWorker?.dispose();
    _heartAnimCtrl.dispose();
    _videoCtrl?.removeListener(_videoListener);
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.controller.setLiked(widget.banner.id, liked: true);
    _heartAnimCtrl.forward(from: 0.0);
  }

  void _handleSingleTap() {
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

  void _startScrubbing(double dx, double width) {
    if (_totalDuration <= Duration.zero) return;
    HapticFeedback.selectionClick();
    _wasPlayingBeforeScrub = _videoCtrl?.value.isPlaying ?? false;
    _videoCtrl?.pause();
    final ratio = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _isScrubbing = true;
      _scrubPosition = _totalDuration * ratio;
    });
    _videoCtrl?.seekTo(_scrubPosition);
  }

  void _updateScrubbing(double dx, double width) {
    if (_totalDuration <= Duration.zero) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _scrubPosition = _totalDuration * ratio;
    });
    _videoCtrl?.seekTo(_scrubPosition);
  }

  void _endScrubbing() {
    if (!_isScrubbing) return;
    _didTriggerEnd = false;
    setState(() {
      _isScrubbing = false;
    });
    if (_wasPlayingBeforeScrub) {
      _videoCtrl?.play();
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Seek bar sits directly near the bottom screen edge
    final double seekBottom = bottomPadding > 0
        ? (bottomPadding * 0.25).clamp(4.0, 10.0)
        : 2.0;
    // Caption & Action rail baseline offset - comfortably positioned near the bottom
    final double contentBottom =
        (bottomPadding > 0 ? bottomPadding : 10.0) + 12.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSingleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media Layer (Video or Image)
          if (_hasVideo) _buildVideoLayer() else _buildImageLayer(),

          // Double Tap Heart Burst Animation
          AnimatedBuilder(
            animation: _heartAnimCtrl,
            builder: (ctx, child) {
              if (_heartAnimCtrl.isDismissed) return const SizedBox.shrink();
              return Center(
                child: Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.4 * _heartOpacity.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFEF4444),
                        size: 115,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Play/Pause subtle indicator on pause
          if (_hasVideo && !_isPlaying && _isVideoInitialized && !_isScrubbing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Bottom Gradient Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Rail (Heart, Comments, Share) - Lowered to bottom area
          Positioned(
            bottom: contentBottom,
            left: 14,
            child: Obx(() {
              final isLiked =
                  widget.controller.isLiked[widget.banner.id] ?? false;
              final likesCount =
                  widget.controller.likesCount[widget.banner.id] ?? 0;
              final commentsCount =
                  widget.controller.commentsCount[widget.banner.id] ?? 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like Button with count
                  _buildRailButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isLiked ? const Color(0xFFEF4444) : Colors.white,
                    label: '$likesCount',
                    onTap: () => widget.controller.toggleLike(widget.banner.id),
                  ),
                  const SizedBox(height: 14),

                  // Comments Button with count
                  _buildRailButton(
                    icon: IconsaxPlusBold.messages_2,
                    iconColor: Colors.white,
                    label: '$commentsCount',
                    onTap: () {
                      ReelsCommentsSheet.show(
                        context,
                        widget.banner.id,
                        onCommentAdded: () =>
                            widget.controller.onCommentAdded(widget.banner.id),
                        onCommentDeleted: () => widget.controller
                            .onCommentDeleted(widget.banner.id),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Share Button
                  _buildRailButton(
                    icon: Icons.share_rounded,
                    iconColor: Colors.white,
                    label: 'مشاركة',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final title =
                          widget.banner.titleAr ??
                          'عرض مميز من علي لقطع الغيار';
                      final link = widget.banner.link?.trim() ?? '';
                      final shareText = link.isNotEmpty
                          ? '$title\n$link\n\nتطبيق علي لقطع الغيار'
                          : '$title\n\nتطبيق علي لقطع الغيار';
                      Share.share(shareText, subject: title);
                    },
                  ),
                ],
              );
            }),
          ),

          // Bottom Caption (Title, Subtitle, Shop Button) - Lowered to align with action rail
          Positioned(
            bottom: contentBottom,
            right: 18,
            left: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.banner.titleAr != null &&
                    widget.banner.titleAr!.isNotEmpty)
                  Text(
                    widget.banner.titleAr!,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black),
                        Shadow(blurRadius: 18, color: Colors.black),
                      ],
                    ),
                  ),
                if (widget.banner.subtitleAr != null &&
                    widget.banner.subtitleAr!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.banner.subtitleAr!,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      height: 1.3,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black),
                        Shadow(blurRadius: 14, color: Colors.black),
                      ],
                    ),
                  ),
                ],
                if (widget.banner.link != null &&
                    widget.banner.link!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.banner.link!.trim());
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A192F),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    icon: const Icon(IconsaxPlusBold.shopping_cart, size: 15),
                    label: Text(
                      'تسوّق الآن',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Scrubbing Time Indicator Bubble
          if (_hasVideo && _isScrubbing && _totalDuration > Duration.zero)
            Positioned(
              bottom: contentBottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_formatDuration(_scrubPosition)} / ${_formatDuration(_totalDuration)}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          // Interactive Progress / Seek Bar (تقديم وتأخير) - Lowered right to the bottom edge
          if (_hasVideo &&
              _isVideoInitialized &&
              _totalDuration > Duration.zero)
            Positioned(
              left: 0,
              right: 0,
              bottom: seekBottom,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final width = constraints.maxWidth;
                    final effectivePos = _isScrubbing
                        ? _scrubPosition
                        : _currentPosition;
                    final ratio = _totalDuration.inMilliseconds > 0
                        ? (effectivePos.inMilliseconds /
                                  _totalDuration.inMilliseconds)
                              .clamp(0.0, 1.0)
                        : 0.0;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (d) =>
                          _startScrubbing(d.localPosition.dx, width),
                      onHorizontalDragUpdate: (d) =>
                          _updateScrubbing(d.localPosition.dx, width),
                      onHorizontalDragEnd: (_) => _endScrubbing(),
                      onHorizontalDragCancel: () => _endScrubbing(),
                      onTapDown: (d) =>
                          _startScrubbing(d.localPosition.dx, width),
                      onTapUp: (_) => _endScrubbing(),
                      onTapCancel: () => _endScrubbing(),
                      child: Container(
                        height: 28, // Generous touch target for easy seeking
                        color: Colors.transparent,
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            // Track background
                            Container(
                              height: _isScrubbing ? 5.5 : 2.5,
                              width: width,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            // Progress bar (Gold)
                            Container(
                              height: _isScrubbing ? 5.5 : 2.5,
                              width: width * ratio,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                boxShadow: _isScrubbing
                                    ? [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            // Thumb handle when scrubbing
                            if (_isScrubbing)
                              Positioned(
                                left: (width * ratio - 6).clamp(
                                  0.0,
                                  width - 12,
                                ),
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.white54,
          size: 54,
        ),
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
      borderRadius: BorderRadius.circular(100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(blurRadius: 4, color: Colors.black),
                Shadow(blurRadius: 8, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
