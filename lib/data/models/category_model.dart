class CategoryModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? icon;
  final String? imageUrl;
  final int? sortOrder;

  CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.icon,
    this.imageUrl,
    this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'icon': icon,
    'image_url': imageUrl,
    'sort_order': sortOrder,
  };
}
