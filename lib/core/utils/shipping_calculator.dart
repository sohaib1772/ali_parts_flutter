import 'dart:math' as math;
import '../../data/models/cart_item_model.dart';

enum ShippingGroup { small, medium, large }

class ShippingCalculator {
  ShippingCalculator._();

  static ShippingGroup? normalizeDeliveryGroup(String? group) {
    if (group != null) {
      final g = group.toLowerCase().trim();
      if (g.isEmpty) return null;
      if (g.contains('large') || g.contains('كبير')) return ShippingGroup.large;
      if (g.contains('medium') || g.contains('متوسط')) return ShippingGroup.medium;
      if (g.contains('small') || g.contains('صغير')) return ShippingGroup.small;
    }
    return null;
  }

  static List<ShippingGroup> normalizeMergeWithGroups(
    List<String>? rawGroups,
    ShippingGroup? fallbackGroup,
    bool mergeDelivery,
  ) {
    if (fallbackGroup == null) return []; // Product without a delivery group is always independent

    if (rawGroups != null && rawGroups.isNotEmpty) {
      final List<ShippingGroup> list = [];
      for (final g in rawGroups) {
        final norm = normalizeDeliveryGroup(g);
        if (norm != null && !list.contains(norm)) list.add(norm);
      }
      return list;
    }

    if (mergeDelivery) {
      if (fallbackGroup == ShippingGroup.large) return [];
      if (fallbackGroup == ShippingGroup.medium) return [ShippingGroup.medium, ShippingGroup.large];
      return [ShippingGroup.small, ShippingGroup.medium, ShippingGroup.large];
    }

    return [];
  }

  static ({double shipping, int shipments}) evaluateShipping(List<CartItemModel> items) {
    if (items.isEmpty) return (shipping: 0.0, shipments: 0);

    final List<_ParsedShippingItem> parsed = [];

    for (final item in items) {
      final product = item.product;
      if (product == null) continue;

      final double rawFee = product.shippingIqd ?? 0.0;
      final double fee = rawFee > 0 ? rawFee : 0.0;
      final int qty = item.quantity > 0 ? item.quantity : 1;
      final ShippingGroup? group = normalizeDeliveryGroup(product.deliveryGroup);
      final bool mergeBool = product.mergeDelivery;
      final List<ShippingGroup> mergeWith = normalizeMergeWithGroups(
        product.mergeWithGroups,
        group,
        mergeBool,
      );
      final bool canMerge = group != null && mergeBool && mergeWith.isNotEmpty;
      final int? maxMergeQty = (product.maxMergeQty != null && product.maxMergeQty! > 0)
          ? product.maxMergeQty
          : null;

      parsed.add(_ParsedShippingItem(
        fee: fee,
        qty: qty,
        group: group,
        mergeWith: mergeWith,
        canMerge: canMerge,
        maxMergeQty: maxMergeQty,
      ));
    }

    if (parsed.isEmpty) return (shipping: 0.0, shipments: 0);

    // 1. Large items
    final List<_Unit> mergeableLargeUnits = [];
    double largeIndependentShipping = 0.0;
    int largeIndependentCount = 0;

    for (final it in parsed) {
      if (it.group == ShippingGroup.large) {
        if (it.canMerge && it.mergeWith.contains(ShippingGroup.large)) {
          final int cap = it.maxMergeQty ?? 999999;
          for (int k = 0; k < it.qty; k++) {
            mergeableLargeUnits.add(_Unit(fee: it.fee, maxQty: cap));
          }
        } else if (it.maxMergeQty != null && it.maxMergeQty! > 1) {
          final int parcels = (it.qty / it.maxMergeQty!).ceil();
          largeIndependentShipping += it.fee * parcels;
          largeIndependentCount += parcels;
        } else {
          largeIndependentShipping += it.fee * it.qty;
          largeIndependentCount += it.qty;
        }
      }
    }

    final largeMergedPack = _packParcels(mergeableLargeUnits);
    final double largeShipping = largeMergedPack.fee + largeIndependentShipping;
    final int totalLargeParcels = largeMergedPack.count + largeIndependentCount;

    // 2. Non-large items absorbing into large
    final List<_ParsedShippingItem> nonLarge =
        parsed.where((it) => it.group != ShippingGroup.large).toList();
    final List<_ParsedShippingItem> afterLargeAbsorption = [];

    for (final it in nonLarge) {
      if (totalLargeParcels > 0 && it.canMerge && it.mergeWith.contains(ShippingGroup.large)) {
        final int maxAbsorbable =
            it.maxMergeQty != null ? totalLargeParcels * it.maxMergeQty! : 999999;
        final int absorbedQty = math.min(it.qty, maxAbsorbable);
        final int remainingQty = it.qty - absorbedQty;
        if (remainingQty > 0) {
          afterLargeAbsorption.add(it.copyWith(qty: remainingQty));
        }
      } else {
        afterLargeAbsorption.add(it);
      }
    }

    // 3. Medium items
    final List<_Unit> mergeableMediumUnits = [];
    double mediumIndependentShipping = 0.0;
    int mediumIndependentCount = 0;
    final List<_ParsedShippingItem> nonMediumItems = [];

    for (final it in afterLargeAbsorption) {
      if (it.group == ShippingGroup.medium) {
        if (it.canMerge && it.mergeWith.contains(ShippingGroup.medium)) {
          final int cap = it.maxMergeQty ?? 999999;
          for (int k = 0; k < it.qty; k++) {
            mergeableMediumUnits.add(_Unit(fee: it.fee, maxQty: cap));
          }
        } else if (it.maxMergeQty != null && it.maxMergeQty! > 1) {
          final int parcels = (it.qty / it.maxMergeQty!).ceil();
          mediumIndependentShipping += it.fee * parcels;
          mediumIndependentCount += parcels;
        } else {
          mediumIndependentShipping += it.fee * it.qty;
          mediumIndependentCount += it.qty;
        }
      } else {
        nonMediumItems.pushOrAdd(it);
      }
    }

    final mediumMergedPack = _packParcels(mergeableMediumUnits);
    final double mediumShipping = mediumMergedPack.fee + mediumIndependentShipping;
    final int totalMediumParcels = mediumMergedPack.count + mediumIndependentCount;

    // Absorption of small items into medium shipments
    final List<_ParsedShippingItem> afterMediumAbsorption = [];
    for (final it in nonMediumItems) {
      if (mediumMergedPack.count > 0 && it.canMerge && it.mergeWith.contains(ShippingGroup.medium)) {
        final int maxAbsorbable =
            it.maxMergeQty != null ? mediumMergedPack.count * it.maxMergeQty! : 999999;
        final int absorbedQty = math.min(it.qty, maxAbsorbable);
        final int remainingQty = it.qty - absorbedQty;
        if (remainingQty > 0) {
          afterMediumAbsorption.add(it.copyWith(qty: remainingQty));
        }
      } else {
        afterMediumAbsorption.add(it);
      }
    }

    // 4. Small items
    final List<_Unit> mergeableSmallUnits = [];
    double unmergedShipping = 0.0;
    int unmergedCount = 0;

    for (final it in afterMediumAbsorption) {
      if (it.group == ShippingGroup.small) {
        if (it.canMerge && it.mergeWith.contains(ShippingGroup.small)) {
          final int cap = it.maxMergeQty ?? 999999;
          for (int k = 0; k < it.qty; k++) {
            mergeableSmallUnits.add(_Unit(fee: it.fee, maxQty: cap));
          }
        } else if (it.maxMergeQty != null && it.maxMergeQty! > 1) {
          final int parcels = (it.qty / it.maxMergeQty!).ceil();
          unmergedShipping += it.fee * parcels;
          unmergedCount += parcels;
        } else {
          unmergedShipping += it.fee * it.qty;
          unmergedCount += it.qty;
        }
      } else {
        // Items without group or unmerged items:
        if (it.maxMergeQty != null && it.maxMergeQty! > 1) {
          final int parcels = (it.qty / it.maxMergeQty!).ceil();
          unmergedShipping += it.fee * parcels;
          unmergedCount += parcels;
        } else {
          unmergedShipping += it.fee * it.qty;
          unmergedCount += it.qty;
        }
      }
    }

    final smallPack = _packParcels(mergeableSmallUnits);

    final double totalShipping =
        largeShipping + mediumShipping + smallPack.fee + unmergedShipping;
    final int totalShipments =
        totalLargeParcels + totalMediumParcels + smallPack.count + unmergedCount;

    return (shipping: totalShipping, shipments: totalShipments);
  }

