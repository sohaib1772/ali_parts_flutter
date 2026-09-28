import 'package:flutter_test/flutter_test.dart';
import 'package:ali_parts_app/core/utils/shipping_calculator.dart';
import 'package:ali_parts_app/data/models/cart_item_model.dart';
import 'package:ali_parts_app/data/models/product_model.dart';

void main() {
  CartItemModel makeItem({
    required String id,
    required double fee,
    int qty = 1,
    String? group,
    List<String> mergeWith = const [],
    int? maxMerge,
    bool merge = true,
  }) {
    final product = ProductModel(
      id: id,
      nameAr: 'منتج $id',
      priceIqd: 10000,
      shippingIqd: fee,
      deliveryGroup: group,
      mergeWithGroups: mergeWith,
      maxMergeQty: maxMerge,
      mergeDelivery: merge,
    );
    return CartItemModel(
      id: 'cart_$id',
      userId: 'user_1',
      productId: id,
      quantity: qty,
      product: product,
    );
  }

  group('ShippingCalculator real-world car parts delivery rules', () {
    test('returns 0 for empty list', () {
      expect(ShippingCalculator.computeShipping([]), 0.0);
      expect(ShippingCalculator.shipmentCount([]), 0);
    });

    test('فلتر شوته + فلتر تبريد + درايم شفت = توصيل واحد (6000 د.ع)', () {
      final items = [
        makeItem(id: 'filter_shoteh', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
        makeItem(id: 'filter_tabreed', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
        makeItem(id: 'draim_shaft', fee: 6000, group: 'small', mergeWith: ['small']),
      ];
      expect(ShippingCalculator.computeShipping(items), 6000.0);
      expect(ShippingCalculator.shipmentCount(items), 1);
    });

    test('دعامية (35 ألف) + فلتر شوته + فلتر تبريد + درايم شفت = 41 ألف (الفلاتر تلتصق بالدعامية والدرايم شفت منفصل)', () {
      final items = [
        makeItem(id: 'bumper', fee: 35000, group: 'large', mergeWith: ['large']),
        makeItem(id: 'filter_shoteh', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
        makeItem(id: 'filter_tabreed', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
        makeItem(id: 'draim_shaft', fee: 6000, group: 'small', mergeWith: ['small']),
      ];
      // 35,000 (دعامية وفلاتر) + 6,000 (درايم شفت) = 41,000
      expect(ShippingCalculator.computeShipping(items), 41000.0);
      expect(ShippingCalculator.shipmentCount(items), 2);
    });

    test('دعامية (35 ألف) + فلتر شوته وفلتر تبريد بدون درايم شفت = 35 ألف فقط', () {
      final items = [
        makeItem(id: 'bumper', fee: 35000, group: 'large', mergeWith: ['large']),
        makeItem(id: 'filter_shoteh', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
        makeItem(id: 'filter_tabreed', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
      ];
      expect(ShippingCalculator.computeShipping(items), 35000.0);
      expect(ShippingCalculator.shipmentCount(items), 1);
    });

    test('دعاميات 2 يمكن لصقهن بشريط لاصق = توصيل واحد (35 ألف)', () {
      final items = [
        makeItem(id: 'bumper_front', fee: 35000, group: 'large', mergeWith: ['large']),
        makeItem(id: 'bumper_rear', fee: 35000, group: 'large', mergeWith: ['large']),
      ];
      expect(ShippingCalculator.computeShipping(items), 35000.0);
      expect(ShippingCalculator.shipmentCount(items), 1);
    });

    test('بيبان 2 لا يمكن لصقهن معاً = توصيلين (35 + 35 = 70 ألف)', () {
      final items = [
        makeItem(id: 'door_lh', fee: 35000, group: 'large', mergeWith: []), // لا يندمج مع كبير آخر
        makeItem(id: 'door_rh', fee: 35000, group: 'large', mergeWith: []), // لا يندمج مع كبير آخر
      ];
      expect(ShippingCalculator.computeShipping(items), 70000.0);
      expect(ShippingCalculator.shipmentCount(items), 2);
    });

    test('بابين + فلتر شوتة = 70 ألف (الفلتر يلتصق بأحد البيبان دون كلفة إضافية)', () {
      final items = [
        makeItem(id: 'door_lh', fee: 35000, group: 'large', mergeWith: []),
        makeItem(id: 'door_rh', fee: 35000, group: 'large', mergeWith: []),
        makeItem(id: 'filter_shoteh', fee: 6000, group: 'small', mergeWith: ['small', 'large']),
      ];
      expect(ShippingCalculator.computeShipping(items), 70000.0);
      expect(ShippingCalculator.shipmentCount(items), 2);
    });

    test('منتج بدون تحديد مجموعة = توصيل مستقل دائماً', () {
      final items = [
        makeItem(id: 'bumper', fee: 35000, group: 'large', mergeWith: ['large']),
        makeItem(id: 'independent_item', fee: 10000, group: null),
      ];
      expect(ShippingCalculator.computeShipping(items), 45000.0);
      expect(ShippingCalculator.shipmentCount(items), 2);
    });

    test('دعامية مع حد أقصى للدمج = 2: 1=35k, 2=35k, 3=70k, 4=70k, 5=105k', () {
      CartItemModel makeBumper(int qty) =>
          makeItem(id: 'b', fee: 35000, qty: qty, group: 'large', mergeWith: ['large'], maxMerge: 2);

      expect(ShippingCalculator.computeShipping([makeBumper(1)]), 35000.0);
      expect(ShippingCalculator.shipmentCount([makeBumper(1)]), 1);

      expect(ShippingCalculator.computeShipping([makeBumper(2)]), 35000.0);
      expect(ShippingCalculator.shipmentCount([makeBumper(2)]), 1);

      expect(ShippingCalculator.computeShipping([makeBumper(3)]), 70000.0);
      expect(ShippingCalculator.shipmentCount([makeBumper(3)]), 2);

      expect(ShippingCalculator.computeShipping([makeBumper(4)]), 70000.0);
      expect(ShippingCalculator.shipmentCount([makeBumper(4)]), 2);

      expect(ShippingCalculator.computeShipping([makeBumper(5)]), 105000.0);
      expect(ShippingCalculator.shipmentCount([makeBumper(5)]), 3);
    });

    test('دعامية أمامية 40k (max 2) + دعاميتين خلفيات 35k (max 2) = 75k في طردين', () {
      final items = [
        makeItem(id: 'bf', fee: 40000, qty: 1, group: 'large', mergeWith: ['large'], maxMerge: 2),
        makeItem(id: 'br', fee: 35000, qty: 2, group: 'large', mergeWith: ['large'], maxMerge: 2),
      ];
      expect(ShippingCalculator.computeShipping(items), 75000.0);
      expect(ShippingCalculator.shipmentCount(items), 2);
    });
  });
}
