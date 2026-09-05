import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../modules/main_nav/controllers/main_nav_controller.dart';

class OrderSuccessDialog extends StatelessWidget {
  final String orderNumber;

  const OrderSuccessDialog({
    super.key,
    required this.orderNumber,
  });

  static Future<void> show({required String orderNumber}) async {
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: OrderSuccessDialog(orderNumber: orderNumber),
      ),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeOutBack,
    );
  }

  void _onDone() {
    Get.back(); // Close dialog
    Get.offAllNamed(AppRoutes.mainNav);
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().changeTab(2); // Switch to Orders tab (index 2)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button on Top Left in RTL
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: _onDone,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Glowing 3D Golden Bell Icon matching User Screenshot
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFBBF24), // Amber 400
                  Color(0xFFF59E0B), // Amber 500
                  Color(0xFFD97706), // Amber 600
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFA000),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Title: "تم استلام طلبك"
          const Text(
            'تم استلام طلبك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Cairo',
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle: "طلب رقم XXX"
          Text(
            'طلب رقم $orderNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              fontFamily: 'Cairo',
            ),
          ),

          const SizedBox(height: 24),

          // Big Dark Navy "تم" Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A192F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'تم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
