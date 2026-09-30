import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReelsView extends StatefulWidget {
  final bool isInsideNavBar;
  const ReelsView({super.key, this.isInsideNavBar = false});

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> with WidgetsBindingObserver {
  final ReelsController controller = Get.put(ReelsController());
  late PageController _pageController;
  Worker? _pageWorker;

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

    _pageWorker = ever(controller.currentIndex, (int targetIdx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pageController.hasClients) {
          final cur = _pageController.page?.round();
          if (cur != null && cur != targetIdx) {
            _pageController.jumpToPage(targetIdx);
          }
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller.setTabVisible(false);
      // When the user exits the app from Reels, automatically close Reels
      // so when the app is reopened or resumed, the user always lands on the Home screen (الرئيسية)
      if (mounted) {
        if (Get.isBottomSheetOpen == true) Get.back();
        if (Get.isDialogOpen == true) Get.back();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.offAllNamed(AppRoutes.mainNav);
        }
        if (Get.isRegistered<MainNavController>()) {
          Get.find<MainNavController>().changeTab(0);
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      controller.setTabVisible(false);
    } else if (state == AppLifecycleState.resumed) {
      controller.setTabVisible(true);
    }
  }

  @override
  void dispose() {
    _pageWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    controller.setTabVisible(false);
    _pageController.dispose();
    super.dispose();
  }

  void _onVideoFinished(int index) {
    // In reels, the current video loops continuously until the user swipes
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
                      key: ValueKey(banner.id),
                      banner: banner,
                      itemIndex: i,
                      isActive: isEffectiveActive,
                      isInsideNavBar: false,
                      controller: controller,
                      onVideoFinished: () => _onVideoFinished(i),
                    );
                  },
                ),

                // Top Black Mask (Covers YouTube Shorts logo, 3 dots, and headphone icon)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).padding.top + 45,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // Blocks taps to YouTube's header menu/search
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.black.withValues(alpha: 0.80),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 0.80, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Top Navigation & Header
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
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
  final int itemIndex;
  final bool isActive;
  final bool isInsideNavBar;
  final ReelsController controller;
  final VoidCallback onVideoFinished;

  const _ReelItemCard({
    super.key,
    required this.banner,
    required this.itemIndex,
    required this.isActive,
    required this.isInsideNavBar,
    required this.controller,
    required this.onVideoFinished,
  });

  @override
  State<_ReelItemCard> createState() => _ReelItemCardState();
}

