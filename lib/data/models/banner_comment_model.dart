class BannerCommentModel {
  final String id;
  final String bannerId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? parentId;
  final bool isAdminReply;
  final String createdAt;
  final bool isBlocked;
  final List<BannerCommentModel> replies;

  BannerCommentModel({
    required this.id,
    required this.bannerId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.parentId,
    this.isAdminReply = false,
    required this.createdAt,
    this.isBlocked = false,
    List<BannerCommentModel>? replies,
  }) : replies = replies ?? [];

  factory BannerCommentModel.fromJson(Map<String, dynamic> json) {
    String name = 'مستخدم';
    String? avatar;
    bool blocked = false;

    if (json['profiles'] != null && json['profiles'] is Map) {
      final p = json['profiles'] as Map<String, dynamic>;
      name = (p['full_name'] as String?)?.trim() ?? 'مستخدم';
      avatar = p['avatar_url'] as String?;
      blocked = p['is_blocked'] as bool? ?? false;
    } else if (json['full_name'] != null) {
      name = (json['full_name'] as String).trim();
      avatar = json['avatar_url'] as String?;
      blocked = json['is_blocked'] as bool? ?? false;
    }

    if (json['is_admin_reply'] == true) {
      name = 'مكتب علي شوفرليت';
    }

    return BannerCommentModel(
      id: json['id']?.toString() ?? '',
      bannerId: json['banner_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: name.isEmpty ? 'مستخدم' : name,
      userAvatar: avatar,
      content: json['content']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      isAdminReply: json['is_admin_reply'] == true || json['is_admin_reply'] == 1,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isBlocked: blocked,
    );
  }

  BannerCommentModel copyWith({
    List<BannerCommentModel>? replies,
  }) {
    return BannerCommentModel(
      id: id,
      bannerId: bannerId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      parentId: parentId,
      isAdminReply: isAdminReply,
      createdAt: createdAt,
      isBlocked: isBlocked,
      replies: replies ?? this.replies,
    );
  }
}
