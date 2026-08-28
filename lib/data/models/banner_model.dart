class BannerModel {
  final String id;
  final String? titleAr;
  final String? subtitleAr;
  final String imageUrl;
  final String? videoUrl;
  final String? link;
  final String? expiresAt;
  final bool isActive;

  BannerModel({
    required this.id,
    this.titleAr,
    this.subtitleAr,
    required this.imageUrl,
    this.videoUrl,
    this.link,
    this.expiresAt,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String?,
      subtitleAr: json['subtitle_ar'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      link: json['link'] as String?,
      expiresAt: json['expires_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
