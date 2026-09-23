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

  // Like & Comment counts per bannerId
  final RxMap<String, int> likesCount = <String, int>{}.obs;
  final RxMap<String, bool> isLiked = <String, bool>{}.obs;
  final RxMap<String, int> commentsCount = <String, int>{}.obs;
  final RxMap<String, bool> likePending = <String, bool>{}.obs;

  Worker? _tabWorker;

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
    isTabVisible.value = visible;
    if (visible) {
      refreshBanners();
    }
  }

  void checkTabVisibility() {
    // Kept for backwards compatibility
  }

  void handleNewArguments(Map<String, dynamic> args) {
    if (args['banners'] is List<BannerModel>) {
      banners.assignAll(args['banners'] as List<BannerModel>);
    }
    final targetId = args['targetBannerId'] as String?;
    if (targetId != null && targetId.isNotEmpty) {
      final idx = banners.indexWhere((b) => b.id == targetId);
      if (idx != -1) {
        currentIndex.value = idx;
      }
    } else if (args['initialIndex'] is int) {
      currentIndex.value = (args['initialIndex'] as int).clamp(0, (banners.length - 1).clamp(0, 999));
    }
    for (final banner in banners) {
      loadBannerStats(banner.id);
    }
  }

  Future<void> refreshBanners({List<BannerModel>? newBanners, String? targetBannerId, int? targetIndex}) async {
    try {
      if (newBanners != null && newBanners.isNotEmpty) {
        banners.assignAll(newBanners);
      } else {
        final fetched = await _productRepo.fetchBanners();
        banners.assignAll(fetched);
      }

      if (targetBannerId != null && targetBannerId.isNotEmpty) {
        final idx = banners.indexWhere((b) => b.id == targetBannerId);
        if (idx != -1) {
          currentIndex.value = idx;
        }
      } else if (targetIndex != null) {
        currentIndex.value = targetIndex.clamp(0, (banners.length - 1).clamp(0, 999));
      } else if (currentIndex.value >= banners.length && banners.isNotEmpty) {
        currentIndex.value = (banners.length - 1).clamp(0, 999);
      }

      for (final banner in banners) {
        loadBannerStats(banner.id);
      }
    } catch (_) {}
  }

  Future<void> _initData() async {
    isLoading.value = true;
    try {
      if (banners.isEmpty) {
        final fetched = await _productRepo.fetchBanners();
        banners.assignAll(fetched);
      }

      // Check if there is a target bannerId passed in arguments
      final targetBannerId = Get.arguments is Map ? Get.arguments['targetBannerId'] as String? : null;
      if (targetBannerId != null && targetBannerId.isNotEmpty) {
        final idx = banners.indexWhere((b) => b.id == targetBannerId);
        if (idx != -1) {
          currentIndex.value = idx;
        }
      }

      // Pre-load likes & comments for all loaded banners
      for (final banner in banners) {
        loadBannerStats(banner.id);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadBannerStats(String bannerId) async {
    final uid = _authService.userId;
    final likesData = await _reelsRepo.fetchLikes(bannerId, uid);
    final count = await _reelsRepo.fetchCommentsCount(bannerId);

    likesCount[bannerId] = likesData.count;
    isLiked[bannerId] = likesData.isLiked;
    commentsCount[bannerId] = count;
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    if (index >= 0 && index < banners.length) {
      loadBannerStats(banners[index].id);
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
    commentsCount[bannerId] = (commentsCount[bannerId] ?? 0) + 1;
  }

  void onCommentDeleted(String bannerId) {
    commentsCount[bannerId] = ((commentsCount[bannerId] ?? 1) - 1).clamp(0, 999999);
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    super.onClose();
  }
}
