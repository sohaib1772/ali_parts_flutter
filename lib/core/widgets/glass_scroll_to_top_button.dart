import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable Apple TV-style Glassmorphic "Scroll to Top" floating button
/// with smooth scale & opacity entry/exit animations.
class GlassScrollToTopButton extends StatefulWidget {
  /// The ScrollController to listen to for automatic visibility & scrolling.
  final ScrollController? scrollController;

  /// Custom visibility override if not using automatic scrollController listening.
  final bool? isVisible;

  /// Custom tap callback (defaults to scrolling `scrollController` to 0).
  final VoidCallback? onTap;

  /// Offset from bottom of the parent Stack. Defaults to 85 (above bottom nav bar).
  final double bottom;

  /// Offset from left of the parent Stack. Defaults to 18.
  final double left;

  /// Scroll offset threshold in pixels to show the button. Defaults to 250.
  final double threshold;

  const GlassScrollToTopButton({
    super.key,
    this.scrollController,
    this.isVisible,
    this.onTap,
    this.bottom = 85,
    this.left = 18,
    this.threshold = 250,
  });

  @override
  State<GlassScrollToTopButton> createState() => _GlassScrollToTopButtonState();
}

class _GlassScrollToTopButtonState extends State<GlassScrollToTopButton> {
  bool _autoVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant GlassScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null || !widget.scrollController!.hasClients) return;
    final show = widget.scrollController!.offset > widget.threshold;
    if (show != _autoVisible) {
      if (mounted) {
        setState(() => _autoVisible = show);
      }
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.scrollController != null && widget.scrollController!.hasClients) {
      widget.scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool visible = widget.isVisible ?? _autoVisible;

    return Positioned(
      bottom: widget.bottom,
      left: widget.left,
      child: AnimatedScale(
        scale: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !visible,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleTap,
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.88),
                            Colors.white.withValues(alpha: 0.48),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.92),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6A00).withValues(alpha: 0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Color(0xFFFF6A00), // Vibrant Apple Orange
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
