import 'product_model.dart';

class CartItemModel {
  final String id;
  final String? userId;
  final String productId;
  final int quantity;
  final String? side; // 'LH' | 'RH' | 'PAIR' | null
  final String? note;
  final ProductModel? product;

  CartItemModel({
    required this.id,
    this.userId,
    required this.productId,
    this.quantity = 1,
    this.side,
    this.note,
    this.product,
  });

  // Pair (تخم) costs 2x the single unit price only if product supports side options
  double get unitPrice => (side == 'PAIR' && (product?.hasSideOptions ?? true))
      ? ((product?.priceIqd ?? 0.0) * 2)
      : (product?.priceIqd ?? 0.0);
  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    String? side,
    String? note,
    ProductModel? product,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      side: side ?? this.side,
      note: note ?? this.note,
      product: product ?? this.product,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      productId: json['product_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      side: json['side'] as String?,
      note: json['note'] as String?,
      product: json['products'] != null ? ProductModel.fromJson(json['products'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'quantity': quantity,
    'side': side,
    'note': note,
  };
}
