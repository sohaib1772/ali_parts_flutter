import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_header_widget.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.background,
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'طلباتي',
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardWhite,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(Icons.local_shipping_outlined, color: AppColors.gold, size: 54),
                        ),
                        const SizedBox(height: 16),
                        const Text('سجل الطلبات', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('لا توجد طلبات جارية حالياً، طلباتك الجديدة ستظهر هنا مع مراحل التتبع فور إرسالها.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
