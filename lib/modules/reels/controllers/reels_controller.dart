import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/reels_repository.dart';

class ReelsController extends GetxController {
  final ReelsRepository _reelsRepo = Get.find<ReelsRepository>();
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isMuted = false.obs;
  final RxBool isTabVisible = true.obs;

  // Like, Comment, and View counts per bannerId
  final RxMap<String, int> likesCount = <String, int>{}.obs;
  final RxMap<String, bool> isLiked = <String, bool>{}.obs;
  final RxMap<String, int> commentsCount = <String, int>{}.obs;
  final RxMap<String, int> viewsCount = <String, int>{}.obs;
  final RxMap<String, bool> likePending = <String, bool>{}.obs;

  Worker? _tabWorker;

  void _safeNotify(VoidCallback fn) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      handleNewArguments(args);
    }
    _initData();
  }

  void setTabVisible(bool visible) {
    if (isTabVisible.value == visible) return;
    _safeNotify(() => isTabVisible.value = visible);
  }

  void checkTabVisibility() {
    // Kept for backwards compatibility
  }

  void handleNewArguments(Map<String, dynamic> args) {
    _safeNotify(() {
      if (args['banners'] is List<BannerModel>) {
        banners.assignAll(args['banners'] as List<BannerModel>);
      }
      final targetId = args['targetBannerId'] as String?;
      if (targetId != null && targetId.isNotEmpty) {
        final idx = banners.indexWhere((b) => b.id == targetId);
        if (idx != -1) {
          if (currentIndex.value != idx) {
            currentIndex.value = idx;
          }
        } else {
          // If banner list doesn't have targetId yet, refresh with targetBannerId
          refreshBanners(targetBannerId: targetId);
          return;
        }
      } else if (args['initialIndex'] is int) {
        final target = (args['initialIndex'] as int).clamp(0, (banners.length - 1).clamp(0, 999));
        if (currentIndex.value != target) {
          currentIndex.value = target;
        }
      }
      for (final banner in banners) {
        viewsCount[banner.id] ??= banner.totalViews;
        loadBannerStats(banner.id);
      }
      if (banners.isNotEmpty && currentIndex.value < banners.length) {
        recordView(banners[currentIndex.value].id);
      }
    });
  }

  Future<void> refreshBanners({List<BannerModel>? newBanners, String? targetBannerId, int? targetIndex}) async {
    try {
      final List<BannerModel> fetched;
      if (newBanners != null && newBanners.isNotEmpty) {
        fetched = newBanners;
      } else {
        fetched = await _productRepo.fetchBanners();
      }

      _safeNotify(() {
        final currentActiveId = (banners.isNotEmpty && currentIndex.value < banners.length)
            ? banners[currentIndex.value].id
            : null;

        banners.assignAll(fetched);

        if (targetBannerId != null && targetBannerId.isNotEmpty) {
          final idx = banners.indexWhere((b) => b.id == targetBannerId);
          if (idx != -1 && currentIndex.value != idx) {
            currentIndex.value = idx;
          }
        } else if (targetIndex != null) {
          final target = targetIndex.clamp(0, (banners.length - 1).clamp(0, 999));
          if (currentIndex.value != target) {
            currentIndex.value = target;
          }
        } else if (currentActiveId != null) {
          final idx = banners.indexWhere((b) => b.id == currentActiveId);
          if (idx != -1 && currentIndex.value != idx) {
            currentIndex.value = idx;
          }
        } else if (currentIndex.value >= banners.length && banners.isNotEmpty) {
          currentIndex.value = (banners.length - 1).clamp(0, 999);
        }

        for (final banner in banners) {
          viewsCount[banner.id] ??= banner.totalViews;
          loadBannerStats(banner.id);
        }
        if (banners.isNotEmpty && currentIndex.value < banners.length) {
          recordView(banners[currentIndex.value].id);
        }
      });
    } catch (_) {}
  }

  Future<void> _initData() async {
    _safeNotify(() => isLoading.value = true);
    try {
      if (banners.isEmpty) {
        final fetched = await _productRepo.fetchBanners();
        _safeNotify(() => banners.assignAll(fetched));
      }

      // Check if there is a target bannerId passed in arguments
      final targetBannerId = Get.arguments is Map ? Get.arguments['targetBannerId'] as String? : null;
      if (targetBannerId != null && targetBannerId.isNotEmpty) {
        final idx = banners.indexWhere((b) => b.id == targetBannerId);
        if (idx != -1 && currentIndex.value != idx) {
          _safeNotify(() => currentIndex.value = idx);
        }
      }

      // Pre-load likes & comments for all loaded banners
      for (final banner in banners) {
        _safeNotify(() {
          viewsCount[banner.id] ??= banner.totalViews;
        });
        loadBannerStats(banner.id);
      }

      if (banners.isNotEmpty && currentIndex.value < banners.length) {
        recordView(banners[currentIndex.value].id);
      }
    } finally {
      _safeNotify(() => isLoading.value = false);
    }
  }

  Future<void> loadBannerStats(String bannerId) async {
    final uid = _authService.userId;
    final likesData = await _reelsRepo.fetchLikes(bannerId, uid);
    final count = await _reelsRepo.fetchCommentsCount(bannerId);

    final banner = banners.firstWhereOrNull((b) => b.id == bannerId);
    final manualLikes = banner?.manualLikesCount ?? 0;
    final baseViews = viewsCount[bannerId] ?? (banner?.totalViews ?? 0);

    _safeNotify(() {
      likesCount[bannerId] = likesData.count + manualLikes;
      isLiked[bannerId] = likesData.isLiked;
      commentsCount[bannerId] = count;
      viewsCount[bannerId] = baseViews;
    });
  }

  /// Record an automatic view for each view / scroll
  void recordView(String bannerId) {
    if (bannerId.trim().isEmpty) return;
    _safeNotify(() {
      viewsCount[bannerId] = (viewsCount[bannerId] ?? 0) + 1;
    });
    _reelsRepo.incrementViews(bannerId);
  }

  void onPageChanged(int index) {
    _safeNotify(() {
      currentIndex.value = index;
    });
    if (index >= 0 && index < banners.length) {
      final bannerId = banners[index].id;
      loadBannerStats(bannerId);
      recordView(bannerId);
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
  }

  Future<void> toggleLike(String bannerId) async {
    final uid = _authService.userId;
    if (uid == null || uid.isEmpty) {
      Get.snackbar('تسجيل الدخول', 'يرجى تسجيل الدخول أولاً للإعجاب بالعرض',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (likePending[bannerId] == true) return;
    likePending[bannerId] = true;

    final currentLiked = isLiked[bannerId] ?? false;
    final currentCount = likesCount[bannerId] ?? 0;

    // Optimistic UI update
    isLiked[bannerId] = !currentLiked;
    likesCount[bannerId] = !currentLiked ? currentCount + 1 : (currentCount - 1).clamp(0, 999999);

    try {
      final actualLiked = await _reelsRepo.toggleLike(bannerId, uid, currentLiked);
      isLiked[bannerId] = actualLiked;
    } catch (_) {
      // Revert on error
      isLiked[bannerId] = currentLiked;
      likesCount[bannerId] = currentCount;
    } finally {
      likePending[bannerId] = false;
    }
  }

  /// Ensure liked state (used by double-tap: only likes, never unlikes)
  Future<void> setLiked(String bannerId, {bool liked = true}) async {
    final currentLiked = isLiked[bannerId] ?? false;
    if (currentLiked == liked) return;
    await toggleLike(bannerId);
  }

  void onCommentAdded(String bannerId) {
    _safeNotify(() {
      commentsCount[bannerId] = (commentsCount[bannerId] ?? 0) + 1;
    });
  }

  void onCommentDeleted(String bannerId) {
    _safeNotify(() {
      commentsCount[bannerId] = ((commentsCount[bannerId] ?? 1) - 1).clamp(0, 999999);
    });
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    super.onClose();
  }
}
