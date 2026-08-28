import 'package:dio/dio.dart';
import '../../app/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DioClient _dioClient;

  OrderRepository(this._dioClient);

  Future<List<AddressModel>> fetchAddresses(String userId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.addresses,
        queryParameters: {
          'select': '*',
          'user_id': 'eq.$userId',
          'order': 'is_default.desc,created_at.desc',
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<AddressModel?> addAddress(AddressModel address) async {
    final response = await _dioClient.dio.post(
      ApiConstants.addresses,
      data: address.toJson(),
      options: Options(headers: {'Prefer': 'return=representation'}),
    );
    if (response.statusCode == 201 && response.data is List && (response.data as List).isNotEmpty) {
      return AddressModel.fromJson((response.data as List).first as Map<String, dynamic>);
    }
    return null;
  }

  Future<OrderModel?> createOrder({
    required String userId,
    required double totalIqd,
    required double deliveryFeeIqd,
    required Map<String, dynamic> shippingAddress,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderResponse = await _dioClient.dio.post(
      ApiConstants.orders,
      data: {
        'user_id': userId,
        'status': 'pending',
        'total_iqd': totalIqd,
        'delivery_fee_iqd': deliveryFeeIqd,
        'shipping_address': shippingAddress,
        'notes': notes,
      },
      options: Options(headers: {'Prefer': 'return=representation'}),
    );

    if (orderResponse.statusCode == 201 && orderResponse.data is List && (orderResponse.data as List).isNotEmpty) {
      final orderData = (orderResponse.data as List).first as Map<String, dynamic>;
      final orderId = orderData['id'] as String;

      final itemsToInsert = items.map((item) => {
        'order_id': orderId,
        'product_id': item['product_id'],
        'product_name_ar': item['name_ar'],
        'quantity': item['quantity'],
        'unit_price_iqd': item['price_iqd'],
        'side': item['side'],
      }).toList();

      await _dioClient.dio.post(
        ApiConstants.orderItems,
        data: itemsToInsert,
      );

      return OrderModel.fromJson(orderData);
    }
    return null;
  }

  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.orders,
        queryParameters: {
          'select': '*,order_items(*)',
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
