class CarModelModel {
  final String id;
  final String? brandId;
  final String nameAr;
  final String? nameEn;
  final String? imageUrl;

  CarModelModel({
    required this.id,
    this.brandId,
    required this.nameAr,
    this.nameEn,
    this.imageUrl,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'] as String,
      brandId: json['brand_id'] as String?,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand_id': brandId,
    'name_ar': nameAr,
    'name_en': nameEn,
    'image_url': imageUrl,
  };
}
