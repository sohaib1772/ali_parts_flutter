import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class SecureStorageService extends GetxService {
  late final FlutterSecureStorage _storage;

  Future<SecureStorageService> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    return this;
  }

  Future<String?> read(String key) async {
    // 1. Try reading from FlutterSecureStorage
    try {
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) {
        // Keep durable backup synchronized
        _backupWrite(key, val);
        return val;
      }
    } catch (e) {
      debugPrint('[SecureStorage] read error for $key: $e');
    }

    // 2. Fallback to durable GetStorage backup (preserves session across updates & Keystore glitches)
    final backupVal = _backupRead(key);
    if (backupVal != null && backupVal.isNotEmpty) {
      debugPrint('[SecureStorage] recovered $key from durable backup');
      // Attempt to re-heal secure storage
      try {
        await _storage.write(key: key, value: backupVal);
      } catch (_) {}
      return backupVal;
    }

    return null;
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorage] write error for $key: $e');
    }
    // Always persist to durable backup
    _backupWrite(key, value);
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] delete error for $key: $e');
    }
    _backupDelete(key);
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage] deleteAll error: $e');
    }
    _backupDeleteAll();
  }

  void _backupWrite(String key, String value) {
    try {
      if (Get.isRegistered<StorageService>()) {
        Get.find<StorageService>().write('sec_bk_$key', value);
      }
    } catch (_) {}
  }

  String? _backupRead(String key) {
    try {
      if (Get.isRegistered<StorageService>()) {
        return Get.find<StorageService>().read<String>('sec_bk_$key');
      }
    } catch (_) {}
    return null;
  }

  void _backupDelete(String key) {
    try {
      if (Get.isRegistered<StorageService>()) {
        Get.find<StorageService>().remove('sec_bk_$key');
      }
    } catch (_) {}
  }

  void _backupDeleteAll() {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        storage.remove('sec_bk_access_token');
        storage.remove('sec_bk_refresh_token');
        storage.remove('sec_bk_user_id');
        storage.remove('sec_bk_admin_device_id');
      }
    } catch (_) {}
  }
}
