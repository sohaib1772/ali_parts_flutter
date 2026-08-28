import '../../../core/widgets/app_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_storage_service.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
    
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final sec = Get.find<SecureStorageService>();
    final userId = await sec.read(AppConstants.secureKeyUserId);

    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
          'limit': 30,
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        if (mounted) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(res.data as List);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
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

              // Content Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _notifications.isEmpty
                        ? Center(
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
                                    child: const Icon(Icons.notifications_none_rounded, color: Color(0xFFD97706), size: 36),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد إشعارات حالياً',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'ستصلك تنبيهات فورية عند تغيير حالة طلباتك وعروض التخفيضات المميزة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              final title = item['title'] as String? ?? 'إشعار';
                              final body = item['body'] as String? ?? '';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFFBEB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD97706), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          if (body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
