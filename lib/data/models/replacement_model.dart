import 'package:flutter/material.dart';

class ReplacementModel {
  final String id;
  final String userId;
  final String? orderId;
  final String? orderItemId;
  final String? productId;
  final String productNameAr;
  final String reason;
  final List<String> attachments;
  final String? adminNotes;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? userProfile;

  ReplacementModel({
    required this.id,
    required this.userId,
    this.orderId,
    this.orderItemId,
    this.productId,
    required this.productNameAr,
    required this.reason,
    required this.attachments,
    this.adminNotes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.userProfile,
  });

  factory ReplacementModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedAttachments = [];
    if (json['attachments'] is List) {
      parsedAttachments = List<String>.from(
        (json['attachments'] as List).map((e) => e.toString()),
      );
    }

    return ReplacementModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      orderItemId: json['order_item_id'] as String?,
      productId: json['product_id'] as String?,
      productNameAr: json['product_name_ar'] as String? ?? 'منتج غير معروف',
      reason: json['reason'] as String? ?? '',
      attachments: parsedAttachments,
      adminNotes: json['admin_notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      userProfile: json['profiles'] is Map ? json['profiles'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'order_item_id': orderItemId,
      'product_id': productId,
      'product_name_ar': productNameAr,
      'reason': reason,
      'attachments': attachments,
      'admin_notes': adminNotes,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'بانتظار المراجعة';
      case 'in_review':
        return 'قيد المراجعة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'resolved':
        return 'منجز';
      default:
        return status;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_review':
        return Icons.search_rounded;
      case 'approved':
        return Icons.thumb_up_alt_rounded;
      case 'rejected':
        return Icons.thumb_down_alt_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706); // Amber
      case 'in_review':
        return const Color(0xFF2563EB); // Blue
      case 'approved':
        return const Color(0xFF16A34A); // Emerald
      case 'rejected':
        return const Color(0xFFDC2626); // Rose
      case 'resolved':
        return const Color(0xFF0A192F); // Navy
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'in_review':
        return const Color(0xFFDBEAFE);
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'rejected':
        return const Color(0xFFFFE4E6);
      case 'resolved':
        return const Color(0xFF0A192F);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get statusTextColor {
    switch (status) {
      case 'pending':
        return const Color(0xFF92400E);
      case 'in_review':
        return const Color(0xFF1E40AF);
      case 'approved':
        return const Color(0xFF166534);
      case 'rejected':
        return const Color(0xFF9F1239);
      case 'resolved':
        return Colors.white;
      default:
        return const Color(0xFF334155);
    }
  }
}

class ReplacementStatusLogModel {
  final String id;
  final String requestId;
  final String status;
  final String? note;
  final DateTime createdAt;

  ReplacementStatusLogModel({
    required this.id,
    required this.requestId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory ReplacementStatusLogModel.fromJson(Map<String, dynamic> json) {
    return ReplacementStatusLogModel(
      id: json['id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'بانتظار المراجعة';
      case 'in_review':
        return 'قيد المراجعة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'resolved':
        return 'منجز';
      default:
        return status;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_review':
        return Icons.search_rounded;
      case 'approved':
        return Icons.thumb_up_alt_rounded;
      case 'rejected':
        return Icons.thumb_down_alt_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'in_review':
        return const Color(0xFF2563EB);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'resolved':
        return const Color(0xFF0A192F);
      default:
        return const Color(0xFF64748B);
    }
  }
}
