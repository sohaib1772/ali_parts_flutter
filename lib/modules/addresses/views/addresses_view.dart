import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/dashed_border_button.dart';
import 'add_edit_address_view.dart';

class AddressesView extends StatefulWidget {
  const AddressesView({super.key});

  @override
  State<AddressesView> createState() => _AddressesViewState();
}

class _AddressesViewState extends State<AddressesView> {
  final StorageService _storage = Get.find<StorageService>();

  final List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    setState(() => _isLoading = true);
    final list = _storage.read<List>('user_addresses');
    setState(() {
      _addresses.clear();
      if (list != null) {
        _addresses.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      }
      _isLoading = false;
    });
  }

  void _openAddAddressPage({Map<String, dynamic>? initialAddress, int? editIndex}) {
    Get.to(
      () => AddEditAddressView(
        initialAddress: initialAddress,
        editIndex: editIndex,
      ),
      transition: Transition.fade,
    )?.then((_) => _loadAddresses());
  }

  void _makeDefault(int index) async {
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i]['is_default'] = (i == index);
    }
    await _storage.write('user_addresses', _addresses);
    _loadAddresses();
    Get.snackbar('تم التعيين', 'تم تعيين العنوان الرئيسي', backgroundColor: AppColors.navyMedium, colorText: Colors.white);
  }

  void _deleteAddress(int index) async {
    _addresses.removeAt(index);
    if (_addresses.isNotEmpty && !_addresses.any((a) => a['is_default'] == true)) {
      _addresses[0]['is_default'] = true;
    }
    await _storage.write('user_addresses', _addresses);
    _loadAddresses();
    Get.snackbar('تم الحذف', 'تم حذف العنوان بنجاح', backgroundColor: AppColors.navyMedium, colorText: Colors.white);
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
                // Unified Header
                const AppHeaderWidget(
                  title: 'عناويني',
                  showBack: true,
                ),

                // Body Content matching Website
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                      : _addresses.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(IconsaxPlusBold.location, color: Color(0xFF64748B), size: 36),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'لا توجد عناوين محفوظة',
                                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 24),
                                    DashedBorderButton(
                                      title: '+ إضافة عنوان جديد',
                                      onTap: () => _openAddAddressPage(),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...List.generate(_addresses.length, (index) {
                                  final a = _addresses[index];
                                  final fullName = a['full_name'] as String? ?? 'عنوان';
                                  final phone = a['phone'] as String? ?? '';
                                  final phone2 = a['phone2'] as String? ?? '';
                                  final city = a['city'] as String? ?? 'أربيل';
                                  final area = a['area'] as String? ?? '';
                                  final street = a['street'] as String? ?? '';
                                  final isDefault = a['is_default'] == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(IconsaxPlusBold.location, color: AppColors.gold, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        fullName,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                                      ),
                                                      if (isDefault) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFFBEB),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Text(
                                                            'افتراضي',
                                                            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 10),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '$fullName · $phone${phone2.isNotEmpty ? " · $phone2" : ""}',
                                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$city · $area${street.isNotEmpty ? " · $street" : ""}',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (!isDefault)
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => _makeDefault(index),
                                                  child: Container(
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        '✓ اجعله افتراضياً',
                                                        style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold, fontSize: 11.5),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (!isDefault) const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _openAddAddressPage(initialAddress: a, editIndex: index),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(IconsaxPlusBold.edit_2, color: Color(0xFF0A192F), size: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _deleteAddress(index),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF2F2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 6),
                                DashedBorderButton(
                                  title: '+ إضافة عنوان جديد',
                                  onTap: () => _openAddAddressPage(),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
