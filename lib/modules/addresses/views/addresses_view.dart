import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/settings_service.dart';

class AddressesView extends StatefulWidget {
  const AddressesView({super.key});

  @override
  State<AddressesView> createState() => _AddressesViewState();
}

class _AddressesViewState extends State<AddressesView> {
  final CartService _cart = Get.find<CartService>();
  final SettingsService _settings = Get.find<SettingsService>();

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
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top AppHeader
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A192F),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF102A43),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'العناوين',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _settings.storeTagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Icon
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.search),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF132B45),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cart Icon with Badge
                    Obx(() {
                      final count = _cart.cartCount.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.cart),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF132B45),
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEAB308),
                                  border: Border.all(color: const Color(0xFF0A192F), width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
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
