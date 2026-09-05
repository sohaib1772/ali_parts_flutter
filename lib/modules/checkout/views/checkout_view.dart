import '../../../core/widgets/order_success_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/dashed_border_button.dart';
import '../../../data/repositories/order_repository.dart';
import '../../addresses/views/add_edit_address_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _auth = Get.find<AuthService>();
  final CartService _cart = Get.find<CartService>();
  final SettingsService _settings = Get.find<SettingsService>();
  final OrderRepository _orderRepo = Get.find<OrderRepository>();

  final List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  String _paymentMethod = 'cod'; // 'cod' | 'transfer'
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _auth.fetchUserProfile();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _loadAddresses() {
    final list = _storage.read<List>('user_addresses');
    setState(() {
      _addresses.clear();
      if (list != null) {
        _addresses.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      }
      if (_addresses.isNotEmpty && _selectedAddressId == null) {
        final def = _addresses.firstWhereOrNull((a) => a['is_default'] == true);
        _selectedAddressId = def != null ? def['id']?.toString() : _addresses.first['id']?.toString();
      }
    });
  }

  Map<String, dynamic>? get _activeAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhereOrNull((a) => a['id']?.toString() == _selectedAddressId) ?? _addresses.first;
  }

  // Loyalty Points Computations matching Website
  int get _pointsBalance => _auth.pointsBalance.value;
  double get _subtotal => _cart.subtotalIqd;
  double get _shippingCost => _cart.deliveryFeeIqd;
  double get _redeemRate => _settings.pointsRedeemIqdPerPoint;
  int get _minRedeem => _settings.pointsMinRedeem;
  int get _maxRedeemPct => _settings.pointsMaxRedeemPct;
  int get _earnPer1000 => _settings.pointsEarnPer1000;

  int get _maxPoints {
    if (_pointsBalance <= 0 || _subtotal <= 0 || _redeemRate <= 0) return 0;
    final maxBySubtotal = (_subtotal / _redeemRate).floor();
    final maxByCap = (((_subtotal + _shippingCost) * _maxRedeemPct) / 100 / _redeemRate).floor();
    final cap = maxBySubtotal < maxByCap ? maxBySubtotal : maxByCap;
    final res = cap < _pointsBalance ? cap : _pointsBalance;
    return res > 0 ? res : 0;
  }

  int get _parsedPoints {
    final raw = int.tryParse(_pointsController.text.trim()) ?? 0;
    if (raw <= 0) return 0;
    return raw > _maxPoints ? _maxPoints : raw;
  }

  bool get _belowMin => _parsedPoints > 0 && _parsedPoints < _minRedeem;
  int get _effectivePoints => _belowMin ? 0 : _parsedPoints;
  double get _pointsDiscount => _effectivePoints * _redeemRate;
  double get _grandTotal {
    final res = _subtotal + _shippingCost - _pointsDiscount;
    return res > 0 ? res : 0.0;
  }
  int get _earnPreview => (_subtotal / 1000).floor() * _earnPer1000;

  void _openAddAddressPage() {
    Get.to(
      () => const AddEditAddressView(),
      transition: Transition.fade,
    )?.then((result) {
      _loadAddresses();
      if (result is Map && result['id'] != null) {
        setState(() => _selectedAddressId = result['id'].toString());
      }
    });
  }

  Future<void> _submitOrder() async {
    // 1. Check if user is logged in
    if (!_auth.isLoggedIn.value || _auth.currentUser.value == null) {
      Get.defaultDialog(
        title: 'تسجيل الدخول مطلوب',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        middleText: 'يرجى تسجيل الدخول أو إنشاء حساب لإرسال طلبك ومتابعته مباشرة على السيرفر.',
        middleTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        textConfirm: 'تسجيل الدخول',
        textCancel: 'إلغاء',
        confirmTextColor: const Color(0xFF0A192F),
        cancelTextColor: const Color(0xFF64748B),
        buttonColor: AppColors.gold,
        radius: 18,
        onConfirm: () {
          Get.back();
          Get.toNamed(AppRoutes.login);
        },
      );
      return;
    }

    // 2. Validate Address
    if (_activeAddress == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار أو إضافة عنوان توصيل أولاً', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    // 3. Validate Cart
    if (_cart.cartItems.isEmpty) {
      Get.snackbar('تنبيه', 'السلة فارغة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 4. Call Supabase RPC place_order with effectivePoints
      final orderId = await _orderRepo.placeOrder(
        address: _activeAddress!,
        paymentMethod: _paymentMethod,
        pointsUsed: _effectivePoints,
        notes: _notesController.text.trim(),
      );

      // 6. Clear local cart & refresh user profile for updated points balance
      _cart.clearCart();
      _auth.fetchUserProfile();
      setState(() => _isSubmitting = false);

      // 7. Extract display order number and show custom animated dialog
      final displayNum = (orderId != null && orderId.isNotEmpty)
          ? (orderId.length > 8 ? orderId.substring(0, 8) : orderId)
          : '102';

      await OrderSuccessDialog.show(orderNumber: displayNum);
    } catch (e) {
      setState(() => _isSubmitting = false);
      String errorMsg = 'تعذّر إرسال الطلب، يرجى المحاولة مرة أخرى';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }
      Get.snackbar(
        'خطأ في الطلب',
        errorMsg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.outOfStock,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        borderRadius: 14,
      );
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
                // Top Unified AppHeader
                const AppHeaderWidget(
                  title: 'إتمام الطلب',
                  showBack: true,
                  showCart: false,
                ),

                // Scrollable Content matching Website
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: عنوان التوصيل
                        _buildSectionCard(
                          title: 'عنوان التوصيل',
                          icon: Icons.location_on_outlined,
                          child: _addresses.isEmpty
                              ? DashedBorderButton(
                                  title: '+ إضافة عنوان',
                                  onTap: _openAddAddressPage,
                                )
                              : Column(
                                  children: [
                                    ..._addresses.map((a) {
                                      final id = a['id']?.toString();
                                      final isSelected = id == _selectedAddressId;
                                      final fullName = a['full_name'] as String? ?? 'عميل Ali Parts';
                                      final phone = a['phone'] as String? ?? '';
                                      final city = a['city'] as String? ?? 'أربيل';
                                      final area = a['area'] as String? ?? '';
                                      final street = a['street'] as String? ?? '';

                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedAddressId = id),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                                              width: isSelected ? 1.8 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                                color: isSelected ? AppColors.gold : const Color(0xFF94A3B8),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '$fullName · $phone',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$city · $area ${street.isNotEmpty ? "· $street" : ""}',
                                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.center,
                                      child: TextButton.icon(
                                        onPressed: () => Get.toNamed(AppRoutes.addresses)?.then((_) => _loadAddresses()),
                                        icon: const Icon(Icons.edit_location_alt_outlined, size: 14, color: AppColors.gold),
                                        label: const Text('إدارة العناوين', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 12),

                        // Card 2: كلفة التوصيل
                        _buildSectionCard(
                          title: 'كلفة التوصيل',
                          icon: Icons.local_shipping_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text.rich(
                                TextSpan(
                                  text: 'كلفة التوصيل: ',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  children: [
                                    TextSpan(
                                      text: _cart.deliveryFeeIqd > 0 ? Formatters.formatIQD(_cart.deliveryFeeIqd) : 'توصيل مجاني',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A192F), fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              )),
                              Obx(() {
                                if (!_cart.hasSplitShipment) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'يتضمن الطلب ${_cart.shipmentCount} شحنات منفصلة لأمان النقل.',
                                    style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card 3: طريقة الدفع
                        _buildSectionCard(
                          title: 'طريقة الدفع',
                          icon: Icons.credit_card_outlined,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPaymentPill(
                                  label: 'الدفع عند الاستلام',
                                  isSelected: _paymentMethod == 'cod',
                                  onTap: () => setState(() => _paymentMethod = 'cod'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildPaymentPill(
                                  label: 'حوالة',
                                  isSelected: _paymentMethod == 'transfer',
                                  onTap: () => setState(() => _paymentMethod = 'transfer'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card: استخدام نقاط الولاء (Matching Website & Uploaded Screenshot)
                        Obx(() {
                          if (_pointsBalance <= 0 || _subtotal <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSectionCard(
                              title: 'استخدام نقاط الولاء',
                              icon: Icons.auto_awesome_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: 'رصيدك: ',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                                      children: [
                                        TextSpan(
                                          text: '$_pointsBalance نقطة',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                        TextSpan(
                                          text: ' (≈ ${Formatters.formatIQD(_pointsBalance * _redeemRate)}) · كل نقطة = ${_redeemRate.toInt()} د.ع',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Right in RTL: Number input field
                                      Expanded(
                                        child: SizedBox(
                                          height: 44,
                                          child: TextField(
                                            controller: _pointsController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                              fontFamily: 'Cairo',
                                            ),
                                            onChanged: (val) {
                                              if (val.isNotEmpty) {
                                                final numVal = int.tryParse(val) ?? 0;
                                                if (numVal > _maxPoints) {
                                                  _pointsController.text = _maxPoints.toString();
                                                  _pointsController.selection = TextSelection.fromPosition(
                                                    TextPosition(offset: _pointsController.text.length),
                                                  );
                                                }
                                              }
                                              setState(() {});
                                            },
                                            decoration: InputDecoration(
                                              hintText: '0',
                                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Left in RTL: استخدم الحد الأقصى Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _pointsController.text = _maxPoints.toString();
                                          });
                                        },
                                        child: Container(
                                          height: 44,
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'استخدم الحد الأقصى ($_maxPoints)',
                                            style: const TextStyle(
                                              color: Color(0xFFD97706),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'الحد الأقصى لهذا الطلب: $_maxPoints نقطة (خصم حتى $_maxRedeemPct% من الطلب)${_minRedeem > 0 ? " · الحد الأدنى للاستبدال: $_minRedeem نقطة" : ""}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                                  ),
                                  if (_belowMin) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'الحد الأدنى للاستبدال هو $_minRedeem نقطة — لن يُطبّق الخصم.',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                  if (_effectivePoints > 0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'خصم: ${Formatters.formatIQD(_pointsDiscount)}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                        // Card 4: ملاحظة على الطلب
                        _buildSectionCard(
                          title: 'ملاحظة على الطلب',
                          icon: Icons.sticky_note_2_outlined,
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              hintText: 'أي تعليمات إضافية للتوصيل أو التجهيز...',
                              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card 5: ملخص الطلب
                        _buildSectionCard(
                          title: 'ملخص الطلب',
                          icon: Icons.receipt_long_outlined,
                          child: Obx(() => Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_cart.cartItems.length} منتج',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  Text(
                                    Formatters.formatIQD(_cart.subtotalIqd),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('التوصيل', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                  Text(
                                    _cart.deliveryFeeIqd > 0 ? Formatters.formatIQD(_cart.deliveryFeeIqd) : 'مجاني',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              if (_effectivePoints > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'خصم نقاط ($_effectivePoints)',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    ),
                                    Text(
                                      '- ${Formatters.formatIQD(_pointsDiscount)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF047857)),
                                    ),
                                  ],
                                ),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(color: Color(0xFFF1F5F9), height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text(
                                    'الإجمالي',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    Formatters.formatIQD(_grandTotal),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0A192F),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (_subtotal > 0 && _earnPreview > 0) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, size: 16, color: AppColors.gold),
                                    const SizedBox(width: 4),
                                    Text.rich(
                                      TextSpan(
                                        text: 'ستكسب ',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                                        children: [
                                          TextSpan(
                                            text: '$_earnPreview نقطة',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                                          ),
                                          const TextSpan(text: ' عند تسليم الطلب'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          )),
                        ),

                        const SizedBox(height: 20),

                        // Big Confirm Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF0A192F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting
                                ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0A192F))))
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'تأكيد الطلب',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'Cairo', height: 1.2),
                                    ),
                                  ),
                          ),
                        ),
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

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
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
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
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

  Widget _buildPaymentPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF0A192F) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
