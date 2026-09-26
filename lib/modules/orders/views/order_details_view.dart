import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/replacement_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/replacement_repository.dart';
import '../../replacements/views/replacement_details_view.dart';
import '../../replacements/views/replacements_view.dart';
import '../widgets/order_tracking_widget.dart';

class OrderDetailsView extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsView({super.key, required this.order});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final OrderRepository _orderRepo = Get.find<OrderRepository>();
  final ReplacementRepository _replacementRepo = Get.find<ReplacementRepository>();
  final AuthService _auth = Get.find<AuthService>();

  late OrderModel _order;
  bool _isCancelling = false;
  final Map<String, ReplacementModel> _replacementsByItemId = {};

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadOrderReplacements();
  }

  Future<void> _loadOrderReplacements() async {
    try {
      final reps = await _replacementRepo.fetchReplacementsByOrderId(_order.id);
      if (mounted) {
        setState(() {
          _replacementsByItemId.clear();
          for (final r in reps) {
            if (r.orderItemId != null && r.orderItemId!.isNotEmpty) {
              _replacementsByItemId[r.orderItemId!] = r;
            }
            if (r.productId != null && r.productId!.isNotEmpty) {
              _replacementsByItemId[r.productId!] = r;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _cancelOrder() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('إلغاء الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('تراجع', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text('تأكيد الإلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isCancelling = true);
      final result = await _orderRepo.cancelOrder(_order.id);
      setState(() => _isCancelling = false);

      if (result.success) {
        Get.back(result: true);
        Get.snackbar('تم الإلغاء', 'تم إلغاء الطلب بنجاح', backgroundColor: AppColors.navyDark, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', result.message ?? 'تعذّر إلغاء الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      }
    }
  }

  void _openReplacementDialog(OrderItemModel item) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.repeat_rounded, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'طلب استبدال',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.productNameAr,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF0F172A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'سبب الاستبدال أو العطل بالتفصيل:',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    maxLength: 500,
                    style: GoogleFonts.cairo(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'مثال: المقاس غير مطابق، أو وجود كسر بالقطعة...',
                      hintStyle: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتواصل معك قسم متابعة الاستبدال لمعرفة أسباب الخلل خلال 72 ساعة.',
                            style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF92400E), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Get.back(),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final reason = reasonController.text.trim();
                        if (reason.length < 5) {
                          Get.snackbar('تنبيه', 'يرجى كتابة سبب الاستبدال بوضوح (5 أحرف على الأقل)', backgroundColor: AppColors.navyDark, colorText: Colors.white);
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final userId = _auth.currentUser.value?.id;
                        if (userId == null) {
                          Get.back();
                          Get.toNamed(AppRoutes.login);
                          return;
                        }

                        final created = await _replacementRepo.createReplacementRequest(
                          userId: userId,
                          orderId: _order.id,
                          orderItemId: item.id,
                          productId: item.productId,
                          productNameAr: item.productNameAr,
                          reason: reason,
                        );
                        setDialogState(() => isSubmitting = false);

                        if (created != null) {
                          Get.back(); // close input dialog
                          if (mounted) {
                            setState(() {
                              _replacementsByItemId[item.id] = created;
                              if (item.productId != null && item.productId!.isNotEmpty) {
                                _replacementsByItemId[item.productId!] = created;
                              }
                            });
                          }
                          _showReplacementSuccessDialog(created.id);
                        } else {
                          Get.snackbar('خطأ', 'تعذّر إرسال طلب الاستبدال، يرجى المحاولة لاحقاً', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A192F)),
                      )
                    : Text('إرسال طلب الاستبدال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReplacementSuccessDialog(String replacementId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'تم استلام طلب الاستبدال',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'سوف يتواصل معك قسم متابعة الاستبدال لمعرفة أسباب الخلل خلال 72 ساعة. يمكنك متابعة حالة الطلب وإرفاق الصور من صفحة طلبات الاستبدال.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.to(() => const ReplacementsView(), transition: Transition.fade);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A192F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('عرض طلبات الاستبدال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('حسناً', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addr = _order.shippingAddress;
    final canCancel = _order.status == 'received' || _order.status == 'preparing' || _order.status == 'pending';
    final canReplace = _order.status == 'delivered';

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
                AppHeaderWidget(
                  title: 'طلب #${_order.orderNumber}',
                  showBack: true,
                  showNotifications: false,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      children: [
                        // Card 1: Tracking Timeline
                        _buildCard(
                          title: 'مراحل التتبع',
                          icon: Icons.timeline_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OrderTrackingWidget(status: _order.status),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 2: Items List
                        _buildCard(
                          title: 'القطع المطلوبة (${_order.items.length})',
                          icon: Icons.inventory_2_outlined,
                          child: Column(
                            children: _order.items.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl: Formatters.thumbUrl(item.imageUrl, width: 100),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF94A3B8), size: 24),
                                          ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productNameAr,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                                              ),
                                              if (item.side != null && item.side!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'الجهة: ${item.side == "LH" ? "يسار" : (item.side == "RH" ? "يمين" : "طقم")}',
                                                  style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.gold, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                              const SizedBox(height: 2),
                                              Text(
                                                '${Formatters.formatIQD(item.unitPriceIqd)} × ${item.quantity}',
                                                style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatIQD(item.totalPrice),
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13.5, color: const Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final replacement = _replacementsByItemId[item.id] ??
                                            (item.productId != null ? _replacementsByItemId[item.productId!] : null);

                                        if (replacement != null) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: InkWell(
                                              onTap: () {
                                                Get.to(
                                                  () => ReplacementDetailsView(
                                                    replacementId: replacement.id,
                                                    initialRequest: replacement,
                                                  ),
                                                  transition: Transition.fade,
                                                )?.then((_) => _loadOrderReplacements());
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: double.infinity,
                                                height: 42,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: replacement.statusBgColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: replacement.statusColor.withValues(alpha: 0.45),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      replacement.statusIcon,
                                                      size: 16,
                                                      color: replacement.statusColor,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'تفاصيل الاستبدال (${replacement.statusLabel})',
                                                        style: GoogleFonts.cairo(
                                                          color: replacement.statusTextColor == Colors.white
                                                              ? const Color(0xFF0A192F)
                                                              : replacement.statusTextColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      IconsaxPlusBold.arrow_left_2,
                                                      size: 12,
                                                      color: replacement.statusColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (canReplace) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: InkWell(
                                              onTap: () => _openReplacementDialog(item),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: double.infinity,
                                                height: 42,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFFDF5),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.gold.withValues(alpha: 0.6),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(IconsaxPlusBold.convert, size: 16, color: AppColors.gold),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'طلب استبدال هذه القطعة',
                                                        style: GoogleFonts.cairo(
                                                          color: const Color(0xFF0A192F),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 3: Shipping Address
                        if (addr != null) ...[
                          _buildCard(
                            title: 'عنوان التوصيل',
                            icon: Icons.location_on_outlined,
                            child: Column(
                              children: [
                                _buildRow('المستلم', addr['full_name'] ?? '—'),
                                _buildRow('رقم الهاتف', addr['phone'] ?? '—'),
                                if (addr['phone2'] != null && addr['phone2'].toString().isNotEmpty)
                                  _buildRow('هاتف إضافي', addr['phone2'].toString()),
                                _buildRow('المحافظة', addr['city'] ?? '—'),
                                _buildRow('المنطقة', addr['area'] ?? '—'),
                                if (addr['street'] != null && addr['street'].toString().isNotEmpty)
                                  _buildRow('أقرب نقطة دالة', addr['street'].toString()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Card 4: Summary & Pricing
                        _buildCard(
                          title: 'ملخص الحساب',
                          icon: Icons.receipt_long_outlined,
                          child: Column(
                            children: [
                              _buildRow('المجموع الفرعي', Formatters.formatIQD(_order.subtotalIqd > 0 ? _order.subtotalIqd : _order.totalIqd)),
                              _buildRow('أجور التوصيل', _order.deliveryFeeIqd > 0 ? Formatters.formatIQD(_order.deliveryFeeIqd) : 'توصيل مجاني'),
                              _buildRow('طريقة الدفع', _order.paymentMethod == 'cod' ? 'الدفع عند الاستلام' : 'حوالة'),
                              const Divider(color: Color(0xFFF1F5F9), height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('الإجمالي المستحق', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A))),
                                  Text(
                                    Formatters.formatIQD(_order.totalIqd),
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF0A192F)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (canCancel) ...[
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: _isCancelling ? null : _cancelOrder,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                              ),
                              alignment: Alignment.center,
                              child: _isCancelling
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)))
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'إلغاء هذا الطلب',
                                            style: GoogleFonts.cairo(
                                              color: const Color(0xFFDC2626),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              height: 1.2,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFF64748B))),
          Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