class _ReelItemCardState extends State<_ReelItemCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _isVideoInitialized = false;
  bool _isYouTubeInitialized = false;
  bool _isPlaying = false;
  bool _userPaused = false;
  Worker? _pageWorker;
  Worker? _tabWorker;
  Worker? _muteWorker;
  bool _didTriggerEnd = false;
  bool _pendingPlay = false;
  bool _isCardActive = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isActive =>
      widget.controller.currentIndex.value == widget.itemIndex &&
      widget.controller.isTabVisible.value;

  // Video progress / seek bar
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(
    Duration.zero,
  );
  bool _wasPlayingBeforeScrub = false;

  // Double tap to like heart animation
  late AnimationController _heartAnimCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  bool get _hasVideo =>
      widget.banner.videoUrl != null &&
      widget.banner.videoUrl!.trim().isNotEmpty;

  bool get _isYouTube =>
      _hasVideo &&
      YouTubeHelper.isYouTubeUrl(widget.banner.videoUrl) &&
      YouTubeHelper.extractVideoId(widget.banner.videoUrl) != null;

  String? get _youTubeId =>
      _isYouTube ? YouTubeHelper.extractVideoId(widget.banner.videoUrl) : null;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

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
      if (_isYouTube && _ytCtrl != null) {
        if (muted) {
          _ytCtrl!.mute();
        } else {
          _ytCtrl!.unMute();
        }
      } else {
        _videoCtrl?.setVolume(muted ? 0 : 1);
      }
    });

    _pageWorker = ever(widget.controller.currentIndex, (int currentIdx) {
      final bool nowActive =
          currentIdx == widget.itemIndex &&
          widget.controller.isTabVisible.value;
      _handleActiveChanged(nowActive);
    });

    _tabWorker = ever(widget.controller.isTabVisible, (bool visible) {
      final bool nowActive =
          widget.controller.currentIndex.value == widget.itemIndex && visible;
      _handleActiveChanged(nowActive);
    });

    if (_isActive) {
      if (_isYouTube) {
        _initYouTube();
      } else if (_hasVideo) {
        _initVideo();
      }
    }
  }

  void _handleActiveChanged(bool active) {
    if (!mounted) return;
    if (_isCardActive == active && ((active && _isPlaying) || (!active && !_isPlaying))) {
      return;
    }
    _isCardActive = active;

    if (active) {
      _userPaused = false;
      _didTriggerEnd = false;
      if (_isYouTube) {
        if (_ytCtrl == null) {
          _initYouTube();
        } else {
          _pendingPlay = false;
          _ytCtrl!.play();
        }
        _safeSetState(() => _isPlaying = true);
      } else if (_hasVideo) {
        if (_videoCtrl == null) {
          _initVideo();
        } else if (_isVideoInitialized) {
          if (_videoCtrl!.value.isCompleted) {
            _videoCtrl!.seekTo(Duration.zero);
          }
          _videoCtrl!.play();
        }
        _safeSetState(() => _isPlaying = true);
      }
    } else {
      _userPaused = false;
      _pendingPlay = false;
      if (_isYouTube) {
        _ytCtrl?.pause();
      } else {
        _videoCtrl?.pause();
      }
      _safeSetState(() => _isPlaying = false);
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemIndex != oldWidget.itemIndex ||
        widget.isActive != oldWidget.isActive) {
      _handleActiveChanged(_isActive);
    }
  }

  void _initYouTube() {
    final videoId = _youTubeId;
    if (videoId == null) return;
    if (_ytCtrl != null) return;

    _pendingPlay = _isActive;

    final ytCtrl = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: _isActive,
        mute: widget.controller.isMuted.value,
        hideControls: true,
        controlsVisibleAtStart: false,
        disableDragSeek: true,
        enableCaption: false,
        loop: false,
        forceHD: false,
        hideThumbnail: true,
        useHybridComposition: true,
      ),
    );

    ytCtrl.addListener(_ytListener);
    _ytCtrl = ytCtrl;
    _isYouTubeInitialized = true;
    _safeSetState(() {});
  }

  void _ytListener() {
    if (!mounted || _ytCtrl == null) return;
    final val = _ytCtrl!.value;
    if (!val.isReady) return;

    // Trigger pending play when player becomes ready on an active reel
    if (_isActive && !_userPaused && _pendingPlay) {
      _pendingPlay = false;
      _ytCtrl!.play();
    }

    if (!_isScrubbing) {
      _totalDuration = val.metaData.duration;
      _positionNotifier.value = val.position;
      if (_isPlaying != val.isPlaying) {
        _safeSetState(() {
          _isPlaying = val.isPlaying;
        });
      }
    }
  }

  Future<void> _initVideo() async {
    final rawUrl = widget.banner.videoUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return;
    try {
      final videoUri = Uri.tryParse(rawUrl);
      if (videoUri == null) return;

      final vCtrl = VideoPlayerController.networkUrl(videoUri);
      _videoCtrl = vCtrl;
      await vCtrl.initialize();
      await vCtrl.setLooping(true);
      await vCtrl.setVolume(widget.controller.isMuted.value ? 0 : 1);
      vCtrl.addListener(_videoListener);

      if (mounted) {
        _safeSetState(() {
          _isVideoInitialized = true;
          _totalDuration = vCtrl.value.duration;
        });
        if (_isActive && !_userPaused) {
          vCtrl.play();
          _safeSetState(() => _isPlaying = true);
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing video player: $e');
      if (mounted) _safeSetState(() => _isVideoInitialized = false);
    }
  }

  void _videoListener() {
    if (!mounted || _videoCtrl == null) return;
    final val = _videoCtrl!.value;
    if (!val.isInitialized) return;

    if (!_isScrubbing) {
      _totalDuration = val.duration;
      _positionNotifier.value = val.position;
      if (_isPlaying != val.isPlaying) {
        _safeSetState(() {
          _isPlaying = val.isPlaying;
        });
      }
    }

    // Seamless loop replay fallback if native looping is not active
    if (_isActive && !_isScrubbing && !_didTriggerEnd) {
      if (val.isCompleted && !val.isLooping) {
        _didTriggerEnd = true;
        _videoCtrl?.seekTo(Duration.zero).then((_) {
          if (mounted && _isActive && !_userPaused) {
            _videoCtrl?.play();
          }
          _didTriggerEnd = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    _pageWorker?.dispose();
    _tabWorker?.dispose();
    _muteWorker?.dispose();
    _heartAnimCtrl.dispose();
    _videoCtrl?.removeListener(_videoListener);
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    _ytCtrl?.removeListener(_ytListener);
    _ytCtrl?.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.controller.setLiked(widget.banner.id, liked: true);
    _heartAnimCtrl.forward(from: 0.0);
  }

  void _handleSingleTap() {
    if (_isYouTube && _ytCtrl != null) {
      if (_ytCtrl!.value.isPlaying) {
        _userPaused = true;
        _ytCtrl!.pause();
        _safeSetState(() => _isPlaying = false);
      } else {
        _userPaused = false;
        _ytCtrl!.play();
        _safeSetState(() => _isPlaying = true);
      }
      return;
    }

    if (_hasVideo && _videoCtrl != null && _isVideoInitialized) {
      if (_videoCtrl!.value.isPlaying) {
        _userPaused = true;
        _videoCtrl!.pause();
        _safeSetState(() => _isPlaying = false);
      } else {
        _userPaused = false;
        _videoCtrl!.play();
        _safeSetState(() => _isPlaying = true);
      }
    }
  }

  void _startScrubbing(double dx, double width) {
    if (_totalDuration <= Duration.zero) return;
    HapticFeedback.selectionClick();
    _wasPlayingBeforeScrub = _isPlaying;
    if (_isYouTube) {
      _ytCtrl?.pause();
    } else {
      _videoCtrl?.pause();
    }
    final ratio = (dx / width).clamp(0.0, 1.0);
    _safeSetState(() {
      _isScrubbing = true;
      _scrubPosition = _totalDuration * ratio;
    });
    if (!_isYouTube) {
      _videoCtrl?.seekTo(_scrubPosition);
    }
  }

  void _updateScrubbing(double dx, double width) {
    if (_totalDuration <= Duration.zero) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    _safeSetState(() {
      _scrubPosition = _totalDuration * ratio;
    });
    if (!_isYouTube) {
      _videoCtrl?.seekTo(_scrubPosition);
    }
  }

  void _endScrubbing() {
    if (!_isScrubbing) return;
    _didTriggerEnd = false;
    _safeSetState(() {
      _isScrubbing = false;
    });
    if (_isYouTube && _ytCtrl != null) {
      _ytCtrl!.seekTo(_scrubPosition);
      if (_wasPlayingBeforeScrub) {
        _ytCtrl!.play();
        _safeSetState(() => _isPlaying = true);
      }
    } else {
      _videoCtrl?.seekTo(_scrubPosition);
      if (_wasPlayingBeforeScrub) {
        _videoCtrl?.play();
        _safeSetState(() => _isPlaying = true);
      }
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      final val = count / 1000000;
      return '${val.toStringAsFixed(val >= 10 ? 0 : 1)}M';
    } else if (count >= 1000) {
      final val = count / 1000;
      return '${val.toStringAsFixed(val >= 10 ? 0 : 1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          // Media Layer (YouTube, Native Video, or Image)
          _buildMediaLayer(),

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

          // Play button indicator - shown only when the user manually paused the video
          if (_hasVideo && _userPaused && !_isPlaying && !_isScrubbing)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.85),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),

          // Top Black Mask for YouTube Shorts header (attached to each card, moves during vertical scroll)
          if (_isYouTube)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: (MediaQuery.of(context).padding.top + 32).clamp(
                58.0,
                72.0,
              ),
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.black,
                        Colors.black54,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.70, 0.84, 0.93, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Dark Gradient Overlay (سواد في الأسفل لتغطية شريط اليوتيوب ومعلومات القناة وإبراز النصوص والتحكم)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.45, 0.65, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Action Rail (Heart, Comments, Share) - Positioned on the RIGHT over YouTube's buttons
          Positioned(
            bottom: contentBottom + 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Obx(() {
                final isLiked =
                    widget.controller.isLiked[widget.banner.id] ?? false;
                final likesCount =
                    widget.controller.likesCount[widget.banner.id] ??
                    widget.banner.totalLikes;
                final commentsCount =
                    widget.controller.commentsCount[widget.banner.id] ??
                    widget.banner.totalComments;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like Button with count
                    _buildRailButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isLiked
                          ? const Color(0xFFEF4444)
                          : Colors.white,
                      label: _formatCount(likesCount),
                      onTap: () =>
                          widget.controller.toggleLike(widget.banner.id),
                    ),
                    const SizedBox(height: 12),

                    // Comments Button with count
                    _buildRailButton(
                      icon: IconsaxPlusBold.messages_2,
                      iconColor: Colors.white,
                      label: _formatCount(commentsCount),
                      onTap: () {
                        ReelsCommentsSheet.show(
                          context,
                          widget.banner.id,
                          onCommentAdded: () => widget.controller
                              .onCommentAdded(widget.banner.id),
                          onCommentDeleted: () => widget.controller
                              .onCommentDeleted(widget.banner.id),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Share Button with Deeplink (iOS compatible with sharePositionOrigin)
                    Builder(
                      builder: (btnContext) {
                        return _buildRailButton(
                          icon: Icons.share_rounded,
                          iconColor: Colors.white,
                          label: 'مشاركة',
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final title =
                                widget.banner.titleAr?.trim().isNotEmpty == true
                                    ? widget.banner.titleAr!.trim()
                                    : 'عرض مميز من علي لقطع الغيار';
                            final deepLink =
                                'https://maktabali.com/reels?id=${widget.banner.id}';
                            final shareText =
                                '$title\n\nشاهد العرض عبر تطبيق علي لقطع الغيار:\n$deepLink';

                            Rect? origin;
                            try {
                              final box = btnContext.findRenderObject() as RenderBox?;
                              if (box != null && box.hasSize) {
                                origin = box.localToGlobal(Offset.zero) & box.size;
                              }
                            } catch (_) {}
                            origin ??= Rect.fromLTWH(
                              0,
                              0,
                              MediaQuery.of(btnContext).size.width,
                              MediaQuery.of(btnContext).size.height / 2,
                            );

                            try {
                              await Share.share(
                                shareText,
                                subject: title,
                                sharePositionOrigin: origin,
                              );
                            } catch (e) {
                              AppLogger.e('Error sharing reel: $e');
                            }
                          },
                        );
                      },
                    ),
                  ],
                );
              }),
            ),
          ),

          // Views Counter Badge - Positioned on the LEFT
          Positioned(
            bottom: contentBottom + 18,
            left: 14,
            child: Obx(() {
              final viewsCount =
                  widget.controller.viewsCount[widget.banner.id] ??
                  widget.banner.totalViews;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusBold.eye,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatCount(viewsCount),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Bottom Caption (Title, Subtitle, Shop Button) - Positioned on the right side
          Positioned(
            bottom: contentBottom,
            right: 82,
            left: 95,
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
              (_isVideoInitialized || _isYouTubeInitialized) &&
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
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _positionNotifier,
                      builder: (ctx, currentPos, _) {
                        final effectivePos = _isScrubbing
                            ? _scrubPosition
                            : currentPos;
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
                            height:
                                28, // Generous touch target for easy seeking
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
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaLayer() {
    if (_isYouTube) {
      return _buildYouTubeLayer();
    }
    if (_hasVideo) {
      return _buildVideoLayer();
    }
    return _buildImageLayer();
  }

  Widget _buildYouTubeLayer() {
    final isYouTubeReadyToDisplay = _isYouTubeInitialized &&
        _ytCtrl != null &&
        _ytCtrl!.value.isReady &&
        (_isPlaying || _ytCtrl!.value.isPlaying || _ytCtrl!.value.position > Duration.zero || _userPaused);

    final size = MediaQuery.of(context).size;
    final isShort =
        widget.banner.videoUrl?.toLowerCase().contains('shorts') == true;
    final double aspect = isShort && size.height > 0
        ? (size.width / size.height)
        : (16 / 9);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isYouTubeInitialized && _ytCtrl != null)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: YoutubePlayer(
              key: ValueKey('yt_${widget.banner.id}_${_youTubeId ?? ""}'),
              controller: _ytCtrl!,
              aspectRatio: aspect,
              showVideoProgressIndicator: false,
              onReady: () {
                _safeSetState(() {});
                if (_isActive && !_userPaused) {
                  _pendingPlay = false;
                  _ytCtrl?.play();
                }
              },
              onEnded: (_) {
                _ytCtrl?.seekTo(Duration.zero);
                _ytCtrl?.play();
              },
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isYouTubeReadyToDisplay
              ? const SizedBox.shrink(key: ValueKey('empty_yt_placeholder'))
              : SizedBox.expand(
                  key: const ValueKey('yt_thumb_placeholder'),
                  child: _buildThumbnailPlaceholder(showLoader: _isActive),
                ),
        ),
      ],
    );
  }

  Widget _buildThumbnailPlaceholder({bool showLoader = true}) {
    final videoId = _youTubeId;
    final thumbUrl = widget.banner.imageUrl.trim().isNotEmpty
        ? widget.banner.imageUrl.trim()
        : (videoId != null ? YoutubePlayer.getThumbnail(videoId: videoId) : '');

    Widget imageWidget;
    if (thumbUrl.isEmpty) {
      imageWidget = Container(color: Colors.black);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: thumbUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Container(color: Colors.black),
        errorWidget: (_, __, ___) => Container(color: Colors.black),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Semi-transparent dark overlay to enhance contrast and readability
        Container(
          color: Colors.black.withValues(alpha: 0.25),
        ),
        if (showLoader && _isActive)
          Center(
            child: Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3.2,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoLayer() {
    final isReadyToDisplay = _isVideoInitialized &&
        _videoCtrl != null &&
        (_isPlaying || _videoCtrl!.value.position > Duration.zero || _userPaused);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isVideoInitialized && _videoCtrl != null)
          Center(
            child: AspectRatio(
              aspectRatio: _videoCtrl!.value.aspectRatio,
              child: VideoPlayer(_videoCtrl!),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isReadyToDisplay
              ? const SizedBox.shrink(key: ValueKey('empty_video_placeholder'))
              : SizedBox.expand(
                  key: const ValueKey('video_thumb_placeholder'),
                  child: _buildThumbnailPlaceholder(showLoader: _isActive),
                ),
        ),
      ],
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
