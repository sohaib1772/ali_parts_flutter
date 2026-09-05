import '../../data/models/cart_item_model.dart';

class ShippingCalculator {
  ShippingCalculator._();

  /// Calculates total shipping cost matching the website's exact algorithm:
  /// - `mergeDelivery != false`: Product joins the single merged shipment.
  ///   The delivery fee for this merged group is MAX(shippingIqd) among all merged products.
  /// - `mergeDelivery == false`: Product requires its own separate shipment.
  ///   Each unmerged product adds its own shipping fee to the total.
  static double computeShipping(List<CartItemModel> items) {
    if (items.isEmpty) return 0.0;

    final Map<String, double> groups = {};
    int anon = 0;

    for (final item in items) {
      final product = item.product;
      if (product == null) continue;

      final double rawFee = product.shippingIqd ?? 0.0;
      final double fee = rawFee > 0 ? rawFee : 0.0;
      final bool merge = product.mergeDelivery;
      final String id = product.id.isNotEmpty ? product.id : '__anon_${anon++}';

      final String key = merge ? 'g:__merged__' : 'p:$id';
      final double currentMax = groups[key] ?? 0.0;
      groups[key] = fee > currentMax ? fee : currentMax;
    }

    double totalShipping = 0.0;
    for (final fee in groups.values) {
      totalShipping += fee;
    }

    return totalShipping;
  }

  /// Calculates number of distinct shipments:
  /// - 1 shipment if there are any mergeable items
  /// - +1 for each unmergeable item
  static int shipmentCount(List<CartItemModel> items) {
    if (items.isEmpty) return 0;

    final Set<String> keys = {};
    int anon = 0;

    for (final item in items) {
      final product = item.product;
      if (product == null) continue;

      final bool merge = product.mergeDelivery;
      final String id = product.id.isNotEmpty ? product.id : '__anon_${anon++}';
      keys.add(merge ? 'g:__merged__' : 'p:$id');
    }

    return keys.length;
  }
}
