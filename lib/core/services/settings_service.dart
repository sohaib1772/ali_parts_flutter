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
}
