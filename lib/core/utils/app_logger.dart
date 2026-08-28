import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void d(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'AliParts');
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      dev.log('❌ $message', name: 'AliParts', error: error, stackTrace: stackTrace);
    }
  }
}
