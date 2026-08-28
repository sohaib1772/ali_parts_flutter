class BrandModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? logoUrl;

  BrandModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.logoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'logo_url': logoUrl,
  };
}
