import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    super.initState();
    _refreshAccountData();
  }

  void _refreshAccountData() async {
    final auth = Get.find<AuthService>();
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

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final auth = Get.find<AuthService>();
    final cart = Get.find<CartService>();

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
                // Top AppHeader: Store Avatar + "حسابي" + Subtitle + Action Icons
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
                              'حسابي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.storeTagline,
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

                      // Notification Bell
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.notifications),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF132B45),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Cart Icon with Badge
                      Obx(() {
                        final count = cart.cartCount.value;
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
                                // Circular Avatar with S Letter / Image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0D9488),
                                    border: Border.all(color: AppColors.gold, width: 1.8),
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
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),

                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name + Edit icon
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              auth.userName.value.isNotEmpty ? auth.userName.value : 'عميل Ali Parts',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => _showEditNameDialog(context, auth),
                                            child: const Icon(Icons.edit_rounded, color: AppColors.gold, size: 16),
                                          ),
                                        ],
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

                                      const SizedBox(height: 4),

                                      // Change Photo text
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, color: AppColors.gold.withValues(alpha: 0.85), size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تغيير الصورة',
                                            style: TextStyle(
                                              color: AppColors.gold.withValues(alpha: 0.85),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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

                      // 2. Points Card
                      Obx(() {
                        final pts = auth.pointsBalance.value;
                        final pointsIqd = pts * 50;

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
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '≈ ${Formatters.formatIQD(pointsIqd.toDouble())}',
                                          style: TextStyle(
                                            color: const Color(0xFF0A192F).withValues(alpha: 0.75),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'كل 100 نقطة = 5,000 دينار خصم عند الشراء',
                                      style: TextStyle(
                                        color: const Color(0xFF0A192F).withValues(alpha: 0.7),
                                        fontSize: 10,
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
                                      icon: Icons.shield_outlined,
                                      title: 'لوحة الإدارة',
                                      onTap: () => Get.toNamed(AppRoutes.admin),
                                    ),
                                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  ],
                                );
                              }),

                              // 2. My Orders
                              _buildMenuItem(
                                icon: Icons.inventory_2_outlined,
                                title: 'طلباتي السابقة',
                                onTap: () => Get.toNamed(AppRoutes.orders),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 3. Favorites
                              _buildMenuItem(
                                icon: Icons.favorite_border_rounded,
                                title: 'المفضلة',
                                onTap: () => Get.toNamed(AppRoutes.favorites),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 4. Addresses
                              _buildMenuItem(
                                icon: Icons.location_on_outlined,
                                title: 'العناوين',
                                onTap: () => Get.toNamed(AppRoutes.addresses),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 5. Notifications
                              _buildMenuItem(
                                icon: Icons.notifications_none_rounded,
                                title: 'الإشعارات',
                                onTap: () => Get.toNamed(AppRoutes.notifications),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 6. Contact Us
                              _buildMenuItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'اتصل بنا',
                                onTap: () async {
                                  final url = Formatters.generateWhatsAppUrl(phone: settings.whatsappNumber);
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 7. About Us
                              _buildMenuItem(
                                icon: Icons.info_outline_rounded,
                                title: 'من نحن',
                                onTap: () => Get.toNamed(AppRoutes.about),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 8. Privacy Policy
                              _buildMenuItem(
                                icon: Icons.shield_outlined,
                                title: 'سياسة الخصوصية',
                                onTap: () => Get.toNamed(AppRoutes.privacy),
                              ),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),

                              // 9. Terms and Conditions
                              _buildMenuItem(
                                icon: Icons.description_outlined,
                                title: 'الشروط والأحكام',
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
                                  Get.snackbar(
                                    'تم',
                                    'تم تسجيل الخروج بنجاح',
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
                                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
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
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعديل الاسم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (ctrl.text.trim().isNotEmpty) {
                        await auth.updateFullName(ctrl.text.trim());
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                                  Get.back();
                                  Get.snackbar(
                                    'تم حذف الحساب',
                                    'تم حذف حسابك نهائياً. نأسف لرحيلك.',
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
