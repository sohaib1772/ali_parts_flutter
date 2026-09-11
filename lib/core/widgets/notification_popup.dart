import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

/// Full-screen popup overlay shown when a new notification arrives.
/// Matches the website's `notification-popup.tsx` with a clean white modal card.
class NotificationPopup extends StatefulWidget {
  final String title;
  final String? body;
  final String? type;
  final String notifId;
  final String? orderId;

  const NotificationPopup({
    super.key,
    required this.title,
    this.body,
    this.type,
    required this.notifId,
    this.orderId,
  });

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();

  /// Convenience factory to show the popup via GetX dialog.
  static void show({
    required String title,
    String? body,
    String? type,
    required String notifId,
    String? orderId,
  }) {
    if (title.isEmpty) return;
    if (Get.isDialogOpen == true) return; // don't stack

    Get.dialog(
      NotificationPopup(
        title: title,
        body: body,
        type: type,
        notifId: notifId,
        orderId: orderId,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
    );
  }
}

class _NotificationPopupState extends State<NotificationPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  Timer? _autoDismiss;

  bool get _isBlock =>
      widget.type == 'account_status' ||
      (widget.title).contains('حظر') ||
      (widget.body ?? '').contains('حظر');

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();

    _autoDismiss = Timer(const Duration(seconds: 8), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    if (mounted && Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _viewNotification() {
    _dismiss();
    if (widget.notifId.isNotEmpty) {
      Get.find<NotificationService>().markRead(widget.notifId);
    }
    // Use the centralized navigation handler
    Get.find<NotificationService>().handleNotificationNavigation(
      type: widget.type,
      orderId: widget.orderId,
    );
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor =
        _isBlock ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.12),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Close button ──────────────────────────────────
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                // ── Glowing 3D icon ──────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isBlock
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFE11D48),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              const Color(0xFFFBBF24),
                              const Color(0xFFF59E0B),
                              const Color(0xFFD97706),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.45),
                        blurRadius: 25,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      _isBlock
                          ? Icons.shield_rounded
                          : Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Title ────────────────────────────────────────
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                // ── Body ─────────────────────────────────────────
                if (widget.body != null && widget.body!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.body!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ── Action buttons ──────────────────────────────
                Row(
                  children: [
                    // "عرض" view button — navigates to the notification target
                    if (!_isBlock) ...[
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _viewNotification,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0A192F),
                              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Text(
                              'عرض',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // "تم" dismiss button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A192F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Text(
                            'تم',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
    );
  }
}
