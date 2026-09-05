import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_header_widget.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

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
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'الشروط والأحكام',
                showBack: true,
              ),

              // Terms Content (LTR)
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الشروط والأحكام وسياسة الضمان',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'يرجى قراءة الشروط والأحكام بعناية قبل إتمام الطلب',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Divider(height: 28, color: Color(0xFFF1F5F9)),
                            _buildSection(
                              title: '1. جودة القطع والمواصفات',
                              content: 'جميع القطع المعروضة توضح حالتها (جديدة أصلية أو مستعملة تفصيخ). نضمن فحص واختبار القطع المستعملة قبل إرسالها لضمان كفاءتها التشغيلية.',
                            ),
                            _buildSection(
                              title: '2. سياسة الضمان والاستبدال',
                              content: 'نوفر ضمان استبدال واسترجاع حقيقي على جميع القطع المشمولة بالضمان في حال وجود عيب مصنعي أو عدم مطابقة للطلب خلال فترة الضمان المحددة.',
                            ),
                            _buildSection(
                              title: '3. التوصيل والشحن',
                              content: 'يتم شحن الطلبات إلى جميع المحافظات العراقية في غضون 72 ساعة كحد أقصى من وقت تأكيد الطلب.',
                            ),
                            _buildSection(
                              title: '4. الأسعار والدفع',
                              content: 'الأسعار المعروضة بالدينار العراقي وهي أسعار نهائية. يتم الدفع عند الاستلام أو عبر بوابات الدفع الإلكترونية المعتمدة.',
                            ),
                          ],
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
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
