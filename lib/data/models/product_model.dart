class ProductModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? oemNumber;
  final double priceIqd;
  final double priceUsd;
  final double? comparePriceIqd;
  final double? shippingIqd;
  final String? categoryId;
  final String? brandId;
  final List<String> compatibleModels;
  final List<String> images;
  final bool inStock;
  final int stockQty;
  final bool isFeatured;
  final bool isDeal;
  final String? dealExpiresAt;
  final int salesCount;
  final String condition; // 'new' | 'used'
  final String? createdAt;

  ProductModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.oemNumber,
    required this.priceIqd,
    this.priceUsd = 0,
    this.comparePriceIqd,
    this.shippingIqd,
    this.categoryId,
    this.brandId,
    this.compatibleModels = const [],
    this.images = const [],
    this.inStock = true,
    this.stockQty = 0,
    this.isFeatured = false,
    this.isDeal = false,
    this.dealExpiresAt,
    this.salesCount = 0,
    this.condition = 'new',
    this.createdAt,
  });

  bool get isAvailable => inStock && stockQty > 0;
  bool get isUsed => condition == 'used';
  bool get hasDiscount => comparePriceIqd != null && comparePriceIqd! > priceIqd;

  int get discountPercentage {
    if (!hasDiscount || comparePriceIqd! <= 0) return 0;
    return (((comparePriceIqd! - priceIqd) / comparePriceIqd!) * 100).round();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProductModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      oemNumber: json['oem_number'] as String?,
      priceIqd: (json['price_iqd'] as num?)?.toDouble() ?? 0.0,
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0.0,
      comparePriceIqd: (json['compare_price_iqd'] as num?)?.toDouble(),
      shippingIqd: (json['shipping_iqd'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      brandId: json['brand_id'] as String?,
      compatibleModels: parseStringList(json['compatible_models']),
      images: parseStringList(json['images']),
      inStock: json['in_stock'] as bool? ?? true,
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isDeal: json['is_deal'] as bool? ?? false,
      dealExpiresAt: json['deal_expires_at'] as String?,
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? 'new',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'description_ar': descriptionAr,
    'oem_number': oemNumber,
    'price_iqd': priceIqd,
    'price_usd': priceUsd,
    'compare_price_iqd': comparePriceIqd,
    'shipping_iqd': shippingIqd,
    'category_id': categoryId,
    'brand_id': brandId,
    'compatible_models': compatibleModels,
    'images': images,
    'in_stock': inStock,
    'stock_qty': stockQty,
    'is_featured': isFeatured,
    'is_deal': isDeal,
    'deal_expires_at': dealExpiresAt,
    'sales_count': salesCount,
    'condition': condition,
    'created_at': createdAt,
  };
}
