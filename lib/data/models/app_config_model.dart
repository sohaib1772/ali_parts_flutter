class AppConfigModel {
  final String appName;
  final String minSupportedVersion;
  final String latestVersion;
  final bool isUnderMaintenance;
  final String whatsappSupport;

  AppConfigModel({
    required this.appName,
    this.minSupportedVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.isUnderMaintenance = false,
    this.whatsappSupport = '+9647700000000',
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      appName: json['app_name'] as String? ?? 'Ali Parts',
      minSupportedVersion: json['min_supported_version'] as String? ?? '1.0.0',
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      isUnderMaintenance: json['is_under_maintenance'] as bool? ?? false,
      whatsappSupport: json['whatsapp_support'] as String? ?? '+9647700000000',
    );
  }

  Map<String, dynamic> toJson() => {
    'app_name': appName,
    'min_supported_version': minSupportedVersion,
    'latest_version': latestVersion,
    'is_under_maintenance': isUnderMaintenance,
    'whatsapp_support': whatsappSupport,
  };
}
