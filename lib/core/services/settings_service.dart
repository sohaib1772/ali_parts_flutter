import 'package:get/get.dart';
import '../../app/config/api_constants.dart';
import '../../data/models/app_setting_model.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

class SettingsService extends GetxService {
  final DioClient _dioClient;
  final RxMap<String, String> settings = <String, String>{}.obs;

  SettingsService(this._dioClient);

  Future<SettingsService> init() async {
    await fetchSettings();
    return this;
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.appSettings, queryParameters: {
        'select': '*',
      });
      if (response.statusCode == 200 && response.data is List) {
        for (final item in response.data) {
          final setting = AppSettingModel.fromJson(item as Map<String, dynamic>);
          settings[setting.key] = setting.value;
        }
        AppLogger.d('Loaded ${settings.length} app settings');
      }
    } catch (e) {
      AppLogger.e('Error loading app settings', e);
    }
  }

  String get storePhone => settings['store_phone'] ?? settings['whatsapp_number'] ?? '+9647855500585';
  String get whatsappNumber => settings['whatsapp_number'] ?? '+9647855500585';
  String get storeName => settings['store_name'] ?? 'مكتب علي شوفرليت';
  String get storeTagline => settings['store_tagline'] ?? 'أربيل أهلاً بكم في مكتب علي شوفرليت، GMC وكاديلاك الأصلية';
  String get storeLogo => settings['store_logo'] ?? '';
  String get storeAbout => settings['store_about'] ?? 'متجر علي لقطع غيار السيارات متخصص بتوفير قطع غيار شفروليه، جي إم سي، وكاديلاك الأصلية والمستعملة بحالة ممتازة. نوفر أسعار منافسة، جودة مضمونة، وشحن إلى جميع محافظات العراق مع خدمة عملاء سريعة وموثوق / اربيل';
  String get storeAddress => settings['store_address'] ?? 'اربيل';
  String get storeYears => settings['store_years'] ?? '7';
  String get storeFrontImage => settings['store_front_image'] ?? '';
  String get storeLocationLink => settings['store_location_link'] ?? 'https://maps.google.com/?q=Erbil';
  String get supportEmail => settings['support_email'] ?? 'aliskida816@gmail.com';
  double get usdExchangeRate => double.tryParse(settings['usd_exchange_rate'] ?? '1530') ?? 1530.0;

  // Loyalty Points Configuration
  int get pointsEarnPer1000 => int.tryParse(settings['points_earn_per_1000_iqd'] ?? '2') ?? 2;
  double get pointsRedeemIqdPerPoint {
    final val = double.tryParse(settings['points_redeem_iqd_per_point'] ?? '20');
    return (val != null && val >= 1) ? val : 20.0;
  }
  int get pointsMinRedeem => int.tryParse(settings['points_min_redeem'] ?? '100') ?? 100;
  int get pointsMaxRedeemPct {
    final val = int.tryParse(settings['points_max_redeem_pct'] ?? '100');
    return (val != null) ? val.clamp(0, 100) : 100;
  }
  String get pointsCardText => settings['points_card_text'] ?? '';

  // Force Update Configuration
  String get minAppVersionAndroid => settings['min_app_version_android'] ?? '1.0.0';
  String get minAppVersionIos => settings['min_app_version_ios'] ?? '1.0.0';
  String get forceUpdateMessage =>
      settings['force_update_message'] ??
      'يتوفر تحديث جديد ومهم للتطبيق يحتوي على تحسينات ومميزات جديدة. يرجى التحديث للمتابعة.';
  String get appStoreUrl =>
      settings['app_store_url'] ?? 'https://apps.apple.com/app/id6741753177';
  String get playStoreUrl =>
      settings['play_store_url'] ??
      'https://play.google.com/store/apps/details?id=com.mkteb.ali.chevrolet';

  /// Helper to compare two versions (e.g. "1.1.0" vs "1.2.0")
  static bool isVersionOutdated(String currentVersion, String minRequiredVersion) {
    try {
      final curParts = currentVersion.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final minParts = minRequiredVersion.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = curParts.length > minParts.length ? curParts.length : minParts.length;
      for (var i = 0; i < maxLen; i++) {
        final cur = i < curParts.length ? curParts[i] : 0;
        final req = i < minParts.length ? minParts[i] : 0;
        if (cur < req) return true;
        if (cur > req) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
