import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../data/models/replacement_model.dart';
import '../../../data/repositories/replacement_repository.dart';

class ReplacementDetailsView extends StatefulWidget {
  final String replacementId;
  final ReplacementModel? initialRequest;

  const ReplacementDetailsView({
    super.key,
    required this.replacementId,
    this.initialRequest,
  });

  @override
  State<ReplacementDetailsView> createState() => _ReplacementDetailsViewState();
}

class _ReplacementDetailsViewState extends State<ReplacementDetailsView> {
  final AuthService _auth = Get.find<AuthService>();
  final ReplacementRepository _repo = Get.find<ReplacementRepository>();
  final ImagePicker _picker = ImagePicker();

  ReplacementModel? _request;
  List<ReplacementStatusLogModel> _logs = [];
  Map<String, String> _signedUrls = {};
  bool _isLoading = true;
  bool _isUploading = false;
  String? _deletingPath;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    if (_request != null) {
      _isLoading = false;
      if (_request!.attachments.isNotEmpty) {
        _loadSignedUrls(_request!.attachments);
      }
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    final req = await _repo.fetchReplacementById(widget.replacementId);
    final logs = await _repo.fetchStatusLog(widget.replacementId);

    if (mounted) {
      setState(() {
        if (req != null) {
          _request = req;
        }
        _logs = logs;
        _isLoading = false;
      });
    }

    if (req != null && req.attachments.isNotEmpty) {
      _loadSignedUrls(req.attachments);
    }
  }

  Future<void> _loadSignedUrls(List<String> paths) async {
    final Map<String, String> urls = {};
    for (final p in paths) {
      final signed = await _repo.getSignedUrl(p);
      if (signed != null) {
        urls[p] = signed;
      }
    }
    if (mounted) {
      setState(() {
        _signedUrls = urls;
      });
    }
  }

  void _pickAndUpload() async {
    final req = _request;
    if (req == null || _isUploading) return;
    if (req.attachments.length >= 6) {
      Get.snackbar('تنبيه', 'الحد الأقصى للمرفقات هو 6 صور', backgroundColor: AppColors.navyDark, colorText: Colors.white);
      return;
    }

    final source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر مصدر الصورة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.gold),
              title: Text('المعرض', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.gold),
              title: Text('الكاميرا', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploading = true);
    final pathKey = await _repo.uploadAttachment(
      userId: _auth.currentUser.value?.id ?? req.userId,
      requestId: req.id,
      file: image,
    );

    if (pathKey != null) {
      final next = [...req.attachments, pathKey];
      await _repo.updateAttachments(req.id, next);
      Get.snackbar('تم الرفع', 'تم إرفاق الصورة بنجاح', backgroundColor: AppColors.navyDark, colorText: Colors.white);
      await _loadAll();
    } else {
      Get.snackbar('خطأ', 'تعذّر رفع الصورة، يرجى المحاولة لاحقاً', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    }

    if (mounted) setState(() => _isUploading = false);
  }

  void _deleteAttachment(String pathKey) async {
    final req = _request;
    if (req == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف المرفق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل تريد حذف هذه الصورة من الطلب؟', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _deletingPath = pathKey);
      final success = await _repo.deleteAttachment(
        requestId: req.id,
        pathKey: pathKey,
        currentAttachments: req.attachments,
      );
      setState(() => _deletingPath = null);

      if (success) {
        Get.snackbar('تم الحذف', 'تم حذف المرفق بنجاح', backgroundColor: AppColors.navyDark, colorText: Colors.white);
        await _loadAll();
      }
    }
  }

