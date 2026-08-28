import 'package:get/get.dart';
import 'ar_iq.dart';
import 'en_us.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar_IQ': arIQ,
    'en_US': enUS,
  };
}
