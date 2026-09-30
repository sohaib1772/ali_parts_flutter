class BannerModel {
  final String id;
  final String? titleAr;
  final String? subtitleAr;
  final String imageUrl;
  final String? videoUrl;
  final String? link;
  final String? expiresAt;
  final bool isActive;
  final int viewsCount;
  final int manualViewsCount;
  final int manualLikesCount;
  final int rawLikesCount;
  final int rawCommentsCount;

  BannerModel({
    required this.id,
    this.titleAr,
    this.subtitleAr,
    required this.imageUrl,
    this.videoUrl,
    this.link,
    this.expiresAt,
    this.isActive = true,
    this.viewsCount = 0,
    this.manualViewsCount = 0,
    this.manualLikesCount = 0,
    this.rawLikesCount = 0,
    this.rawCommentsCount = 0,
  });

  int get totalViews => viewsCount + manualViewsCount;
  int get totalManualLikes => manualLikesCount;
  int get totalLikes => rawLikesCount + manualLikesCount;
  int get totalComments => rawCommentsCount;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    int parsedLikes = (json['likes_count'] as num?)?.toInt() ?? 0;
    if (parsedLikes == 0 && json['banner_likes'] is List && (json['banner_likes'] as List).isNotEmpty) {
      final first = (json['banner_likes'] as List).first;
      if (first is Map && first['count'] != null) {
        parsedLikes = (first['count'] as num).toInt();
      }
    }

    int parsedComments = (json['comments_count'] as num?)?.toInt() ?? 0;
    if (parsedComments == 0 && json['banner_comments'] is List && (json['banner_comments'] as List).isNotEmpty) {
      final first = (json['banner_comments'] as List).first;
      if (first is Map && first['count'] != null) {
        parsedComments = (first['count'] as num).toInt();
      }
    }

    return BannerModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      link: json['link'] as String?,
      expiresAt: json['expires_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      manualViewsCount: (json['manual_views_count'] as num?)?.toInt() ?? 0,
      manualLikesCount: (json['manual_likes_count'] as num?)?.toInt() ?? 0,
      rawLikesCount: parsedLikes,
      rawCommentsCount: parsedComments,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      final exp = DateTime.parse(expiresAt!);
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }
}
