import 'package:flutter/widgets.dart';

/// Helper to provide responsive grid layouts (crossAxisCount and childAspectRatio)
/// for product and category grids across phones, iPads, tablets, and desktops.
class ResponsiveGridHelper {
  ResponsiveGridHelper._();

  /// Product Grid Delegate
  /// - Phone (< 600px): 2 columns, ratio 0.58
  /// - iPad / Small Tablet (600px - 899px): 3 columns, ratio 0.62
  /// - iPad Landscape / Medium Screen (900px - 1199px): 4 columns, ratio 0.65
  /// - Large Screen (>= 1200px): 5 columns, ratio 0.68
  static SliverGridDelegateWithFixedCrossAxisCount getProductGridDelegate(
    BuildContext context, {
    double spacing = 12,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final int count;
    final double ratio;

    if (width >= 1200) {
      count = 5;
      ratio = 0.68;
    } else if (width >= 900) {
      count = 4;
      ratio = 0.65;
    } else if (width >= 600) {
      count = 3;
      ratio = 0.62;
    } else {
      count = 2;
      ratio = 0.58;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: ratio,
    );
  }

  /// Category Grid Delegate
  /// - Phone (< 600px): 3 columns, ratio 0.72
  /// - iPad / Small Tablet (600px - 899px): 4 columns, ratio 0.78
  /// - iPad Landscape / Medium Screen (900px - 1199px): 6 columns, ratio 0.82
  /// - Large Screen (>= 1200px): 8 columns, ratio 0.85
  static SliverGridDelegateWithFixedCrossAxisCount getCategoryGridDelegate(
    BuildContext context, {
    double spacing = 10,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final int count;
    final double ratio;

    if (width >= 1200) {
      count = 8;
      ratio = 0.85;
    } else if (width >= 900) {
      count = 6;
      ratio = 0.82;
    } else if (width >= 600) {
      count = 4;
      ratio = 0.78;
    } else {
      count = 3;
      ratio = 0.72;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: ratio,
    );
  }
}
