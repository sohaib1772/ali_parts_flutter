import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
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
                      key: ValueKey(banner.id),
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
    super.key,
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
  WebViewController? _webCtrl;
  bool _isVideoInitialized = false;
  bool _isYouTubeReady = false;
  bool _isPlaying = false;
  bool _hasStartedPlaying = false;
  bool _userPaused = false;
  bool _isPlayRequested = false;
  bool _isYouTubeInitializing = false;
  Worker? _muteWorker;
  Worker? _tabWorker;
  bool _didTriggerEnd = false;

  // Video progress / seek bar
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(Duration.zero);
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
      if (_isYouTube && _webCtrl != null) {
        _webCtrl!.runJavaScript(muted ? 'muteVideo();' : 'unMuteVideo();');
      } else {
        _videoCtrl?.setVolume(muted ? 0 : 1);
      }
    });

    _tabWorker = ever(widget.controller.isTabVisible, (bool visible) {
      if (!visible) {
        if (_isYouTube) {
          _webCtrl?.runJavaScript('setActive(false);');
        } else {
          _videoCtrl?.pause();
        }
        if (mounted) setState(() => _isPlaying = false);
      } else if (widget.isActive) {
        if (_isYouTube && _webCtrl != null && _isYouTubeReady) {
          if (_hasStartedPlaying && !_userPaused) {
            _webCtrl!.runJavaScript('playVideo();');
            if (mounted) setState(() => _isPlaying = true);
          }
        } else if (_videoCtrl != null && _isVideoInitialized) {
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

    if (_isYouTube) {
      _initYouTube();
    } else if (_hasVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isYouTube) {
      if (_webCtrl == null && !_isYouTubeInitializing) {
        _initYouTube();
      }
      if (_webCtrl != null) {
        if (widget.isActive && !oldWidget.isActive) {
          if (_hasStartedPlaying && !_userPaused) {
            _webCtrl!.runJavaScript('playVideo();');
            setState(() => _isPlaying = true);
          }
        } else if (!widget.isActive && oldWidget.isActive) {
          _isPlayRequested = false;
          _userPaused = true;
          _webCtrl!.runJavaScript('pauseVideo();');
          setState(() => _isPlaying = false);
        }
        if (widget.controller.isMuted.value !=
            oldWidget.controller.isMuted.value) {
          _webCtrl!.runJavaScript(
            widget.controller.isMuted.value ? 'muteVideo();' : 'unMuteVideo();',
          );
        }
      }
    } else if (_hasVideo && _videoCtrl != null) {
      if (widget.isActive && !oldWidget.isActive) {
        _userPaused = false;
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
        _userPaused = false;
        _videoCtrl!.pause();
        setState(() => _isPlaying = false);
      }
      _videoCtrl!.setVolume(widget.controller.isMuted.value ? 0 : 1);
    }
  }

  Future<void> _initYouTube() async {
    final videoId = _youTubeId;
    if (videoId == null || _isYouTubeInitializing) return;
    _isYouTubeInitializing = true;

    try {
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black);

      if (ctrl.platform is AndroidWebViewController) {
        await (ctrl.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      // Desktop Chrome User-Agent: forces YouTube to use desktop player which strictly honors controls=0,
      // and completely eliminates mobile touch overlay buttons (|<<, pause, >>|) and mobile title bar!
      await ctrl.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      );

      ctrl.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            if (url.contains('youtube') ||
                url.contains('googlevideo.com') ||
                url.contains('ali-parts') ||
                url.startsWith('about:blank') ||
                url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

      ctrl.addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _handleYouTubeBridgeMessage(msg.message);
        },
      );

      final html = _buildYouTubeHtml(
        videoId: videoId,
        isMuted: widget.controller.isMuted.value,
        isActive: widget.isActive,
      );

      if (mounted) {
        setState(() {
          _webCtrl = ctrl;
        });
      }

      await ctrl.loadHtmlString(html, baseUrl: 'https://ali-parts.com');
      if (mounted && _isPlayRequested && !_userPaused) {
        ctrl.runJavaScript('unMuteVideo(); playVideo();');
      }
    } catch (e) {
      AppLogger.e('Error initializing YouTube webview: $e');
    } finally {
      _isYouTubeInitializing = false;
    }
  }

  void _handleYouTubeBridgeMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final event = data['event'];
      if (event == 'ready') {
        if (mounted) {
          setState(() {
            _isYouTubeReady = true;
          });
          if (_isPlayRequested && !_userPaused) {
            _webCtrl?.runJavaScript('unMuteVideo(); playVideo();');
          }
        }
      } else if (event == 'playing') {
        _userPaused = false;
        if (mounted) {
          setState(() {
            _hasStartedPlaying = true;
            _isPlaying = true;
          });
        }
      } else if (event == 'paused') {
        if (mounted && _isPlaying) {
          if (_isPlayRequested && !_userPaused) {
            _webCtrl?.runJavaScript('playVideo();');
          } else {
            setState(() => _isPlaying = false);
          }
        }
      } else if (event == 'ended') {
        _onYouTubeEnded();
      } else if (event == 'progress') {
        if (!_isScrubbing && mounted) {
          final cur = (data['current'] as num?)?.toDouble() ?? 0.0;
          final dur = (data['duration'] as num?)?.toDouble() ?? 0.0;
          _totalDuration = Duration(milliseconds: (dur * 1000).toInt());
          _currentPosition = Duration(milliseconds: (cur * 1000).toInt());
          _positionNotifier.value = _currentPosition;
        }
      }
    } catch (_) {}
  }

  void _onYouTubeEnded() {
    if (!mounted) return;
    if (widget.controller.banners.length <= 1) {
      _webCtrl?.runJavaScript('seekToVideo(0); playVideo();');
    } else {
      widget.onVideoFinished();
    }
  }

  String _buildYouTubeHtml({
    required String videoId,
    required bool isMuted,
    required bool isActive,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      background: #000;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #000;
    }
    #player-container {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      background: #000;
      pointer-events: none;
    }
    #player, iframe {
      width: 100% !important;
      height: 100% !important;
      border: 0 !important;
      pointer-events: none !important;
      transform: scale(1.38);
      transform-origin: center center;
    }
  </style>
