import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatIQD(dynamic amount) {
    if (amount == null) return '0 د.ع';
    final num numAmount = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final formatter = NumberFormat('#,###', 'en_US');
    return '${formatter.format(numAmount)} د.ع';
  }

  static String formatNumber(dynamic number) {
    if (number == null) return '0';
    final num numVal = number is num ? number : (num.tryParse(number.toString()) ?? 0);
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(numVal);
  }

  static String thumbUrl(String? originalUrl, {int width = 400, int quality = 70}) {
    if (originalUrl == null || originalUrl.isEmpty) return '';
    if (originalUrl.contains('api.maktabali.com') && originalUrl.contains('/storage/v1/object/public/')) {
      return '$originalUrl?width=$width&quality=$quality';
    }
    return originalUrl;
  }

  static String generateWhatsAppUrl({
    required String phone,
    String? productName,
    String? productUrl,
    String? oemNumber,
    String? message,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    String finalMsg = message ?? 'السلام عليكم، استفسار بخصوص قطع غيار:';
    if (productName != null) {
      finalMsg += '\n- القطعة: $productName';
    }
    if (oemNumber != null && oemNumber.isNotEmpty) {
      finalMsg += '\n- رقم OEM: $oemNumber';
    }
    if (productUrl != null && productUrl.isNotEmpty) {
      finalMsg += '\n- الرابط: $productUrl';
    }
    return 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(finalMsg)}';
  }
}
