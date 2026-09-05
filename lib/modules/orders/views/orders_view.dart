import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../widgets/order_tracking_widget.dart';
import 'order_details_view.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final AuthService _auth = Get.find<AuthService>();
  final OrderRepository _orderRepo = Get.find<OrderRepository>();

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _cancellingOrderId;
  StreamSubscription? _ordersSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    if (Get.isRegistered<NotificationService>()) {
      _ordersSub = Get.find<NotificationService>().ordersUpdates.listen((_) {
        _fetchOrders();
      });
    }
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    final list = await _orderRepo.fetchUserOrders(userId);
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  void _cancelOrder(OrderModel order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('إلغاء الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل تريد إلغاء الطلب #${order.orderNumber}؟', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('تراجع', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text('نعم، إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _cancellingOrderId = order.id);
      final success = await _orderRepo.cancelOrder(order.id);
      setState(() => _cancellingOrderId = null);

      if (success) {
        _fetchOrders();
        Get.snackbar('تم الإلغاء', 'تم إلغاء الطلب بنجاح', backgroundColor: AppColors.navyDark, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', 'تعذّر إلغاء الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      }
    }
  }

  String _formatArabicDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      const months = [
        'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
        'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'received':
        return 'تم الاستلام';
      case 'pending':
        return 'قيد المراجعة';
      case 'preparing':
        return 'جاري التجهيز';
      case 'packed':
        return 'تم التغليف';
      case 'shipped':
        return 'شحن للتوصيل';
      case 'out_for_delivery':
        return 'خرج للتوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'received':
        return const Color(0xFF1D4ED8); // Blue 700
      case 'pending':
      case 'preparing':
        return const Color(0xFFB45309); // Amber 700
      case 'packed':
        return const Color(0xFFC2410C); // Orange 700
      case 'shipped':
        return const Color(0xFF4338CA); // Indigo 700
      case 'out_for_delivery':
        return const Color(0xFF6D28D9); // Purple 700
      case 'delivered':
        return const Color(0xFF047857); // Emerald 700
      case 'cancelled':
        return const Color(0xFFB91C1C); // Red 700
      default:
        return const Color(0xFF334155);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'received':
        return const Color(0xFFDBEAFE); // Blue 100
      case 'pending':
      case 'preparing':
        return const Color(0xFFFEF3C7); // Amber 100
      case 'packed':
        return const Color(0xFFFFEDD5); // Orange 100
      case 'shipped':
        return const Color(0xFFE0E7FF); // Indigo 100
      case 'out_for_delivery':
        return const Color(0xFFEDE9FE); // Purple 100
      case 'delivered':
        return const Color(0xFFD1FAE5); // Emerald 100
      case 'cancelled':
        return const Color(0xFFFEE2E2); // Red 100
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'received':
        return IconsaxPlusBold.box_add;
      case 'pending':
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
        return IconsaxPlusBold.box;
    }
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
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Top Unified Header
                const AppHeaderWidget(
                  title: 'طلباتي',
                  showBack: false,
                ),

                // Body Content
                Expanded(
                  child: Stack(
                    children: [
                      Obx(() {
                    if (!_auth.isLoggedIn.value) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 36),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'تسجيل الدخول مطلوب',
                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'سجّل دخولك لمشاهدة وتتبع حالة طلباتك السابقة وتفاصيل الشحن.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => Get.toNamed(AppRoutes.login)?.then((_) => _fetchOrders()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: const Color(0xFF0A192F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                ),
                                child: Text('تسجيل الدخول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }

                    if (_orders.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _fetchOrders,
                        color: AppColors.gold,
                        child: ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(IconsaxPlusBold.box, color: Color(0xFF64748B), size: 36),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد طلبات بعد',
                                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'ستظهر طلباتك هنا بعد إتمام أول عملية شراء',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => Get.offAllNamed(AppRoutes.mainNav),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: const Color(0xFF0A192F),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                      ),
                                      child: Text('ابدأ التسوق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: AppColors.gold,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) {
                          final order = _orders[i];
                          final statusText = _getStatusLabel(order.status);
                          final statusColor = _getStatusTextColor(order.status);
                          final statusBg = _getStatusBgColor(order.status);
                          final statusIcon = _getStatusIcon(order.status);
                          final canCancel = order.status == 'received' || order.status == 'preparing' || order.status == 'pending';
                          final isCancelling = _cancellingOrderId == order.id;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header Row: Order Number & Status Pill
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Order Number
                                    Text(
                                      order.orderNumber,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),

                                    // Status Badge Pill in Cairo
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 13, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: GoogleFonts.cairo(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Date Line
                                Text(
                                  _formatArabicDate(order.createdAt),
                                  style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),

                                const SizedBox(height: 8),

                                // Total Price Row with Chevron
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Formatters.formatIQD(order.totalIqd),
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0A192F),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                  ],
                                ),

                                // 6-Step Order Tracking Timeline with Perfect Icon-Centered Progress Bar
                                OrderTrackingWidget(status: order.status),

                                const SizedBox(height: 14),

                                // Action Buttons Row in Cairo Font
                                Row(
                                  children: [
                                    // Main "عرض التفاصيل والتتبع" Button
                                    Expanded(
                                      child: Material(
                                        color: AppColors.gold,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          onTap: () {
                                            Get.to(
                                              () => OrderDetailsView(order: order),
                                              transition: Transition.fade,
                                            )?.then((_) => _fetchOrders());
                                          },
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  IconsaxPlusBold.eye,
                                                  size: 18,
                                                  color: Color(0xFF0A192F),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'عرض التفاصيل والتتبع',
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13.5,
                                                    color: const Color(0xFF0A192F),
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Cancel Button in Cairo Font
                                    if (canCancel) ...[
                                      const SizedBox(width: 8),
                                      Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          onTap: isCancelling ? null : () => _cancelOrder(order),
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isCancelling ? 'جاري...' : 'إلغاء',
                                                  style: GoogleFonts.cairo(
                                                    color: const Color(0xFFDC2626),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  // Floating Glass Scroll To Top Button
                  GlassScrollToTopButton(
                    scrollController: _scrollController,
                    bottom: 82,
                    left: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}
