import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_header_widget.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

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
                title: 'سياسة الخصوصية',
                showBack: true,
              ),

              // Policy Content (LTR)
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
                              'سياسة الخصوصية وحماية البيانات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'تاريخ آخر تحديث: 2026',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Divider(height: 28, color: Color(0xFFF1F5F9)),
                            _buildSection(
                              title: '1. المعلومات التي نجمعها',
                              content: 'نقوم بجمع المعلومات الضرورية لإتمام طلباتك وتوصيلها، مثل الاسم، رقم الهاتف، العنوان الدقيق، وتفاصيل السيارة لضمان توافق القطع المطلوبة.',
                            ),
                            _buildSection(
                              title: '2. استخدام المعلومات',
                              content: 'تُستخدم بياناتك فقط لمعالجة الطلبات، التواصل معك بخصوص حالة الشحنة، وتقديم الدعم الفني وخدمات ما بعد البيع والضمان.',
                            ),
                            _buildSection(
                              title: '3. حماية وأمان البيانات',
                              content: 'نلتزم بحماية بياناتك الشخصية ولا نقوم ببيعها أو مشاركتها مع أي طرف ثالث، باستثناء شركات التوصيل المعتمدة لإيصال طلبك.',
                            ),
                            _buildSection(
                              title: '4. تواصل معنا بخصوص الخصوصية',
                              content: 'إذا كانت لديك أي استفسارات أو طلب لتحديث بياناتك أو حذف حسابك، يرجى التواصل مع فريق الدعم الفني عبر الواتساب أو صفحة حذف الحساب في التطبيق.',
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
