import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import '../../../data/models/replacement_model.dart';
import '../../../data/repositories/replacement_repository.dart';
import 'replacement_details_view.dart';

class ReplacementsView extends StatefulWidget {
  const ReplacementsView({super.key});

  @override
  State<ReplacementsView> createState() => _ReplacementsViewState();
}

class _ReplacementsViewState extends State<ReplacementsView> {
  final AuthService _auth = Get.find<AuthService>();
  final ReplacementRepository _repo = Get.find<ReplacementRepository>();
  final ScrollController _scrollController = ScrollController();

  List<ReplacementModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    final list = await _repo.fetchMyReplacements(userId);
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d · $h:$min';
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
                title: 'طلبات الاستبدال',
                showBack: true,
                showNotifications: false,
              ),

              // Content Body
              Expanded(
                child: Stack(
                  children: [
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          )
                        : RefreshIndicator(
                            color: AppColors.gold,
                            onRefresh: _loadData,
                            child: _items.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.65,
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 76,
                                                  height: 76,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.gold.withValues(alpha: 0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.repeat_rounded,
                                                    color: AppColors.gold,
                                                    size: 38,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                Text(
                                                  'لا توجد طلبات استبدال',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'يمكنك طلب استبدال لأي قطعة بعد استلام الطلب من صفحة تفاصيل الطلب.',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 13,
                                                    color: const Color(0xFF64748B),
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                SizedBox(
                                                  height: 44,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => Get.toNamed(AppRoutes.orders),
                                                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                                                    label: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        'الانتقال إلى طلباتي',
                                                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, height: 1.2),
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.gold,
                                                      foregroundColor: const Color(0xFF0A192F),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = _items[index];

                                      return Material(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          onTap: () {
                                            Get.to(
                                              () => ReplacementDetailsView(
                                                replacementId: item.id,
                                                initialRequest: item,
                                              ),
                                              transition: Transition.fade,
                                            )?.then((_) => _loadData());
                                          },
                                          borderRadius: BorderRadius.circular(18),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.02),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Top Header: Short ID + Status Chip
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '#${item.shortId}',
                                                      style: GoogleFonts.sourceCodePro(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: item.statusBgColor,
                                                        borderRadius: BorderRadius.circular(100),
                                                        border: Border.all(
                                                          color: item.statusColor.withValues(alpha: 0.35),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(item.statusIcon, size: 13, color: item.statusTextColor),
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            item.statusLabel,
                                                            style: GoogleFonts.cairo(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: item.statusTextColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 10),

                                                // Product Name
                                                Text(
                                                  item.productNameAr,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),

                                                if (item.reason.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.reason,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 12.5,
                                                      color: const Color(0xFF64748B),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],

                                                const SizedBox(height: 12),
                                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                                const SizedBox(height: 10),

                                                // Date & Chevron
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatDate(item.createdAt),
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 11.5,
                                                        color: const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'التفاصيل',
                                                          style: GoogleFonts.cairo(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.gold,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons.chevron_left_rounded,
                                                          size: 18,
                                                          color: AppColors.gold,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                    // Floating Glass Scroll To Top Button
                    GlassScrollToTopButton(
                      scrollController: _scrollController,
                      bottom: 20,
                      left: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
