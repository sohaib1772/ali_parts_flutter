import 'dart:ui';
import 'package:flutter/material.dart';

class AppleGlassNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;

  const AppleGlassNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class AppleGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<AppleGlassNavItem> items;

  /// Optional badge counts per tab index. `null` or 0 = no badge.
  final List<int>? badgeCounts;

  // Apple Vibrant Orange
  static const Color activeOrange = Color(0xFFFF6A00);
  static const Color inactiveColor = Color(0xFF334155);

  const AppleGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom > 0 ? 8 : 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.50),
                  Colors.white.withValues(alpha: 0.22),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.70),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Sliding Animated Glass Highlight Lens for Active Tab
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: AlignmentDirectional(
                    items.length > 1
                        ? -1.0 + (selectedIndex / (items.length - 1)) * 2.0
                        : 0.0,
                    0.0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: items.isNotEmpty ? 1.0 / items.length : 1.0,
                    heightFactor: 1.0,
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.45),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.90),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeOrange.withValues(alpha: 0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Interactive Navigation Icons with Badges
                Row(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final isActive = selectedIndex == i;
                    final badgeCount =
                        (badgeCounts != null && i < badgeCounts!.length)
                            ? badgeCounts![i]
                            : 0;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTabSelected(i),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale: isActive ? 1.10 : 0.95,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  isActive ? item.activeIcon : item.inactiveIcon,
                                  color: isActive ? activeOrange : inactiveColor,
                                  size: isActive ? 26 : 24,
                                ),
                              ),
                              // Badge
                              if (badgeCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFEAB308),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        badgeCount > 99
                                            ? '99+'
                                            : badgeCount.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