  void _openImageViewer(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final req = _request;

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
              AppHeaderWidget(
                title: req != null ? 'طلب استبدال #${req.shortId}' : 'تفاصيل الاستبدال',
                showBack: true,
                showNotifications: false,
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : req == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  'لم يتم العثور على طلب الاستبدال',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Current Status Banner
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: req.statusBgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(req.statusIcon, color: req.statusColor, size: 26),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'الحالة الحالية',
                                              style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF64748B)),
                                            ),
                                            Text(
                                              req.statusLabel,
                                              style: GoogleFonts.cairo(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: req.statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 2. Product Name Card
                                _buildCard(
                                  title: 'المنتج المطلوب استبداله',
                                  icon: Icons.inventory_2_outlined,
                                  child: Text(
                                    req.productNameAr,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 3. Reason Card
                                _buildCard(
                                  title: 'سبب الاستبدال',
                                  icon: Icons.description_outlined,
                                  child: Text(
                                    req.reason,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.5,
                                      color: const Color(0xFF334155),
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                                // 4. Admin Notes Card (if present)
                                if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFDF5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.sticky_note_2_outlined, color: AppColors.gold, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'رد قسم الاستبدال',
                                              style: GoogleFonts.cairo(
                                                color: AppColors.gold,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          req.adminNotes!,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13.5,
                                            color: const Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 14),

                                // 5. Attachments Card
                                _buildCard(
                                  title: 'مرفقات (صور / مستندات)',
                                  icon: Icons.attach_file_rounded,
                                  trailing: '${req.attachments.length}/6',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (req.attachments.isEmpty && !_isUploading)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            'لا توجد صور مرفقة بعد',
                                            style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                          ),
                                        ),

                                      if (req.attachments.isNotEmpty) ...[
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: req.attachments.length,
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.0,
                                          ),
                                          itemBuilder: (context, idx) {
                                            final pathKey = req.attachments[idx];
                                            final url = _signedUrls[pathKey];
                                            final isDeleting = _deletingPath == pathKey;

                                            return Stack(
                                              children: [
                                                GestureDetector(
                                                  onTap: url != null ? () => _openImageViewer(url) : null,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                                      color: const Color(0xFFF1F5F9),
                                                    ),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: url != null
                                                        ? CachedNetworkImage(
                                                            imageUrl: url,
                                                            width: double.infinity,
                                                            height: double.infinity,
                                                            fit: BoxFit.cover,
                                                            placeholder: (_, __) => const Center(
                                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                                            ),
                                                            errorWidget: (_, __, ___) => const Center(
                                                              child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                                            ),
                                                          )
                                                        : const Center(
                                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                                          ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  left: 4,
                                                  child: GestureDetector(
                                                    onTap: isDeleting ? null : () => _deleteAttachment(pathKey),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.65),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: isDeleting
                                                          ? const SizedBox(
                                                              width: 12,
                                                              height: 12,
                                                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                                            )
                                                          : const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      if (req.attachments.length < 6)
                                        SizedBox(
                                          width: double.infinity,
                                          height: 44,
                                          child: OutlinedButton.icon(
                                            onPressed: _isUploading ? null : _pickAndUpload,
                                            icon: _isUploading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                                  )
                                                : const Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.gold),
                                            label: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                _isUploading ? 'جاري رفع الصورة...' : 'إرفاق صورة جديدة',
                                                style: GoogleFonts.cairo(
                                                  color: const Color(0xFF0A192F),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 6. Status Log Timeline
                                _buildCard(
                                  title: 'سجل الحالات',
                                  icon: Icons.timeline_rounded,
                                  child: _logs.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            'لا توجد تحديثات سابقة',
                                            style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                          ),
                                        )
                                      : Column(
                                          children: _logs.map((log) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: log.statusColor.withValues(alpha: 0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(log.statusIcon, color: log.statusColor, size: 16),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          log.statusLabel,
                                                          style: GoogleFonts.cairo(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatDate(log.createdAt),
                                                          style: GoogleFonts.cairo(
                                                            fontSize: 11,
                                                            color: const Color(0xFF94A3B8),
                                                          ),
                                                        ),
                                                        if (log.note != null && log.note!.isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFF1F5F9),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              log.note!,
                                                              style: GoogleFonts.cairo(
                                                                fontSize: 12,
                                                                color: const Color(0xFF475569),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),

                                const SizedBox(height: 16),

                                Center(
                                  child: Text(
                                    'أُنشئ الطلب في ${_formatDate(req.createdAt)}',
                                    style: GoogleFonts.cairo(fontSize: 11.5, color: const Color(0xFF94A3B8)),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    String? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                Text(
                  trailing,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
