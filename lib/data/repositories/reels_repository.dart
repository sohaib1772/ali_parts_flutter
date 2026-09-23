import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../app/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../models/banner_comment_model.dart';

class ReelLikesData {
  final int count;
  final bool isLiked;

  ReelLikesData({required this.count, required this.isLiked});
}

class ReelsRepository {
  final DioClient _dioClient = Get.find<DioClient>();

  Dio get _dio => _dioClient.dio;

  /// Fetch like count and user like status for a banner
  Future<ReelLikesData> fetchLikes(String bannerId, String? userId) async {
    if (bannerId.trim().isEmpty) {
      return ReelLikesData(count: 0, isLiked: false);
    }
    try {
      // 1. Fetch total count
      final countRes = await _dio.get(
        ApiConstants.bannerLikes,
        queryParameters: {
          'banner_id': 'eq.$bannerId',
          'select': 'banner_id',
        },
        options: Options(headers: {'Prefer': 'count=exact'}),
      );

      int totalCount = 0;
      final contentRange = countRes.headers.value('content-range');
      if (contentRange != null && contentRange.contains('/')) {
        totalCount = int.tryParse(contentRange.split('/').last) ?? 0;
      } else if (countRes.data is List) {
        totalCount = (countRes.data as List).length;
      }

      // 2. Check if current user liked
      bool isLiked = false;
      if (userId != null && userId.trim().isNotEmpty) {
        final userLikeRes = await _dio.get(
          ApiConstants.bannerLikes,
          queryParameters: {
            'banner_id': 'eq.$bannerId',
            'user_id': 'eq.$userId',
            'select': 'banner_id',
            'limit': 1,
          },
        );
        if (userLikeRes.data is List && (userLikeRes.data as List).isNotEmpty) {
          isLiked = true;
        }
      }

      return ReelLikesData(count: totalCount, isLiked: isLiked);
    } catch (e) {
      AppLogger.e('Error fetching likes for banner $bannerId', e);
      return ReelLikesData(count: 0, isLiked: false);
    }
  }

  /// Toggle like status
  Future<bool> toggleLike(String bannerId, String userId, bool currentlyLiked) async {
    if (bannerId.trim().isEmpty || userId.trim().isEmpty) {
      return currentlyLiked;
    }
    try {
      if (currentlyLiked) {
        // Unlike
        await _dio.delete(
          ApiConstants.bannerLikes,
          queryParameters: {
            'banner_id': 'eq.$bannerId',
            'user_id': 'eq.$userId',
          },
        );
        return false;
      } else {
        // Like
        await _dio.post(
          ApiConstants.bannerLikes,
          data: {
            'banner_id': bannerId,
            'user_id': userId,
          },
        );
        return true;
      }
    } catch (e) {
      AppLogger.e('Error toggling like for banner $bannerId', e);
      return currentlyLiked;
    }
  }

  /// Fetch total comment count
  Future<int> fetchCommentsCount(String bannerId) async {
    if (bannerId.trim().isEmpty) return 0;
    try {
      final res = await _dio.get(
        ApiConstants.bannerComments,
        queryParameters: {
          'banner_id': 'eq.$bannerId',
          'select': 'id',
        },
        options: Options(headers: {'Prefer': 'count=exact'}),
      );
      final contentRange = res.headers.value('content-range');
      if (contentRange != null && contentRange.contains('/')) {
        return int.tryParse(contentRange.split('/').last) ?? 0;
      }
      if (res.data is List) return (res.data as List).length;
    } catch (_) {}
    return 0;
  }

