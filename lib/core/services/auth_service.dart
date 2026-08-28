import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:get/get.dart';
import '../../app/config/api_constants.dart';
import '../../app/config/app_constants.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../utils/app_logger.dart';
import 'cart_service.dart';
import 'favorites_service.dart';
import 'secure_storage_service.dart';

class AuthService extends GetxService {
  late final SecureStorageService _secureStorage;
  late final Dio _authDio;
  late final AppLinks _appLinks;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxString userEmail = ''.obs;
  final RxString userName = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userAvatar = ''.obs;
  final RxInt pointsBalance = 0.obs;
  final RxBool isAdmin = false.obs;

  StreamSubscription<Uri>? _linkSubscription;
  Completer<Map<String, dynamic>>? _authCompleter;
  String? _currentCodeVerifier;

  static const String redirectUrl = 'com.mkteb.ali.chevrolet://auth';

  Future<AuthService> init() async {
    _secureStorage = Get.find<SecureStorageService>();
    _appLinks = AppLinks();
    _authDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'apikey': ApiConstants.anonKey,
      },
    ));

    _initDeepLinks();
    await _restoreSession();
    return this;
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        AppLogger.d('Received incoming deep link: $uri');
        _handleIncomingRedirect(uri);
      },
      onError: (err) {
        AppLogger.e('Error on deep link stream', err);
      },
    );
  }

  void _handleIncomingRedirect(Uri uri) async {
    if (uri.scheme != 'com.mkteb.ali.chevrolet' || uri.host != 'auth') {
      return;
    }

    try {
      await closeCustomTabs();
    } catch (_) {}

    try {
      final errorDesc = uri.queryParameters['error_description'] ??
          _extractFromFragment(uri.fragment, 'error_description');
      final error = uri.queryParameters['error'] ??
          _extractFromFragment(uri.fragment, 'error');

      if (errorDesc != null || error != null) {
        _authCompleter?.complete({
          'status': 'error',
          'message': errorDesc ?? error ?? 'تم إلغاء تسجيل الدخول',
        });
        _authCompleter = null;
        return;
      }

      final accessToken = _extractFromFragment(uri.fragment, 'access_token');
      final refreshToken = _extractFromFragment(uri.fragment, 'refresh_token');

      if (accessToken != null && accessToken.isNotEmpty) {
        await _saveDirectTokens(accessToken, refreshToken);
        _authCompleter?.complete({'status': 'success'});
        _authCompleter = null;
        return;
      }

      final code = uri.queryParameters['code'] ?? _extractFromFragment(uri.fragment, 'code');
      if (code != null && code.isNotEmpty && _currentCodeVerifier != null) {
        AppLogger.d('Exchanging PKCE code with Supabase...');
        final res = await _authDio.post(
          '/auth/v1/token?grant_type=pkce',
          data: {
            'auth_code': code,
            'code_verifier': _currentCodeVerifier,
          },
        );

        if (res.statusCode == 200 && res.data != null) {
          await _saveSession(res.data as Map<String, dynamic>);
          _authCompleter?.complete({'status': 'success'});
        } else {
          _authCompleter?.complete({
            'status': 'error',
            'message': 'تعذّر إكمال تسجيل الدخول من السيرفر',
          });
        }
      } else {
        _authCompleter?.complete({
          'status': 'error',
          'message': 'لم يتم استلام رمز تسجيل الدخول',
        });
      }
    } catch (e, stack) {
      AppLogger.e('Error handling redirect', e, stack);
      _authCompleter?.complete({
        'status': 'error',
        'message': 'حدث خطأ أثناء معالجة تسجيل الدخول',
      });
    } finally {
      _authCompleter = null;
      _currentCodeVerifier = null;
    }
  }

  String? _extractFromFragment(String fragment, String key) {
    if (fragment.isEmpty) return null;
    final params = Uri.splitQueryString(fragment);
    return params[key];
  }

  Future<void> _restoreSession() async {
    try {
      final accessToken = await _secureStorage.read(AppConstants.secureKeyAccessToken);
      final userId = await _secureStorage.read(AppConstants.secureKeyUserId);

      if (accessToken != null && accessToken.isNotEmpty && userId != null) {
        final response = await _authDio.get(
          '/auth/v1/user',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );

        if (response.statusCode == 200 && response.data != null) {
          _setUserFromAuthResponse(response.data as Map<String, dynamic>);
          isLoggedIn.value = true;
          AppLogger.d('Session restored for user: ${userEmail.value}');
          await fetchUserProfile();
          syncServices();
        } else {
          await _tryRefreshToken();
        }
      }
    } catch (e) {
      AppLogger.e('Failed to restore session', e);
      await _tryRefreshToken();
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(AppConstants.secureKeyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _authDio.post(
        '/auth/v1/token?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        await _saveSession(response.data as Map<String, dynamic>);
        return true;
      }
    } catch (e) {
      AppLogger.e('Token refresh failed', e);
      await _clearSession();
    }
    return false;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    return _signInWithOAuthProvider('google');
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    return _signInWithOAuthProvider('apple');
  }

  Future<Map<String, dynamic>> _signInWithOAuthProvider(String provider) async {
    try {
      AppLogger.d('Starting OAuth flow for provider: $provider');
      _currentCodeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_currentCodeVerifier!);

      final authUrl = Uri.parse(
        '${ApiConstants.baseUrl}/auth/v1/authorize'
        '?provider=$provider'
        '&redirect_to=${Uri.encodeComponent(redirectUrl)}'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=s256',
      );

      AppLogger.d('Launching OAuth URL: $authUrl');
      _authCompleter = Completer<Map<String, dynamic>>();

      await launchUrl(
        authUrl,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: AppColors.navyDark,
          ),
          shareState: CustomTabsShareState.off,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          preferredBarTintColor: AppColors.navyDark,
          preferredControlTintColor: Colors.white,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );

      final result = await _authCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _authCompleter = null;
          return {'status': 'cancelled'};
        },
      );

      try {
        await closeCustomTabs();
      } catch (_) {}

      if (result['status'] == 'success') {
        await fetchUserProfile();
        syncServices();
      }

      return result;
    } catch (e, stack) {
      try {
        await closeCustomTabs();
      } catch (_) {}
      AppLogger.e('Error starting OAuth for $provider', e, stack);
      _authCompleter = null;
      return {'status': 'error', 'message': 'تعذّر فتح صفحة تسجيل الدخول'};
    }
  }

  String _generateCodeVerifier() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final rand = Random.secure();
    return List.generate(64, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> _saveDirectTokens(String accessToken, String? refreshToken) async {
    await _secureStorage.write(AppConstants.secureKeyAccessToken, accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(AppConstants.secureKeyRefreshToken, refreshToken);
    }

    final response = await _authDio.get(
      '/auth/v1/user',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    if (response.statusCode == 200 && response.data != null) {
      _setUserFromAuthResponse(response.data as Map<String, dynamic>);
    }

    isLoggedIn.value = true;
    await fetchUserProfile();
    syncServices();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;

    if (accessToken != null) {
      await _secureStorage.write(AppConstants.secureKeyAccessToken, accessToken);
    }
    if (refreshToken != null) {
      await _secureStorage.write(AppConstants.secureKeyRefreshToken, refreshToken);
    }
    if (user != null) {
      final userId = user['id'] as String? ?? '';
      await _secureStorage.write(AppConstants.secureKeyUserId, userId);
      _setUserFromAuthResponse(user);
    }

    isLoggedIn.value = true;
    await fetchUserProfile();
    syncServices();
  }

  void _setUserFromAuthResponse(Map<String, dynamic> user) {
    final email = user['email'] as String? ?? '';
    final meta = user['user_metadata'] as Map<String, dynamic>? ?? {};
    final name = meta['full_name'] as String? ?? meta['name'] as String? ?? '';
    final avatar = meta['avatar_url'] as String? ?? meta['picture'] as String? ?? '';
    final userId = user['id'] as String? ?? '';

    userEmail.value = email;
    if (name.isNotEmpty) userName.value = name;
    if (avatar.isNotEmpty) userAvatar.value = avatar;

    currentUser.value = UserModel(
      id: userId,
      fullName: userName.value.isNotEmpty ? userName.value : null,
      avatarUrl: userAvatar.value.isNotEmpty ? userAvatar.value : null,
      phone: userPhone.value.isNotEmpty ? userPhone.value : null,
      pointsBalance: pointsBalance.value,
      isAdmin: isAdmin.value,
    );
  }

  Future<void> fetchUserProfile() async {
    final userId = await _secureStorage.read(AppConstants.secureKeyUserId);
    final token = await _secureStorage.read(AppConstants.secureKeyAccessToken);
    if (userId == null || token == null) return;

    try {
      AppLogger.d('Fetching profile for userId: $userId');
      final res = await _authDio.get(
        '/rest/v1/profiles',
        queryParameters: {'id': 'eq.$userId', 'select': '*'},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'apikey': ApiConstants.anonKey,
        }),
      );

      AppLogger.d('Profile response status: ${res.statusCode}');
      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List && (res.data as List).isNotEmpty) {
        final data = (res.data as List).first as Map<String, dynamic>;
        final fn = data['full_name'] as String?;
        final ph = data['phone'] as String?;
        final av = data['avatar_url'] as String?;
        final pts = (data['points_balance'] as num?)?.toInt() ?? 0;

        if (fn != null && fn.isNotEmpty) userName.value = fn;
        if (ph != null && ph.isNotEmpty) userPhone.value = ph;
        if (av != null && av.isNotEmpty) userAvatar.value = av;
        pointsBalance.value = pts;
      }

      final roleRes = await _authDio.get(
        '/rest/v1/user_roles',
        queryParameters: {'user_id': 'eq.$userId', 'role': 'eq.admin', 'select': 'role'},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'apikey': ApiConstants.anonKey,
        }),
      );
      if (roleRes.statusCode == 200 && roleRes.data is List && (roleRes.data as List).isNotEmpty) {
        isAdmin.value = true;
      }

      currentUser.value = UserModel(
        id: userId,
        fullName: userName.value.isNotEmpty ? userName.value : null,
        phone: userPhone.value.isNotEmpty ? userPhone.value : null,
        avatarUrl: userAvatar.value.isNotEmpty ? userAvatar.value : null,
        pointsBalance: pointsBalance.value,
        isAdmin: isAdmin.value,
      );
    } catch (e) {
      AppLogger.e('Error fetching user profile', e);
    }
  }

  Future<bool> updateFullName(String newName) async {
    final userId = await _secureStorage.read(AppConstants.secureKeyUserId);
    final token = await _secureStorage.read(AppConstants.secureKeyAccessToken);
    if (userId == null || token == null) return false;

    try {
      final res = await _authDio.patch(
        '/rest/v1/profiles',
        queryParameters: {'id': 'eq.$userId'},
        data: {'full_name': newName.trim()},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'apikey': ApiConstants.anonKey,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        userName.value = newName.trim();
        currentUser.value = currentUser.value?.copyWith(fullName: newName.trim());
        return true;
      }
    } catch (e) {
      AppLogger.e('Error updating full name', e);
    }
    return false;
  }

  void syncServices() {
    final userId = currentUser.value?.id;
    if (userId != null && userId.isNotEmpty) {
      if (Get.isRegistered<CartService>()) {
        Get.find<CartService>().syncWithServer(userId);
      }
      if (Get.isRegistered<FavoritesService>()) {
        Get.find<FavoritesService>().syncWithServer(userId);
      }
    }
  }

  Future<void> signOut() async {
    try {
      final accessToken = await _secureStorage.read(AppConstants.secureKeyAccessToken);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _authDio.post(
          '/auth/v1/logout',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
      }
    } catch (_) {}

    await _clearSession();
  }

  Future<void> _clearSession() async {
    await _secureStorage.deleteAll();
    isLoggedIn.value = false;
    currentUser.value = null;
    userEmail.value = '';
    userName.value = '';
    userPhone.value = '';
    userAvatar.value = '';
    pointsBalance.value = 0;
    isAdmin.value = false;

    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().clearLocalCache();
    }
    if (Get.isRegistered<FavoritesService>()) {
      Get.find<FavoritesService>().clearLocalCache();
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(AppConstants.secureKeyAccessToken);
  }

  Future<bool> refreshAndRetry() async {
    return await _tryRefreshToken();
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
