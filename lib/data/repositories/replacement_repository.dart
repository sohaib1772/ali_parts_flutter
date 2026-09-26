import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/replacement_model.dart';

class ReplacementRepository {
  final DioClient _dioClient;

  ReplacementRepository(this._dioClient);

  /// Fetches replacement requests for the logged-in customer
  Future<List<ReplacementModel>> fetchMyReplacements(String userId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.replacementRequests,
        queryParameters: {'user_id': 'eq.$userId', 'order': 'created_at.desc'},
      );

      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List) {
        return (response.data as List)
            .map((e) => ReplacementModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching my replacements', e);
    }
    return [];
  }

  /// Fetches replacement requests for a specific order
  Future<List<ReplacementModel>> fetchReplacementsByOrderId(
    String orderId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.replacementRequests,
        queryParameters: {
          'order_id': 'eq.$orderId',
          'order': 'created_at.desc',
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List) {
        return (response.data as List)
            .map((e) => ReplacementModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching replacements for order $orderId', e);
    }
    return [];
  }

  /// Fetches a single replacement request by ID with user profile info
  Future<ReplacementModel?> fetchReplacementById(String id) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.replacementRequests,
        queryParameters: {'id': 'eq.$id', 'limit': 1},
      );

      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final row = Map<String, dynamic>.from(
          (response.data as List).first as Map,
        );
        final userId = row['user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          try {
            final pRes = await _dioClient.dio.get(
              ApiConstants.profiles,
              queryParameters: {
                'id': 'eq.$userId',
                'select': 'id,full_name,phone',
                'limit': 1,
              },
            );
            if ((pRes.statusCode == 200 || pRes.statusCode == 206) &&
                pRes.data is List &&
                (pRes.data as List).isNotEmpty) {
              row['profiles'] = (pRes.data as List).first;
            }
          } catch (_) {}
        }
        return ReplacementModel.fromJson(row);
      }
    } catch (e) {
      AppLogger.e('Error fetching replacement details: $id', e);
    }
    return null;
  }

  /// Fetches status log entries for a replacement request
  Future<List<ReplacementStatusLogModel>> fetchStatusLog(
    String requestId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.replacementStatusLog,
        queryParameters: {
          'request_id': 'eq.$requestId',
          'order': 'created_at.asc',
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List) {
        return (response.data as List)
            .map(
              (e) =>
                  ReplacementStatusLogModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching replacement status log: $requestId', e);
    }
    return [];
  }

  /// Creates a new replacement request from order details
  Future<ReplacementModel?> createReplacementRequest({
    required String userId,
    required String orderId,
    String? orderItemId,
    String? productId,
    required String productNameAr,
    required String reason,
    List<String> attachments = const [],
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.replacementRequests,
        data: {
          'user_id': userId,
          'order_id': orderId,
          if (orderItemId != null) 'order_item_id': orderItemId,
          if (productId != null) 'product_id': productId,
          'product_name_ar': productNameAr,
          'reason': reason.trim(),
          'attachments': attachments,
          'status': 'pending',
        },
        options: Options(headers: {'Prefer': 'return=representation'}),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        if (response.data is List && (response.data as List).isNotEmpty) {
          return ReplacementModel.fromJson(
            (response.data as List).first as Map<String, dynamic>,
          );
        } else if (response.data is Map) {
          return ReplacementModel.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error creating replacement request', e);
    }
    return null;
  }

  /// Uploads an image attachment to Supabase Storage `replacement-attachments` bucket
  Future<String?> uploadAttachment({
    required String userId,
    required String requestId,
    required XFile file,
  }) async {
    try {
      final fileName = file.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
      final pathKey =
          '$userId/$requestId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final bytes = await file.readAsBytes();
      final uploadUrl =
          '${ApiConstants.baseUrl}/storage/v1/object/replacement-attachments/$pathKey';

      final response = await _dioClient.dio.post(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': file.mimeType ?? 'image/jpeg'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return pathKey;
      }
    } catch (e) {
      AppLogger.e('Error uploading replacement attachment', e);
    }
    return null;
  }

  /// Updates the attachments list of a replacement request
  Future<bool> updateAttachments(
    String requestId,
    List<String> attachments,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConstants.replacementRequests,
        queryParameters: {'id': 'eq.$requestId'},
        data: {'attachments': attachments},
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.e('Error updating replacement attachments', e);
      return false;
    }
  }

  /// Generates a signed URL for viewing an attachment in Supabase Storage
  Future<String?> getSignedUrl(String pathKey) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/storage/v1/object/sign/replacement-attachments/$pathKey',
        data: {'expiresIn': 3600},
      );

      if (response.statusCode == 200 && response.data != null) {
        final signedUrl = response.data['signedURL'] as String?;
        if (signedUrl != null) {
          if (signedUrl.startsWith('http')) return signedUrl;
          return '${ApiConstants.baseUrl}$signedUrl';
        }
      }
    } catch (e) {
      AppLogger.e('Error generating signed URL for $pathKey', e);
    }
    return null;
  }

  /// Deletes an attachment from Supabase Storage and updates the record
  Future<bool> deleteAttachment({
    required String requestId,
    required String pathKey,
    required List<String> currentAttachments,
  }) async {
    try {
      await _dioClient.dio.delete(
        '${ApiConstants.baseUrl}/storage/v1/object/replacement-attachments/$pathKey',
      );

      final next = currentAttachments.where((p) => p != pathKey).toList();
      return await updateAttachments(requestId, next);
    } catch (e) {
      AppLogger.e('Error deleting replacement attachment', e);
      return false;
    }
  }

  /// Admin: Fetches all replacement requests with customer info
  Future<List<ReplacementModel>> adminFetchAllReplacements() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.replacementRequests,
        queryParameters: {'order': 'created_at.desc', 'limit': 200},
      );

      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List) {
        final list = (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final userIds = list
            .map((e) => e['user_id'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .toList();

        if (userIds.isNotEmpty) {
          try {
            final pRes = await _dioClient.dio.get(
              ApiConstants.profiles,
              queryParameters: {
                'id': 'in.(${userIds.join(",")})',
                'select': 'id,full_name,phone',
              },
            );
            if ((pRes.statusCode == 200 || pRes.statusCode == 206) &&
                pRes.data is List) {
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
          } catch (_) {}
        }

        return list.map((e) => ReplacementModel.fromJson(e)).toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching admin replacements', e);
    }
    return [];
  }

  /// Admin: Updates replacement request status and writes to status log
  Future<bool> adminUpdateStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
    String? logNote,
  }) async {
    try {
      // 1. Update replacement request
      final patchData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (adminNotes != null) patchData['admin_notes'] = adminNotes;

      final res1 = await _dioClient.dio.patch(
        ApiConstants.replacementRequests,
        queryParameters: {'id': 'eq.$requestId'},
        data: patchData,
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );

      if (res1.statusCode != 200 && res1.statusCode != 204) return false;

      // 2. Insert into status log
      await _dioClient.dio.post(
        ApiConstants.replacementStatusLog,
        data: {
          'request_id': requestId,
          'status': newStatus,
          if (logNote != null && logNote.isNotEmpty) 'note': logNote,
        },
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );

      return true;
    } catch (e) {
      AppLogger.e('Error admin updating replacement status: $requestId', e);
      return false;
    }
  }
}
