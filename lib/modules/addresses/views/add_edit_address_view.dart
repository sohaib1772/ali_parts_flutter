import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_header_widget.dart';

class AddEditAddressView extends StatefulWidget {
  final Map<String, dynamic>? initialAddress;
  final int? editIndex;

  const AddEditAddressView({
    super.key,
    this.initialAddress,
    this.editIndex,
  });

  @override
  State<AddEditAddressView> createState() => _AddEditAddressViewState();
}

class _AddEditAddressViewState extends State<AddEditAddressView> {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _auth = Get.find<AuthService>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _phone2Ctrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _streetCtrl;
  late String _selectedCity;

  final governorates = [
    'بغداد', 'أربيل', 'البصرة', 'نينوى', 'النجف', 'كربلاء', 'بابل',
    'ذي قار', 'ديالى', 'الأنبار', 'صلاح الدين', 'كركوك', 'واسط',
    'ميسان', 'المثنى', 'القادسية', 'دهوك', 'السليمانية', 'حلبجة',
  ];

  bool get isEditing => widget.initialAddress != null && widget.editIndex != null;

  @override
  void initState() {
    super.initState();
    final initialPhone = widget.initialAddress?['phone'] ?? _auth.currentUser.value?.phone ?? '';
    final initialPhone2 = widget.initialAddress?['phone2'] ?? '';

    _nameCtrl = TextEditingController(
      text: widget.initialAddress?['full_name'] ?? _auth.userName.value,
    );
    _phoneCtrl = TextEditingController(
      text: Validators.formatLocalIraqiPhone(initialPhone),
    );
    _phone2Ctrl = TextEditingController(
      text: Validators.formatLocalIraqiPhone(initialPhone2),
    );
    _areaCtrl = TextEditingController(
      text: widget.initialAddress?['area'] ?? '',
    );
    _streetCtrl = TextEditingController(
      text: widget.initialAddress?['street'] ?? '',
    );
    _selectedCity = widget.initialAddress?['city'] ?? 'بغداد';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _phone2Ctrl.dispose();
    _areaCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final phone1 = Validators.formatLocalIraqiPhone(_phoneCtrl.text);
    final phone2Raw = _phone2Ctrl.text.trim();

    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال الاسم الكامل', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    if (area.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال المنطقة أو الحي', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    // Validate Phone 1 (Mandatory 11 digits starting with 07)
    final phone1Error = Validators.validateIraqiPhone(phone1, isRequired: true);
    if (phone1Error != null) {
      Get.snackbar('رقم هاتف غير صحيح', phone1Error, backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    // Validate Phone 2 (Optional, but if provided must be 11 digits starting with 07)
    String phone2 = '';
    if (phone2Raw.isNotEmpty) {
      phone2 = Validators.formatLocalIraqiPhone(phone2Raw);
      final phone2Error = Validators.validateIraqiPhone(phone2, isRequired: false);
      if (phone2Error != null) {
        Get.snackbar('الرقم الثاني غير صحيح', phone2Error, backgroundColor: AppColors.outOfStock, colorText: Colors.white);
        return;
      }
    }

    final rawList = _storage.read<List>('user_addresses') ?? [];
    final List<Map<String, dynamic>> addresses = rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final item = {
      'id': isEditing
          ? widget.initialAddress!['id']
          : DateTime.now().millisecondsSinceEpoch.toString(),
      'full_name': name,
      'city': _selectedCity,
      'area': area,
      'street': street,
      'phone': phone1,
      'phone2': phone2,
      'is_default': isEditing
          ? (widget.initialAddress!['is_default'] ?? false)
          : addresses.isEmpty,
    };

    if (isEditing) {
      addresses[widget.editIndex!] = item;
    } else {
      addresses.add(item);
    }

    await _storage.write('user_addresses', addresses);
    Get.back(result: item);
    Get.snackbar(
      'نجاح',
      isEditing ? 'تم تحديث العنوان' : 'تمت إضافة العنوان بنجاح',
      backgroundColor: AppColors.inStock,
      colorText: Colors.white,
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
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Top Unified Header
                AppHeaderWidget(
                  title: isEditing ? 'تعديل العنوان' : 'إضافة عنوان جديد',
                  showBack: true,
                ),

                // Form Page Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                          // Full Name
                          _buildFieldLabel('الاسم الكامل *'),
                          _buildInput(controller: _nameCtrl, hint: 'الاسم'),
                          const SizedBox(height: 14),

                          // Governorate
                          _buildFieldLabel('المحافظة / المدينة *'),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF64748B),
                                ),
                                items: governorates.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCity = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Area
                          _buildFieldLabel('المنطقة *'),
                          _buildInput(controller: _areaCtrl, hint: 'المنطقة / الحي'),
                          const SizedBox(height: 14),

                          // Landmark / Street
                          _buildFieldLabel('أقرب نقطة دالة (اختياري)'),
                          _buildInput(controller: _streetCtrl, hint: 'أقرب نقطة دالة / الشارع'),
                          const SizedBox(height: 14),

                          // Phone 1
                          _buildFieldLabel('رقم الهاتف الأول (11 رقم يبدأ بـ 07) *'),
                          _buildInput(
                            controller: _phoneCtrl,
                            hint: '07xxxxxxxxx',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Phone 2
                          _buildFieldLabel('رقم الهاتف الثاني (اختياري)'),
                          _buildInput(
                            controller: _phone2Ctrl,
                            hint: '07xxxxxxxxx',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _saveAddress,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: const Color(0xFF0A192F),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      isEditing ? 'تحديث' : 'حفظ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
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
    );
  }
}
