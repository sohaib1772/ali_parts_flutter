import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/banner_comment_model.dart';
import '../../../data/repositories/reels_repository.dart';

class ReelsCommentsSheet extends StatefulWidget {
  final String bannerId;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onCommentDeleted;

  const ReelsCommentsSheet({
    super.key,
    required this.bannerId,
    this.onCommentAdded,
    this.onCommentDeleted,
  });

  static void show(
    BuildContext context,
    String bannerId, {
    VoidCallback? onCommentAdded,
    VoidCallback? onCommentDeleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReelsCommentsSheet(
        bannerId: bannerId,
        onCommentAdded: onCommentAdded,
        onCommentDeleted: onCommentDeleted,
      ),
    );
  }

  @override
  State<ReelsCommentsSheet> createState() => _ReelsCommentsSheetState();
}

class _ReelsCommentsSheetState extends State<ReelsCommentsSheet> {
  final ReelsRepository _reelsRepo = Get.find<ReelsRepository>();
  final AuthService _auth = Get.find<AuthService>();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<BannerCommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  BannerCommentModel? _replyingTo;
  bool _asOfficeName = true;

  bool get _isAdminOrStaff => _auth.isAdmin.value || _auth.isStaff.value;

  bool get _canModerate {
    if (_auth.isAdmin.value) return true;
    if (_auth.isStaff.value) {
      final perms = _auth.staffPermissions.value ?? {};
      return perms['can_moderate_comments'] == true ||
          perms['can_manage_banners'] == true ||
          perms['can_manage_products'] == true;
    }
    return false;
  }

  int get _totalCommentsCount {
    int total = _comments.length;
    for (final c in _comments) {
      total += c.replies.length;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _reelsRepo.fetchComments(widget.bannerId);
      if (mounted) {
        setState(() {
          _comments = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    if (_auth.userId == null || _auth.userId!.isEmpty) {
      Get.snackbar('تسجيل الدخول', 'يرجى تسجيل الدخول أولاً لإضافة تعليق');
      return;
    }

    setState(() => _isSending = true);
    try {
      final newComment = await _reelsRepo.addComment(
        bannerId: widget.bannerId,
        userId: _auth.userId,
        content: text,
        parentId: _replyingTo?.id,
        isAdminReply: _isAdminOrStaff && _asOfficeName,
      );

      if (newComment != null) {
        _textCtrl.clear();
        setState(() {
          _replyingTo = null;
        });
        widget.onCommentAdded?.call();
        await _loadComments();
      }
    } catch (e) {
      Get.snackbar('تنبيه', 'تعذر إضافة التعليق، يرجى المحاولة لاحقاً');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(BannerCommentModel comment) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف التعليق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا التعليق؟', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Get.back(result: true),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _reelsRepo.deleteComment(comment.id);
      if (ok) {
        widget.onCommentDeleted?.call();
        _loadComments();
      }
    }
  }

  Future<void> _blockUser(BannerCommentModel comment) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حظر المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFDC2626))),
        content: Text('هل تريد بالتأكيد حظر "${comment.userName}" من التعليق والتفاعل؟', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Get.back(result: true),
            child: Text('تأكيد الحظر', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _reelsRepo.blockUser(comment.userId);
      if (ok) {
        Get.snackbar('تم الحظر', 'تم حظر حساب المستخدم بنجاح', backgroundColor: const Color(0xFFDC2626), colorText: Colors.white);
        _loadComments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التعليقات ($_totalCommentsCount)',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0A192F),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(IconsaxPlusBold.messages_2, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 10),
                            Text(
                              'لا توجد تعليقات بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              'كن أول من يشاركنا رأيه!',
                              style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _buildCommentItem(_comments[i]),
                      ),
          ),

          // Replying banner
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  const Icon(IconsaxPlusBold.undo, size: 14, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الرد على: ${_replyingTo?.userName ?? ""}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A192F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _replyingTo = null),
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Bottom Input Field
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin / Staff checkbox option
                if (_isAdminOrStaff)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => setState(() => _asOfficeName = !_asOfficeName),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _asOfficeName,
                                onChanged: (val) => setState(() => _asOfficeName = val ?? false),
                                activeColor: AppColors.gold,
                                checkColor: const Color(0xFF0A192F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _asOfficeName ? IconsaxPlusBold.verify : IconsaxPlusLinear.profile,
                              size: 14,
                              color: _asOfficeName ? AppColors.gold : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _replyingTo != null
                                  ? 'الرد باسم "مكتب علي شوفرليت"'
                                  : 'التعليق باسم "مكتب علي شوفرليت"',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _asOfficeName ? const Color(0xFF0A192F) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _textCtrl,
                          focusNode: _focusNode,
                          textDirection: TextDirection.rtl,
                          minLines: 1,
                          maxLines: 3,
                          style: GoogleFonts.cairo(fontSize: 13.5, color: const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? (_asOfficeName && _isAdminOrStaff ? 'اكتب رد مكتب علي شوفرليت...' : 'اكتب ردك هنا...')
                                : (_asOfficeName && _isAdminOrStaff ? 'أضف تعليقاً باسم مكتب علي شوفرليت...' : 'أضف تعليقاً على هذا العرض...'),
                            hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A192F),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendComment,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(IconsaxPlusBold.send_1, color: Colors.white, size: 18),
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

  Widget _buildCommentItem(BannerCommentModel comment, {bool isReply = false}) {
    final canDeleteThis = _canModerate || (_auth.userId != null && _auth.userId == comment.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (Office logo or User profile image / initial)
            _buildAvatar(comment, isReply: isReply),
            const SizedBox(width: 10),

            // Comment Box
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: comment.isAdminReply ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: comment.isAdminReply ? AppColors.gold.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              comment.userName,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: comment.isAdminReply ? const Color(0xFFB45309) : const Color(0xFF0A192F),
                              ),
                            ),
                            if (comment.isAdminReply) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'مكتب علي شوفرليت',
                                  style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          comment.content,
                          style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // Actions under comment: Time, Reply, Delete, Block
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Row(
                      children: [
                        Text(
                          _formatTime(comment.createdAt),
                          style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _replyingTo = comment;
                            });
                            _focusNode.requestFocus();
                          },
                          child: Text(
                            'رد',
                            style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F)),
                          ),
                        ),
                        if (canDeleteThis) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _deleteComment(comment),
                            child: const Text(
                              'حذف',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                        if (_canModerate && !comment.isAdminReply && comment.userId != _auth.userId) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _blockUser(comment),
                            child: const Text(
                              'حظر',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Nested Replies
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 32, top: 10),
            child: Column(
              children: comment.replies.map((reply) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCommentItem(reply, isReply: true),
              )).toList(),
            ),
          ),
      ],
    );
  }


  Widget _buildAvatar(BannerCommentModel comment, {required bool isReply}) {
    final size = isReply ? 30.0 : 38.0;

    if (comment.isAdminReply) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A192F),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    final avatarUrl = comment.userAvatar?.trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A192F),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => _buildInitialFallback(comment, isReply, size),
            errorWidget: (_, __, ___) => _buildInitialFallback(comment, isReply, size),
          ),
        ),
      );
    }

    return _buildInitialFallback(comment, isReply, size);
  }

  Widget _buildInitialFallback(BannerCommentModel comment, bool isReply, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0A192F),
      ),
      alignment: Alignment.center,
      child: Text(
        comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '؟',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isReply ? 11 : 13,
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
      return 'منذ ${diff.inDays} ي';
    } catch (_) {
      return '';
    }
  }
}
