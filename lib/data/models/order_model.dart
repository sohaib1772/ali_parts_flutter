class OrderModel {
  final String id;
  final String userId;
  final String status; // 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  final double totalIqd;
  final double deliveryFeeIqd;
  final String? notes;
  final Map<String, dynamic>? shippingAddress;
  final String? createdAt;
  final int pointsEarned;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    this.status = 'pending',
    required this.totalIqd,
    this.deliveryFeeIqd = 0.0,
    this.notes,
    this.shippingAddress,
    this.createdAt,
    this.pointsEarned = 0,
    this.items = const [],
  });

  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'processing':
        return 'جاري التجهيز';
      case 'shipped':
        return 'جاري التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parseItems(dynamic list) {
      if (list is List) {
        return list.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      totalIqd: (json['total_iqd'] as num?)?.toDouble() ?? 0.0,
      deliveryFeeIqd: (json['delivery_fee_iqd'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      items: parseItems(json['order_items']),
    );
  }
}

class OrderItemModel {
  final String id;
  final String? orderId;
  final String? productId;
  final String productNameAr;
  final int quantity;
  final double unitPriceIqd;
  final String? side;
  final String? imageUrl;

  OrderItemModel({
    required this.id,
    this.orderId,
    this.productId,
    required this.productNameAr,
    required this.quantity,
    required this.unitPriceIqd,
    this.side,
    this.imageUrl,
  });

  double get totalPrice => unitPriceIqd * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      productId: json['product_id'] as String?,
      productNameAr: json['product_name_ar'] as String? ?? json['name_ar'] as String? ?? 'قطعة غيار',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceIqd: (json['unit_price_iqd'] as num?)?.toDouble() ?? 0.0,
      side: json['side'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
