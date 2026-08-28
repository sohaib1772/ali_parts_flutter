import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';

class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index == 3) {
      // Tab 3 is Messages / WhatsApp
      _openWhatsAppSupport();
      return;
    }
    currentIndex.value = index;
  }

  Future<void> _openWhatsAppSupport() async {
    final settings = Get.find<SettingsService>();
    final url = Formatters.generateWhatsAppUrl(
      phone: settings.whatsappNumber,
      message: 'مرحباً، أحتاج مساعدة واستفسار من الدعم الفني لمكتب علي شوفرليت.',
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
