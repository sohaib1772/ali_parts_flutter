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

  // Like & Comment counts per bannerId
  final RxMap<String, int> likesCount = <String, int>{}.obs;
  final RxMap<String, bool> isLiked = <String, bool>{}.obs;
  final RxMap<String, int> commentsCount = <String, int>{}.obs;
  final RxMap<String, bool> likePending = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      if (args['banners'] is List<BannerModel>) {
        banners.assignAll(args['banners'] as List<BannerModel>);
      }
      if (args['initialIndex'] is int) {
        currentIndex.value = (args['initialIndex'] as int).clamp(0, (banners.length - 1).clamp(0, 999));
      }
    }
    _initData();
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

  void onCommentAdded(String bannerId) {
    commentsCount[bannerId] = (commentsCount[bannerId] ?? 0) + 1;
  }

  void onCommentDeleted(String bannerId) {
    commentsCount[bannerId] = ((commentsCount[bannerId] ?? 1) - 1).clamp(0, 999999);
  }
}