</head>
<body>
  <div id="player-container">
    <iframe
      id="player"
      src="https://www.youtube.com/embed/$videoId?enablejsapi=1&origin=https://ali-parts.com&autoplay=0&controls=0&playsinline=1&rel=0&modestbranding=1&iv_load_policy=3&disablekb=1&fs=0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>
  </div>

  <script>
    var player;
    var isActive = false;
    var isAppMuted = $isMuted;
    var isUserPaused = false;
    var pendingPlay = false;
    var progressTimer;

    function initPlayer() {
      if (player) return;
      try {
        player = new YT.Player('player', {
          events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange
          }
        });
      } catch(e) {}
    }

    if (window.YT && window.YT.Player) {
      initPlayer();
    } else {
      window.onYouTubeIframeAPIReady = initPlayer;
    }

    function onPlayerReady(event) {
      startProgressTracking();
      if (window.FlutterBridge) {
        FlutterBridge.postMessage(JSON.stringify({event: 'ready'}));
      }
      if (pendingPlay && !isUserPaused) {
        playVideo();
      } else {
        try { event.target.pauseVideo(); } catch(e) {}
      }
    }

    function onPlayerStateChange(event) {
      if (event.data === YT.PlayerState.PLAYING) {
        if (window.FlutterBridge) {
          FlutterBridge.postMessage(JSON.stringify({event: 'playing'}));
        }
      } else if (event.data === YT.PlayerState.PAUSED) {
        if (window.FlutterBridge) {
          FlutterBridge.postMessage(JSON.stringify({event: 'paused'}));
        }
      } else if (event.data === YT.PlayerState.ENDED) {
        if (window.FlutterBridge) {
          FlutterBridge.postMessage(JSON.stringify({event: 'ended'}));
        }
      }
    }

    function startProgressTracking() {
      if (progressTimer) clearInterval(progressTimer);
      progressTimer = setInterval(function() {
        if (player && typeof player.getCurrentTime === 'function' && typeof player.getDuration === 'function') {
          var cur = player.getCurrentTime() || 0;
          var dur = player.getDuration() || 0;
          if (window.FlutterBridge) {
            FlutterBridge.postMessage(JSON.stringify({
              event: 'progress',
              current: cur,
              duration: dur
            }));
          }
        }
      }, 500);
    }

    function playVideo() {
      isUserPaused = false;
      pendingPlay = true;
      isActive = true;
      if (player && typeof player.playVideo === 'function') {
        try {
          if (typeof player.getPlayerState === 'function' && player.getPlayerState() === YT.PlayerState.ENDED) {
            player.seekTo(0, true);
          }
        } catch(e) {}
        try {
          if (!isAppMuted && typeof player.unMute === 'function') {
            player.unMute();
            player.setVolume(100);
          }
        } catch(e) {}
        try { player.playVideo(); } catch(e) {}
      }
    }

    function pauseVideo() {
      isUserPaused = true;
      isActive = false;
      pendingPlay = false;
      if (player && typeof player.pauseVideo === 'function') {
        try { player.pauseVideo(); } catch(e) {}
      }
    }

    function setActive(active) {
      if (!active) {
        pauseVideo();
      }
    }

    function muteVideo() {
      isAppMuted = true;
      if (player && typeof player.mute === 'function') {
        try { player.mute(); } catch(e) {}
      }
    }

    function unMuteVideo() {
      isAppMuted = false;
      if (player && typeof player.unMute === 'function') {
        try {
          player.unMute();
          player.setVolume(100);
        } catch(e) {}
      }
    }

    function seekToVideo(sec) {
      if (player && typeof player.seekTo === 'function') {
        try { player.seekTo(sec, true); } catch(e) {}
      }
    }
  </script>
  <script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';
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
      await vCtrl.setLooping(false); // DO NOT loop so it triggers onVideoFinished
      await vCtrl.setVolume(widget.controller.isMuted.value ? 0 : 1);
      vCtrl.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _totalDuration = vCtrl.value.duration;
          _currentPosition = vCtrl.value.position;
        });
        if (widget.isActive) {
          vCtrl.play();
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
      _currentPosition = val.position;
      _totalDuration = val.duration;
      _positionNotifier.value = val.position;
      if (_isPlaying != val.isPlaying) {
        setState(() {
          _isPlaying = val.isPlaying;
        });
      }
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
    _positionNotifier.dispose();
    _muteWorker?.dispose();
    _tabWorker?.dispose();
    _heartAnimCtrl.dispose();
    _videoCtrl?.removeListener(_videoListener);
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    _webCtrl?.loadHtmlString('<html><body style="background:#000;"></body></html>');
    _webCtrl = null;
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.controller.setLiked(widget.banner.id, liked: true);
    _heartAnimCtrl.forward(from: 0.0);
  }

  void _handleSingleTap() {
    if (_isYouTube) {
      if (_isPlaying) {
        _userPaused = true;
        _isPlayRequested = false;
        _webCtrl?.runJavaScript('pauseVideo();');
        setState(() => _isPlaying = false);
      } else {
        _userPaused = false;
        _isPlayRequested = true;
        setState(() => _isPlaying = true);
        if (_webCtrl != null) {
          _webCtrl!.runJavaScript('unMuteVideo(); playVideo();');
        } else if (!_isYouTubeInitializing) {
          _initYouTube();
        }
      }
      return;
    }

    if (_hasVideo && _videoCtrl != null && _isVideoInitialized) {
      if (_videoCtrl!.value.isPlaying) {
        _userPaused = true;
        _videoCtrl!.pause();
        setState(() => _isPlaying = false);
      } else {
        _userPaused = false;
        _videoCtrl!.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  void _startScrubbing(double dx, double width) {
    if (_totalDuration <= Duration.zero) return;
    HapticFeedback.selectionClick();
    _wasPlayingBeforeScrub = _isPlaying;
    if (_isYouTube && _webCtrl != null) {
      _webCtrl!.runJavaScript('pauseVideo();');
    } else {
      _videoCtrl?.pause();
    }
    final ratio = (dx / width).clamp(0.0, 1.0);
    setState(() {
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
    setState(() {
      _scrubPosition = _totalDuration * ratio;
    });
    if (!_isYouTube) {
      _videoCtrl?.seekTo(_scrubPosition);
    }
  }

  void _endScrubbing() {
    if (!_isScrubbing) return;
    _didTriggerEnd = false;
    setState(() {
      _isScrubbing = false;
    });
    if (_isYouTube && _webCtrl != null) {
      _webCtrl!.runJavaScript(
        'seekToVideo(${_scrubPosition.inMilliseconds / 1000});',
      );
      if (_wasPlayingBeforeScrub) {
        _isPlayRequested = true;
        _userPaused = false;
        _webCtrl!.runJavaScript('playVideo();');
        setState(() => _isPlaying = true);
      }
    } else {
      _videoCtrl?.seekTo(_scrubPosition);
      if (_wasPlayingBeforeScrub) {
        _videoCtrl?.play();
        setState(() => _isPlaying = true);
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

          // Play button indicator - shown when video is not playing
          if (_hasVideo && !_isPlaying && !_isScrubbing)
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
              (_isVideoInitialized || _isYouTubeReady) &&
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
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pure black background - clean and seamless
          const ColoredBox(color: Colors.black),

          // WebView running YouTube HTML5 player
          if (_webCtrl != null)
            IgnorePointer(
              child: WebViewWidget(controller: _webCtrl!),
            ),

          // Black overlay layer ONLY at the beginning before video starts playing - hides default YouTube image!
          if (!_hasStartedPlaying)
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),

          // Loading spinner if user tapped play but video has not started rendering yet
          if (!_hasStartedPlaying && _isPlaying)
            const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
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
