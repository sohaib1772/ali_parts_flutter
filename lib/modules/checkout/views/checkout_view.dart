import '../../../core/widgets/app_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/utils/formatters.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'أربيل');
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final AuthService _auth = Get.find<AuthService>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_auth.isLoggedIn.value && _auth.userName.value.isNotEmpty) {
      _nameController.text = _auth.userName.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartService>();

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.background,
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'إتمام الطلب',
                showBack: true,
                showCart: false,
              ),
              Expanded(
                child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login banner if not logged in
            Obx(() {
              if (_auth.isLoggedIn.value) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navyMedium,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'سجّل دخولك لتتبع شحنتك وحفظ طلباتك',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final res = await Get.toNamed(AppRoutes.login);
                        if (res == true && _auth.userName.value.isNotEmpty) {
                          _nameController.text = _auth.userName.value;
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('دخول', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),

            const Text('بيانات المستلم والتوصيل', style: TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildInputField('الاسم الكامل', _nameController, Icons.person_outline),
            const SizedBox(height: 12),
            _buildInputField('رقم الهاتف', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildInputField('المحافظة / المدينة', _cityController, Icons.location_city_outlined),
            const SizedBox(height: 12),
            _buildInputField('العنوان بالتفصيل (المنطقة / الشارع / نقطة دالة)', _addressController, Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildInputField('ملاحظات إضافية للطلب (اختياري)', _notesController, Icons.notes_outlined, maxLines: 2),

            const SizedBox(height: 24),
            const Text('ملخص الطلب', style: TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('عدد القطع:', style: TextStyle(color: AppColors.textSecondary)),
                      Text('${cart.cartCount.value} قطع', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الفرعي:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(Formatters.formatIQD(cart.subtotalIqd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أجور التوصيل:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(Formatters.formatIQD(cart.deliveryFeeIqd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي المستحق (الدفع عند الاستلام):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(Formatters.formatIQD(cart.totalIqd), style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: AppColors.navyDark)
                    : const Text('تأكيد وإرسال الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
        filled: true,
        fillColor: AppColors.navyMedium,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      Get.snackbar(
        'بيانات ناقصة',
        'يرجى إدخال الاسم ورقم الهاتف والعنوان',
        backgroundColor: AppColors.outOfStock,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final cart = Get.find<CartService>();
    cart.clearCart();

    setState(() => _isSubmitting = false);

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.navyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.inStock),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              const Text('تم إرسال طلبك بنجاح! 🎉', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('سيتم التواصل معك هاتفياً لتأكيد الشحنة وموعد التوصيل.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.until((route) => route.isFirst);
                },
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
