import '../../../core/widgets/app_header_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../../main_nav/controllers/main_nav_controller.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _refreshAccountData();
  }

  void _refreshAccountData() async {
    final auth = Get.find<AuthService>();
    final settings = Get.find<SettingsService>();
    await settings.fetchSettings();
    if (auth.isLoggedIn.value) {
      await auth.fetchUserProfile();
      final sec = Get.find<SecureStorageService>();
      final uid = await sec.read(AppConstants.secureKeyUserId);
      if (uid != null && uid.isNotEmpty) {
        Get.find<CartService>().syncWithServer(uid);
        Get.find<FavoritesService>().syncWithServer(uid);
      }
    }
  }

  Future<void> _pickAndUploadAvatar(AuthService auth) async {
    if (_isUploadingAvatar) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}_${picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

      final dio = Get.find<DioClient>().dio;
      await dio.post(
        '/storage/v1/object/product-images/$fileName',
        data: bytes,
        options: Options(headers: {'Content-Type': safeExt == 'png' ? 'image/png' : 'image/jpeg'}),
      );

      final uploadedUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
      final ok = await auth.updateAvatar(uploadedUrl);
      if (ok) {
        Get.snackbar(
          'نجاح',
          'تم تحديث الصورة الشخصية بنجاح',
          backgroundColor: AppColors.inStock,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر حفظ الصورة الشخصية',
          backgroundColor: AppColors.outOfStock,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر رفع الصورة: $e',
        backgroundColor: AppColors.outOfStock,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final auth = Get.find<AuthService>();

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
                const AppHeaderWidget(
                  title: 'حسابي',
                  showBack: false,
                ),

                // Scrollable Body Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    children: [
                      // 1. Profile Header Card
                      Obx(() {
                        final loggedIn = auth.isLoggedIn.value;

                        if (loggedIn) {
                          final initial = (auth.userName.value.isNotEmpty
                                  ? auth.userName.value[0]
                                  : (auth.userEmail.value.isNotEmpty ? auth.userEmail.value[0] : 'S'))
                              .toUpperCase();

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0A192F), Color(0xFF102A43)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Circular Avatar with S Letter / Image + Tap to change
                                GestureDetector(
                                  onTap: () => _pickAndUploadAvatar(auth),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 62,
                                        height: 62,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0D9488),
                                          border: Border.all(
                                            color: AppColors.gold.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gold.withValues(alpha: 0.2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: auth.userAvatar.value.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: auth.userAvatar.value,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) => Center(
                                                  child: Text(
                                                    initial,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w900,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                      ),
                                      if (_isUploadingAvatar)
                                        Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withValues(alpha: 0.5),
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name + Edit icon (both clickable!)
                                      GestureDetector(
                                        onTap: () => _showEditNameDialog(context, auth),
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                auth.userName.value.isNotEmpty ? auth.userName.value : 'عميل Ali Parts',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.edit_rounded, color: AppColors.gold, size: 16),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),

                                      // Email in gold
                                      Text(
                                        auth.userEmail.value,
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      // Phone number if available
                                      if (auth.userPhone.value.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            auth.userPhone.value,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.75),
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 5),

                                      // Change Photo text button
                                      GestureDetector(
                                        onTap: () => _pickAndUploadAvatar(auth),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt_outlined, color: AppColors.gold.withValues(alpha: 0.9), size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              auth.userAvatar.value.isNotEmpty ? 'تغيير الصورة' : 'إضافة صورة شخصية',
                                              style: TextStyle(
                                                color: AppColors.gold.withValues(alpha: 0.9),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Guest Login Card
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF102A43),
                                  border: Border.all(color: AppColors.gold, width: 1.5),
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: AppColors.gold, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'سجّل دخولك للاستفادة من كل الميزات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'تتبع طلباتك، احفظ مفضلاتك، واستمتع بتجربة أفضل',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final res = await Get.toNamed(AppRoutes.login);
                                    if (res == true) _refreshAccountData();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      // 2. Points Card (Synchronized with Server App Settings!)
                      Obx(() {
                        final pts = auth.pointsBalance.value;
                        final redeemRate = settings.pointsRedeemIqdPerPoint;
                        final pointsIqd = pts * redeemRate;
                        final cardText = settings.pointsCardText.isNotEmpty
                            ? settings.pointsCardText
                            : 'كل 100 نقطة = ${Formatters.formatIQD(100 * redeemRate)} خصم عند الشراء';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0A192F).withValues(alpha: 0.12),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0A192F), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'رصيد نقاطك',
                                      style: TextStyle(
                                        color: Color(0xFF0A192F),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '$pts نقطة',
                                          style: const TextStyle(
                                            color: Color(0xFF0A192F),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '≈ ${Formatters.formatIQD(pointsIqd.toDouble())}',
                                          style: TextStyle(
                                            color: const Color(0xFF0A192F).withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cardText,
                                      style: TextStyle(
                                        color: const Color(0xFF0A192F).withValues(alpha: 0.75),
                                        fontSize: 10,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // 3. Main Menu Card List (Navigate to dedicated views)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              // 1. Admin Dashboard (Only if Admin)
                              Obx(() {
                                if (!auth.isAdmin.value) return const SizedBox.shrink();
                                return Column(
                                  children: [
                                    _buildMenuItem(
                                      icon: IconsaxPlusBold.shield_security,
                                      title: 'لوحة الإدارة',
                                      gradientColors: const [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
                                      onTap: () => Get.toNamed(AppRoutes.admin),
                                    ),
                                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  ],
                                );
                              }),

                              // 2. My Orders
                              _buildMenuItem(
                                icon: IconsaxPlusBold.box,
                                title: 'طلباتي السابقة',
                                gradientColors: const [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF38BDF8)],
                                onTap: () => Get.toNamed(AppRoutes.orders),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 3. Replacement Requests
                              _buildMenuItem(
                                icon: IconsaxPlusBold.convert,
                                title: 'طلبات الاستبدال',
                                gradientColors: const [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                                onTap: () => Get.toNamed(AppRoutes.replacements),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 4. Favorites
                              _buildMenuItem(
                                icon: IconsaxPlusBold.heart,
                                title: 'المفضلة',
                                gradientColors: const [Color(0xFFBE123C), Color(0xFFE11D48), Color(0xFFFB7185)],
                                onTap: () => Get.toNamed(AppRoutes.favorites),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 5. Addresses
                              _buildMenuItem(
                                icon: IconsaxPlusBold.location,
                                title: 'العناوين',
                                gradientColors: const [Color(0xFFC2410C), Color(0xFFEA580C), Color(0xFFFB923C)],
                                onTap: () => Get.toNamed(AppRoutes.addresses),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 6. Notifications
                              _buildMenuItem(
                                icon: IconsaxPlusBold.notification_bing,
                                title: 'الإشعارات',
                                gradientColors: const [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFFBBF24)],
                                onTap: () => Get.toNamed(AppRoutes.notifications),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 7. Contact Us
                              _buildMenuItem(
                                icon: IconsaxPlusBold.messages_2,
                                title: 'اتصل بنا',
                                gradientColors: const [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF4ADE80)],
                                onTap: () async {
                                  final url = Formatters.generateWhatsAppUrl(phone: settings.whatsappNumber);
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 8. About Us
                              _buildMenuItem(
                                icon: IconsaxPlusBold.info_circle,
                                title: 'من نحن',
                                gradientColors: const [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
                                onTap: () => Get.toNamed(AppRoutes.about),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 9. Privacy Policy
                              _buildMenuItem(
                                icon: IconsaxPlusBold.security_safe,
                                title: 'سياسة الخصوصية',
                                gradientColors: const [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFFA78BFA)],
                                onTap: () => Get.toNamed(AppRoutes.privacy),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 10. Terms and Conditions
                              _buildMenuItem(
                                icon: IconsaxPlusBold.document_text_1,
                                title: 'الشروط والأحكام',
                                gradientColors: const [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
                                onTap: () => Get.toNamed(AppRoutes.terms),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Sign Out Button & Delete Account Section
                      Obx(() {
                        if (!auth.isLoggedIn.value) return const SizedBox.shrink();

                        return Column(
                          children: [
                            const SizedBox(height: 18),

                            // Logout Outlined Pill Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await auth.signOut();
                                  if (Get.isRegistered<MainNavController>()) {
                                    Get.find<MainNavController>().currentIndex.value = 0;
                                  }
                                  Get.offAllNamed(AppRoutes.mainNav);
                                  Get.snackbar(
                                    'تم تسجيل الخروج',
                                    'تم مسح كافة البيانات وتسجيل الخروج بنجاح',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: AppColors.navyMedium,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                    borderRadius: 12,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFDC2626),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(IconsaxPlusBold.logout, color: Color(0xFFDC2626), size: 19),
                                    SizedBox(width: 8),
                                    Text(
                                      'تسجيل الخروج',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Delete Account Text Button
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _showDeleteAccountDialog(context, auth),
                                icon: const Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 17),
                                label: const Text(
                                  'حذف الحساب',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 24),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    Color? shadowColor,
  }) {
    final baseColor = gradientColors[1];
    final effShadow = shadowColor ?? baseColor.withValues(alpha: 0.35);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3.5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthService auth) {
    final ctrl = TextEditingController(text: auth.userName.value);
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDlgState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Container(
              padding: const EdgeInsets.all(22),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Text(
                        'تعديل الاسم',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    'الاسم الكامل',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسمك الكامل',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final trimmed = ctrl.text.trim();
                              if (trimmed.length < 2) {
                                Get.snackbar(
                                  'تنبيه',
                                  'الاسم قصير جداً (حرفين كحد أدنى)',
                                  backgroundColor: AppColors.outOfStock,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.TOP,
                                );
                                return;
                              }
                              setDlgState(() => isSaving = true);
                              final ok = await auth.updateFullName(trimmed);
                              Get.back();
                              if (ok) {
                                Get.snackbar(
                                  'نجاح',
                                  'تم تحديث الاسم بنجاح',
                                  backgroundColor: AppColors.inStock,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.TOP,
                                );
                              } else {
                                Get.snackbar(
                                  'خطأ',
                                  'تعذر تحديث الاسم',
                                  backgroundColor: AppColors.outOfStock,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.TOP,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A192F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService auth) {
    final confirmCtrl = TextEditingController();
    bool isDeleting = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'حذف الحساب نهائياً',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'لا يمكن التراجع عن هذا الإجراء.\nسيتم مسح بياناتك الشخصية، العناوين، السلة، والمفضلة نهائياً.\n\nللتأكيد، اكتب كلمة "حذف" في الحقل أدناه:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmCtrl,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
                    decoration: InputDecoration(
                      hintText: 'حذف',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isDeleting ? null : () => Get.back(),
                          child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (confirmCtrl.text.trim() != 'حذف' || isDeleting)
                              ? null
                              : () async {
                                  setState(() => isDeleting = true);
                                  try {
                                    final dio = Get.find<DioClient>().dio;
                                    await dio.post(
                                      '/rest/v1/rpc/delete_my_account',
                                    );
                                  } catch (_) {}
                                  await auth.signOut();
                                  if (Get.isRegistered<MainNavController>()) {
                                    Get.find<MainNavController>().currentIndex.value = 0;
                                  }
                                  Get.offAllNamed(AppRoutes.mainNav);
                                  Get.snackbar(
                                    'تم حذف الحساب',
                                    'تم حذف حسابك ومسح كافة بياناتك بنجاح',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: AppColors.navyMedium,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 3),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFFCA5A5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
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
}
