import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_header_widget.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationService _notifService = Get.find<NotificationService>();
  bool _isLoadingMore = false;
  int _currentLimit = 30;

  @override
  void initState() {
    super.initState();
    _notifService.fetchNotifications(limit: _currentLimit);
    _notifService.fetchUnreadCount();
  }

  IconData _statusIcon(String? status, [String? type]) {
    if (type == 'admin_new_order') return IconsaxPlusBold.box_add;
    if (type == 'promo') return IconsaxPlusBold.gallery;
    if (type == 'banner_comment' || type == 'banner_reply') return IconsaxPlusBold.messages_2;
    if (type == 'new_product' || type == 'product') return IconsaxPlusBold.box;
    if (type == 'replacement_status') return IconsaxPlusBold.convert;
    if (type == 'account_status') return IconsaxPlusBold.shield_cross;
    if (type == 'admin_broadcast') return IconsaxPlusBold.notification_bing;
    switch (status) {
      case 'received':
        return IconsaxPlusBold.box_add;
      case 'preparing':
        return IconsaxPlusBold.box_time;
      case 'packed':
        return IconsaxPlusBold.box_tick;
      case 'shipped':
        return IconsaxPlusBold.truck_fast;
      case 'out_for_delivery':
        return IconsaxPlusBold.routing;
      case 'delivered':
        return IconsaxPlusBold.tick_circle;
      case 'cancelled':
        return IconsaxPlusBold.close_circle;
      default:
        return IconsaxPlusBold.notification_bing;
    }
  }

  String _statusLabel(String? status, [String? type]) {
    if (type == 'admin_new_order') return 'طلب جديد للادارة';
    if (type == 'promo') return 'عرض جديد';
    if (type == 'banner_reply') return 'رد في العروض';
    if (type == 'banner_comment') return 'تعليق في العروض';
    if (type == 'new_product' || type == 'product') return 'منتج جديد';
    if (type == 'replacement_status') return 'طلب استبدال';
    if (type == 'account_status') return 'حالة الحساب';
    if (type == 'admin_broadcast') return 'إشعار عام';
    switch (status) {
      case 'received':
        return 'تم الاستلام';
      case 'preparing':
        return 'جاري التجهيز';
      case 'packed':
        return 'تم التغلفة';
      case 'shipped':
        return 'تم الشحن';
      case 'out_for_delivery':
        return 'خرج للتوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return '';
    }
  }

  Color _statusColor(String? status, [String? type]) {
    if (type == 'admin_new_order') return const Color(0xFF2563EB);
    if (type == 'promo') return const Color(0xFFD97706);
    if (type == 'banner_reply') return const Color(0xFFD97706);
    if (type == 'banner_comment') return const Color(0xFF2563EB);
    if (type == 'new_product' || type == 'product') return const Color(0xFF10B981);
    if (type == 'replacement_status') return const Color(0xFF0D9488);
    if (type == 'account_status') return const Color(0xFFDC2626);
    if (type == 'admin_broadcast') return const Color(0xFF2563EB);
    switch (status) {
      case 'received':
        return const Color(0xFF2563EB);
      case 'preparing':
      case 'packed':
        return const Color(0xFFD97706);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFF7C3AED);
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt).inSeconds;
      if (diff < 60) return 'الآن';
      if (diff < 3600) return 'منذ ${diff ~/ 60} د';
      if (diff < 86400) return 'منذ ${diff ~/ 3600} س';
      if (diff < 604800) return 'منذ ${diff ~/ 86400} يوم';
      return 'منذ ${diff ~/ 604800} أسبوع';
    } catch (_) {
      return '';
    }
  }

  void _onNotificationTap(Map<String, dynamic> item) async {
    final notifId = item['id'] as String?;
    final orderId = item['order_id'] as String?;
    final type = item['type'] as String?;
    final productId = item['product_id'] as String?;
    final bannerId = (item['banner_id'] as String?) ?? (item['status'] as String?);
    final imageUrl = item['image_url'] as String?;
    final createdAt = item['created_at'] as String?;
    final title = item['title'] as String?;
    final body = item['body'] as String?;

    if (notifId != null && item['read_at'] == null) {
      _notifService.markRead(notifId);
    }

    _notifService.handleNotificationNavigation(
      type: type,
      orderId: orderId,
      productId: productId,
      bannerId: bannerId,
      status: item['status'] as String?,
      imageUrl: imageUrl,
      createdAt: createdAt,
      title: title,
      body: body,
    );
  }

  void _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentLimit += 30;
    await _notifService.fetchNotifications(limit: _currentLimit);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'الإشعارات',
                showBack: true,
                showNotifications: false,
              ),

              // Header actions: unread count + mark all read
              Obx(() {
                final unread = _notifService.unreadCount.value;
                if (unread <= 0) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$unread إشعار غير مقروء',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _notifService.markAllRead(),
                        child: Row(
                          children: [
                            const Icon(Icons.done_all_rounded, size: 16, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              'تعليم الكل كمقروء',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Content Body
              Expanded(
                child: Obx(() {
                  final items = _notifService.notifications;

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFFBEB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(IconsaxPlusBold.notification_bing, color: Color(0xFFD97706), size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد إشعارات',
                              style: GoogleFonts.cairo(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ستصلك إشعارات فورية عند تحديث حالة طلباتك وعروض التخفيضات المميزة.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        if (items.length >= _currentLimit) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                onPressed: _isLoadingMore ? null : _loadMore,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoadingMore
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                      )
                                    : Text(
                                        'تحميل المزيد',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 20);
                      }

                      final item = items[index];
                      final isUnread = item['read_at'] == null;
                      final title = item['title'] as String? ?? 'إشعار';
                      final body = item['body'] as String? ?? '';
                      final status = item['status'] as String?;
                      final type = item['type'] as String?;
                      final statusLbl = _statusLabel(status, type);
                      final statusClr = _statusColor(status, type);
                      final iconData = _statusIcon(status, type);
                      final timeStr = _timeAgo(item['created_at'] as String?);

                      return GestureDetector(
                        onTap: () => _onNotificationTap(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUnread ? const Color(0xFFFFFDF5) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnread ? AppColors.gold.withValues(alpha: 0.40) : const Color(0xFFE2E8F0),
                              width: isUnread ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isUnread ? 0.04 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              if (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: item['image_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[200],
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: isUnread
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                          )
                                        : null,
                                    color: isUnread ? null : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: isUnread ? const Color(0xFF0A192F) : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(width: 12),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: GoogleFonts.cairo(
                                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                                              fontSize: 13.5,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (body.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        body,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (statusLbl.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusClr.withValues(alpha: 0.10),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLbl,
                                              style: GoogleFonts.cairo(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: statusClr,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.cairo(
                                            fontSize: 10.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
