class AppSettingModel {
  final String key;
  final String value;
  final String? updatedAt;

  AppSettingModel({
    required this.key,
    required this.value,
    this.updatedAt,
  });

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      key: json['key'] as String,
      value: json['value'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }
}