  /// Calculates total shipping cost matching the website & DB algorithm
  static double computeShipping(List<CartItemModel> items) {
    return evaluateShipping(items).shipping;
  }

  /// Calculates number of distinct shipments
  static int shipmentCount(List<CartItemModel> items) {
    return evaluateShipping(items).shipments;
  }

  static ({double fee, int count}) _packParcels(List<_Unit> units) {
    if (units.isEmpty) return (fee: 0.0, count: 0);

    // Sort descending by fee
    final sorted = List<_Unit>.from(units)..sort((a, b) => b.fee.compareTo(a.fee));
    final List<_Parcel> parcels = [];

    for (final unit in sorted) {
      bool placed = false;
      for (final p in parcels) {
        if (p.count < p.capacity && p.count < unit.maxQty) {
          p.count += 1;
          p.capacity = math.min(p.capacity, unit.maxQty);
          p.maxFee = math.max(p.maxFee, unit.fee);
          placed = true;
          break;
        }
      }
      if (!placed) {
        parcels.add(_Parcel(
          maxFee: unit.fee,
          capacity: unit.maxQty,
          count: 1,
        ));
      }
    }

    final double totalFee = parcels.fold(0.0, (sum, p) => sum + p.maxFee);
    return (fee: totalFee, count: parcels.length);
  }
}

class _Unit {
  final double fee;
  final int maxQty;

  _Unit({required this.fee, required this.maxQty});
}

class _Parcel {
  double maxFee;
  int capacity;
  int count;

  _Parcel({required this.maxFee, required this.capacity, required this.count});
}

class _ParsedShippingItem {
  final double fee;
  final int qty;
  final ShippingGroup? group;
  final List<ShippingGroup> mergeWith;
  final bool canMerge;
  final int? maxMergeQty;

  _ParsedShippingItem({
    required this.fee,
    required this.qty,
    required this.group,
    required this.mergeWith,
    required this.canMerge,
    this.maxMergeQty,
  });

  _ParsedShippingItem copyWith({int? qty}) {
    return _ParsedShippingItem(
      fee: fee,
      qty: qty ?? this.qty,
      group: group,
      mergeWith: mergeWith,
      canMerge: canMerge,
      maxMergeQty: maxMergeQty,
    );
  }
}

extension on List<_ParsedShippingItem> {
  void pushOrAdd(_ParsedShippingItem it) => add(it);
}
