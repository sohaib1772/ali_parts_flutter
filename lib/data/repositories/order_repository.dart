import '../../app/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DioClient _dioClient;

  OrderRepository(this._dioClient);

  /// Places order through Supabase RPC place_order
  Future<String?> placeOrder({
    required Map<String, dynamic> address,
    required String paymentMethod,
    int pointsUsed = 0,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/rest/v1/rpc/place_order',
        data: {
          'p_address': {
            'label': address['label'] ?? 'عنوان',
            'full_name': address['full_name'],
            'phone': address['phone'],
            'city': address['city'],
            'area': address['area'],
            'street': address['street'] ?? '',
            'notes': address['notes'] ?? '',
          },
          'p_payment': paymentMethod,
          'p_points_used': pointsUsed,
          'p_notes': notes ?? '',
        },
      );

      AppLogger.d('place_order response: ${response.statusCode} data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is String) return response.data as String;
        if (response.data is Map && response.data['id'] != null) return response.data['id'].toString();
        return response.data?.toString();
      }
    } catch (e) {
      AppLogger.e('Error in place_order RPC', e);
      rethrow;
    }
    return null;
  }

  /// Fetches orders for authenticated user
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
      if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
        return (response.data as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('Error fetching user orders', e);
    }
    return [];
  }

  /// Fetches single order by ID with order_items
  Future<OrderModel?> fetchOrderById(String orderId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.orders,
        queryParameters: {
          'select': '*,order_items(*)',
          'id': 'eq.$orderId',
          'limit': 1,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 206) &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        return OrderModel.fromJson((response.data as List).first as Map<String, dynamic>);
      }
    } catch (e) {
      AppLogger.e('Error fetching order by ID: $orderId', e);
    }
    return null;
  }

  /// Cancel order through Supabase RPC cancel_my_order
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await _dioClient.dio.post(
        '/rest/v1/rpc/cancel_my_order',
        data: {
          'p_order_id': orderId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.e('Error cancelling order', e);
      return false;
    }
  }
}
