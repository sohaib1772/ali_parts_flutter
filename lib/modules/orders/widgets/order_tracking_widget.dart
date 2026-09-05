import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../../app/theme/app_colors.dart';

class OrderTrackStep {
  final String key;
  final String label;
  final IconData icon;

  const OrderTrackStep({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class OrderTrackingWidget extends StatelessWidget {
  final String status;

  static const List<OrderTrackStep> trackSteps = [
    OrderTrackStep(key: 'received', label: 'استلام', icon: IconsaxPlusBold.box_add),
    OrderTrackStep(key: 'preparing', label: 'تجهيز', icon: IconsaxPlusBold.box_time),
    OrderTrackStep(key: 'packed', label: 'تغليف', icon: IconsaxPlusBold.box_tick),
    OrderTrackStep(key: 'shipped', label: 'شحن', icon: IconsaxPlusBold.truck_fast),
    OrderTrackStep(key: 'out_for_delivery', label: 'خرج', icon: IconsaxPlusBold.routing),
    OrderTrackStep(key: 'delivered', label: 'تسليم', icon: IconsaxPlusBold.tick_circle),
  ];

  const OrderTrackingWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(IconsaxPlusBold.close_circle, size: 16, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              'تم إلغاء هذا الطلب',
              style: GoogleFonts.cairo(
                color: const Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'delivered') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(IconsaxPlusBold.tick_circle, size: 16, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(
              'تم تسليم الطلب بنجاح',
              style: GoogleFonts.cairo(
                color: const Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    int activeIdx = trackSteps.indexWhere((s) => s.key == status);
    if (activeIdx < 0) {
      if (status == 'pending') {
        activeIdx = 0;
      } else if (status == 'processing') {
        activeIdx = 1;
      } else {
        activeIdx = 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          // Horizontal Progress Bar Line precisely spanning from the center of the first icon to the center of the last icon
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final columnWidth = totalWidth / trackSteps.length;
              final halfCol = columnWidth / 2;
              final trackWidth = totalWidth - columnWidth; // Distance between first and last icon centers
              final activeWidth = activeIdx * columnWidth;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: halfCol),
                child: Container(
                  height: 5,
                  width: trackWidth,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.centerRight, // RTL: starts exactly at the rightmost icon center
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: activeWidth,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Color(0xFFE5A93C),
                          Color(0xFFFBBF24),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              );
            },
          ),

          // Step Icons & Labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(trackSteps.length, (i) {
              final step = trackSteps[i];
              final isDone = i <= activeIdx;
              final isActive = i == activeIdx;

              return Expanded(
                child: Column(
                  children: [
                    // Step Circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.gold
                            : (isDone ? const Color(0xFFFBBF24) : const Color(0xFFF1F5F9)),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          step.icon,
                          size: 14,
                          color: (isDone || isActive) ? const Color(0xFF0A192F) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Step Label in GoogleFonts.cairo
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isActive
                            ? AppColors.gold
                            : (isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
