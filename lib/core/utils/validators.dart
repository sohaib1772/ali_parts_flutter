class Validators {
  Validators._();

  /// Converts Arabic-Indic numbers to ASCII digits and strips non-digit characters
  static String normalizePhone(String phone) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const englishDigits = '0123456789';
    String result = phone;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Converts international Iraqi phone (+964... / 964... / 00964...) to local 11-digit format starting with 0 (e.g. 07734326683)
  static String formatLocalIraqiPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    String clean = normalizePhone(phone);
    if (clean.startsWith('00964')) {
      clean = '0${clean.substring(5)}';
    } else if (clean.startsWith('964')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.length == 10 && clean.startsWith('7')) {
      clean = '0$clean';
    }
    return clean;
  }

  /// Checks if the phone number is a valid 11-digit Iraqi mobile number starting with 07
  static bool isValidIraqiPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final clean = formatLocalIraqiPhone(phone);
    return clean.length == 11 && clean.startsWith('07') && RegExp(r'^07[3-9]\d{8}$').hasMatch(clean);
  }

  /// Validates Iraqi phone number and returns a human-readable Arabic error message if invalid
  static String? validateIraqiPhone(String? phone, {bool isRequired = true}) {
    if (phone == null || phone.trim().isEmpty) {
      if (isRequired) return 'رقم الهاتف مطلوب';
      return null;
    }
    final clean = formatLocalIraqiPhone(phone);
    if (!clean.startsWith('07')) {
      return 'يجب أن يبدأ رقم الهاتف بـ 07';
    }
    if (clean.length != 11) {
      return 'يجب أن يتكون رقم الهاتف من 11 رقماً (الآن: ${clean.length})';
    }
    if (!RegExp(r'^07[3-9]\d{8}$').hasMatch(clean)) {
      return 'رقم الهاتف غير صالح، يرجى التأكد من الرقم';
    }
    return null;
  }
}
