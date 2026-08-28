import '../../../core/widgets/app_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_storage_service.dart';

class AddressesView extends StatefulWidget {
  const AddressesView({super.key});

  @override
  State<AddressesView> createState() => _AddressesViewState();
}

class _AddressesViewState extends State<AddressesView> {

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final sec = Get.find<SecureStorageService>();
    final userId = await sec.read(AppConstants.secureKeyUserId);

    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.addresses,
        queryParameters: {
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        if (mounted) {
          setState(() {
            _addresses = List<Map<String, dynamic>>.from(res.data as List);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddAddressDialog() {
    final cityCtrl = TextEditingController(text: 'أربيل');
    final detailsCtrl = TextEditingController();
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة عنوان جديد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      labelText: 'المحافظة / المدينة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'العنوان بالتفصيل (الشارع / نقطة دالة)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (detailsCtrl.text.trim().isEmpty) return;
                                setState(() => isSaving = true);
                                try {
                                  final sec = Get.find<SecureStorageService>();
                                  final userId = await sec.read(AppConstants.secureKeyUserId);
                                  final dio = Get.find<DioClient>().dio;
                                  await dio.post(
                                    ApiConstants.addresses,
                                    data: {
                                      'user_id': userId,
                                      'city': cityCtrl.text.trim(),
                                      'address_line': detailsCtrl.text.trim(),
                                    },
                                  );
                                  Get.back();
                                  _loadAddresses();
                                } catch (_) {}
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A192F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('حفظ العنوان'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
          child: Column(
            children: [
              const AppHeaderWidget(
                title: 'عناويني',
                showBack: true,
              ),

              // Body Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _addresses.isEmpty
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
                                    child: const Icon(Icons.location_on_outlined, color: Color(0xFFD97706), size: 36),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد عناوين محفوظة',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'أضف عنوانك لتسريع عملية الطلب والتوصيل في المرات القادمة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _showAddAddressDialog,
                                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                                    label: const Text('إضافة عنوان جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A192F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _addresses[index];
                              final city = item['city'] as String? ?? 'أربيل';
                              final addressLine = item['address_line'] as String? ?? '';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFFBEB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.location_on_outlined, color: Color(0xFFD97706), size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            city,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            addressLine,
                                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                          ),
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