  /// Fetch all comments for a banner with nested replies
  Future<List<BannerCommentModel>> fetchComments(String bannerId) async {
    if (bannerId.trim().isEmpty) return [];
    try {
      final res = await _dio.get(
        ApiConstants.bannerComments,
        queryParameters: {
          'banner_id': 'eq.$bannerId',
          'select': 'id,banner_id,user_id,parent_id,content,is_admin_reply,created_at,updated_at',
          'order': 'created_at.asc',
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        AppLogger.d('Raw comments fetched from server: ${list.length}');
        final userIds = list
            .map((e) => e['user_id'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .toList();

        if (userIds.isNotEmpty) {
          try {
            final pRes = await _dio.get(
              ApiConstants.profiles,
              queryParameters: {
                'id': 'in.(${userIds.join(",")})',
                'select': 'id,full_name,avatar_url,is_blocked',
              },
            );
            if ((pRes.statusCode == 200 || pRes.statusCode == 206) && pRes.data is List) {
              final pMap = <String, dynamic>{};
              for (final p in (pRes.data as List)) {
                if (p is Map && p['id'] != null) {
                  pMap[p['id'].toString()] = p;
                }
              }
              for (final r in list) {
                final uid = r['user_id']?.toString();
                if (uid != null && pMap.containsKey(uid)) {
                  r['profiles'] = pMap[uid];
                }
              }
            }
          } catch (pe) {
            AppLogger.d('Failed to fetch comment profiles: $pe');
          }
        }

        final allRaw = list.map((e) => BannerCommentModel.fromJson(e)).toList();

        // Organize into top-level and nested replies
        final Map<String, BannerCommentModel> topLevel = {};
        final List<BannerCommentModel> replies = [];

        for (final comment in allRaw) {
          if (comment.parentId == null || comment.parentId!.isEmpty) {
            topLevel[comment.id] = comment;
          } else {
            replies.add(comment);
          }
        }

        // Attach replies to parents
        for (final reply in replies) {
          final parent = topLevel[reply.parentId];
          if (parent != null) {
            parent.replies.add(reply);
          } else {
            topLevel[reply.id] = reply;
          }
        }

        return topLevel.values.toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching comments for banner $bannerId', e);
    }
    return [];
  }

  /// Add a new comment or reply
  Future<BannerCommentModel?> addComment({
    required String bannerId,
    String? userId,
    required String content,
    String? parentId,
    bool isAdminReply = false,
  }) async {
    final effectiveUserId = userId ?? (Get.isRegistered<AuthService>() ? Get.find<AuthService>().userId : null);
    if (bannerId.trim().isEmpty || effectiveUserId == null || effectiveUserId.trim().isEmpty) {
      AppLogger.e('Cannot post comment: bannerId or userId is empty');
      return null;
    }
    try {
      final res = await _dio.post(
        ApiConstants.bannerComments,
        data: {
          'banner_id': bannerId,
          'user_id': effectiveUserId,
          'content': content.trim(),
          if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
          'is_admin_reply': isAdminReply,
        },
        options: Options(headers: {'Prefer': 'return=representation'}),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is List && (res.data as List).isNotEmpty) {
        final comment = BannerCommentModel.fromJson((res.data as List).first as Map<String, dynamic>);
        _dispatchNotification(
          bannerId: bannerId,
          commentId: comment.id,
          authorId: effectiveUserId,
          parentId: parentId,
          content: content,
          isAdminReply: isAdminReply,
        );
        return comment;
      }
    } on DioException catch (e) {
      // If office reply was rejected by DB policy (e.g. staff without admin role), retry as regular comment
      if (isAdminReply && e.response?.statusCode == 403) {
        AppLogger.d('Posting as office failed with 403, retrying as standard comment...');
        return addComment(
          bannerId: bannerId,
          userId: effectiveUserId,
          content: content,
          parentId: parentId,
          isAdminReply: false,
        );
      }
      AppLogger.e('Error posting comment', e);
      rethrow;
    } catch (e) {
      AppLogger.e('Error posting comment', e);
      rethrow;
    }
    return null;
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    if (commentId.trim().isEmpty) return false;
    try {
      final res = await _dio.delete(
        ApiConstants.bannerComments,
        queryParameters: {'id': 'eq.$commentId'},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      AppLogger.e('Error deleting comment $commentId', e);
      return false;
    }
  }

  /// Block a user (Admin/Moderator RPC)
  Future<bool> blockUser(String userId, {String? reason}) async {
    if (userId.trim().isEmpty) return false;
    try {
      final res = await _dio.post(
        ApiConstants.rpcAdminSetUserBlocked,
        data: {
          'p_user_id': userId,
          'p_blocked': true,
          'p_reason': reason ?? 'تم حظر الحساب بسبب تعليق مخالف لقوانين التطبيق',
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      AppLogger.e('Error blocking user $userId', e);
      return false;
    }
  }

  void _dispatchNotification({
    required String bannerId,
    required String commentId,
    required String authorId,
    String? parentId,
    required String content,
    required bool isAdminReply,
  }) {
    Future.microtask(() async {
      try {
        await _dio.post(
          ApiConstants.apiCommentNotify,
          data: {
            'banner_id': bannerId,
            'comment_id': commentId,
            'parent_id': parentId,
            'content': content.trim(),
            'is_admin_reply': isAdminReply,
          },
        );
      } catch (e) {
        AppLogger.d('Background comment notification dispatch failed (non-critical): $e');
      }
    });
  }
}
