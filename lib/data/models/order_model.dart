class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final String status; // 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  final double totalIqd;
  final double subtotalIqd;
  final double deliveryFeeIqd;
  final String paymentMethod;
  final String? notes;
  final Map<String, dynamic>? shippingAddress;
  final String? createdAt;
  final String? updatedAt;
  final int pointsEarned;
  final int pointsUsed;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    this.status = 'pending',
    required this.totalIqd,
    this.subtotalIqd = 0.0,
    this.deliveryFeeIqd = 0.0,
    this.paymentMethod = 'cod',
    this.notes,
    this.shippingAddress,
    this.createdAt,
    this.updatedAt,
    this.pointsEarned = 0,
    this.pointsUsed = 0,
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

    final addr = json['address'] is Map
        ? json['address'] as Map<String, dynamic>
        : (json['shipping_address'] is Map ? json['shipping_address'] as Map<String, dynamic> : null);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? (json['id'] != null ? json['id'].toString().substring(0, 8) : 'ORD'),
      status: json['status']?.toString() ?? 'pending',
      totalIqd: (json['total_iqd'] as num?)?.toDouble() ?? 0.0,
      subtotalIqd: (json['subtotal_iqd'] as num?)?.toDouble() ?? 0.0,
      deliveryFeeIqd: (json['shipping_iqd'] as num?)?.toDouble() ?? (json['delivery_fee_iqd'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      notes: json['notes'] as String?,
      shippingAddress: addr,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      pointsUsed: (json['points_used'] as num?)?.toInt() ?? 0,
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
  final String? oemNumber;

  OrderItemModel({
    required this.id,
    this.orderId,
    this.productId,
    required this.productNameAr,
    required this.quantity,
    required this.unitPriceIqd,
    this.side,
    this.imageUrl,
    this.oemNumber,
  });

  double get totalPrice => unitPriceIqd * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      productId: json['product_id']?.toString(),
      productNameAr: json['name_ar'] as String? ?? json['product_name_ar'] as String? ?? 'قطعة غيار',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceIqd: (json['unit_price_iqd'] as num?)?.toDouble() ?? 0.0,
      side: json['side'] as String?,
      imageUrl: json['image_url'] as String?,
      oemNumber: json['oem_number'] as String?,
    );
  }
}
