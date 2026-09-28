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
import '../../app/routes/app_routes.dart';
import '../../modules/reels/controllers/reels_controller.dart';
import 'cart_service.dart';
import 'favorites_service.dart';
import 'notification_service.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';

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
  final RxBool isStaff = false.obs;
  final Rx<Map<String, dynamic>?> staffPermissions = Rx<Map<String, dynamic>?>(null);

  bool get canAccessAdmin => isAdmin.value || isStaff.value;
  String? get userId => currentUser.value?.id;

  StreamSubscription<Uri>? _linkSubscription;
  Completer<Map<String, dynamic>>? _authCompleter;
  String? _currentCodeVerifier;
  Uri? _pendingDeepLinkUri;
  String? _lastHandledDeepLink;
  DateTime? _lastDeepLinkTime;
  bool _isNavigatingToReels = false;
  Completer<bool>? _refreshCompleter;
  static const String _keyCachedProfile = 'cached_user_profile';

  bool get _isNavigatorReady {
    try {
      return Get.key.currentState != null;
    } catch (_) {
      return false;
    }
  }

  /// Called after splash screen completes and MainNav is mounted
  void checkAndExecutePendingDeepLink() {
    if (_pendingDeepLinkUri != null) {
      final uri = _pendingDeepLinkUri!;
      _pendingDeepLinkUri = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleIncomingRedirect(uri);
      });
    }
  }

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

    // Check initial deep link on cold launch
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        AppLogger.d('Received initial launch deep link: $uri');
        _handleIncomingRedirect(uri);
      }
    }).catchError((err) {
      AppLogger.e('Error checking initial deep link', err);
    });
  }

  void _handleIncomingRedirect(Uri uri) async {
    // 1. Reel / Banner Deep Link
    final isReelLink = ((uri.host == 'maktabali.com' || uri.host == 'www.maktabali.com') &&
            (uri.path.startsWith('/reels') || uri.path.startsWith('/reel') || uri.path.startsWith('/offers'))) ||
        (uri.scheme == 'com.mkteb.ali.chevrolet' &&
            (uri.host == 'reel' ||
                uri.host == 'reels' ||
                uri.host == 'offers' ||
                uri.path.startsWith('/reel') ||
                uri.path.startsWith('/reels') ||
                uri.path.startsWith('/offers')));

    if (isReelLink) {
      String? bannerId = uri.queryParameters['id'] ?? uri.queryParameters['bannerId'];
      if (bannerId == null || bannerId.isEmpty) {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty &&
            segments.last != 'reels' &&
            segments.last != 'reel' &&
            segments.last != 'offers') {
          bannerId = segments.last;
        }
      }

      // 1. De-duplicate: ignore if the exact same link was handled recently (within 4 seconds)
      final uriString = uri.toString();
      final now = DateTime.now();
      if (_lastHandledDeepLink == uriString &&
          _lastDeepLinkTime != null &&
          now.difference(_lastDeepLinkTime!) < const Duration(seconds: 4)) {
        AppLogger.d('Ignoring duplicate deep link within cooldown: $uriString');
        return;
      }

      // 2. Prevent concurrent navigations
      if (_isNavigatingToReels) {
        AppLogger.d('Already navigating to reels, skipping duplicate invocation');
        return;
      }

      // If navigator is not ready yet or still on splash screen, defer until splash completes
      if (!_isNavigatorReady || Get.currentRoute == AppRoutes.splash || Get.currentRoute.isEmpty) {
        AppLogger.d('Navigator not ready yet or in splash, queuing pending deep link: $uri');
        _pendingDeepLinkUri = uri;
        return;
      }

      _lastHandledDeepLink = uriString;
      _lastDeepLinkTime = now;
      _isNavigatingToReels = true;

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_isNavigatorReady) {
          _pendingDeepLinkUri = uri;
          _isNavigatingToReels = false;
          return;
        }
        try {
          final isAlreadyOnReels = Get.currentRoute.startsWith(AppRoutes.reels);
          if (isAlreadyOnReels) {
            _isNavigatingToReels = false;
            if (bannerId != null && bannerId.isNotEmpty && Get.isRegistered<ReelsController>()) {
              final reelsCtrl = Get.find<ReelsController>();
              final currentBanner = reelsCtrl.banners.isNotEmpty &&
                      reelsCtrl.currentIndex.value < reelsCtrl.banners.length
                  ? reelsCtrl.banners[reelsCtrl.currentIndex.value].id
                  : null;
              if (currentBanner != bannerId) {
                reelsCtrl.handleNewArguments({'targetBannerId': bannerId});
              }
            }
          } else {
            // Dismiss open overlays if any to ensure clean navigation
            if (Get.isDialogOpen == true) Get.back();
            if (Get.isBottomSheetOpen == true) Get.back();

            if (bannerId != null && bannerId.isNotEmpty) {
              Get.toNamed(AppRoutes.reels, arguments: {'targetBannerId': bannerId}, preventDuplicates: true);
            } else {
              Get.toNamed(AppRoutes.reels, preventDuplicates: true);
            }
            Future.delayed(const Duration(milliseconds: 1000), () {
              _isNavigatingToReels = false;
            });
          }
        } catch (e) {
          _isNavigatingToReels = false;
          AppLogger.e('Error navigating to reel via deep link: $e');
        }
      });
      return;
    }

    // 2. OAuth Redirect
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
      final refreshToken = await _secureStorage.read(AppConstants.secureKeyRefreshToken);
      final userId = await _secureStorage.read(AppConstants.secureKeyUserId);

      // 1. Instant offline-first session restoration!
      if (userId != null && userId.isNotEmpty && (accessToken != null || refreshToken != null)) {
        isLoggedIn.value = true;
        _restoreCachedProfile(userId);
        AppLogger.d('Instant session restored locally for user ID: $userId');
      } else {
        AppLogger.d('No saved session credentials found.');
        return;
      }

      // 2. Background verification & refresh (never logs out on network error/offline)
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final response = await _authDio.get(
            '/auth/v1/user',
            options: Options(
              headers: {'Authorization': 'Bearer $accessToken'},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            _setUserFromAuthResponse(response.data as Map<String, dynamic>);
            isLoggedIn.value = true;
            AppLogger.d('Session verified online for user: ${userEmail.value}');
            await fetchUserProfile();
            syncServices();
            return;
          } else if (response.statusCode == 401) {
            AppLogger.d('Stored access token expired (401), attempting token refresh...');
            await _tryRefreshToken();
            return;
          }
        } on DioException catch (e) {
          AppLogger.w('Network error during session verify ($e). Retaining offline login.');
          return;
        } catch (e) {
          AppLogger.w('Non-network error during session verify: $e');
        }
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _tryRefreshToken();
      }
    } catch (e) {
      AppLogger.w('Failed to restore session gracefully: $e');
      // NEVER clear session here; keep user logged in.
    }
  }

  Future<bool> _tryRefreshToken() async {
    // If a refresh is already in-flight, await the ongoing refresh to avoid token rotation race conditions!
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      AppLogger.d('Token refresh already in progress, awaiting existing refresh...');
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final success = await _executeTokenRefresh();
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(success);
      }
      return success;
    } catch (e) {
      AppLogger.w('Unexpected error during token refresh: $e');
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _executeTokenRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(AppConstants.secureKeyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.w('No refresh token available to refresh session.');
        return false;
      }

      final response = await _authDio.post(
        '/auth/v1/token?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await _saveSession(response.data as Map<String, dynamic>);
        final newToken = await _secureStorage.read(AppConstants.secureKeyAccessToken);
        if (newToken != null && Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().updateRealtimeAuth(newToken);
        }
        AppLogger.d('Token refreshed successfully.');
        return true;
      }

      // Check if server explicitly rejected the refresh token:
      if (response.statusCode == 400 || response.statusCode == 401) {
        final data = response.data;
        final error = data is Map ? data['error'] : null;
        final errorDesc = (data is Map ? (data['error_description'] ?? '') : '').toString().toLowerCase();
        AppLogger.w('Refresh token rejected (${response.statusCode}): $error - $errorDesc');

        // Only clear session if user is not found or token was permanently revoked.
        // If it was "Already Used" in a race condition, do NOT destroy session!
        if (error == 'invalid_grant' && (errorDesc.contains('not found') || errorDesc.contains('user not found'))) {
          AppLogger.w('User not found or refresh token permanently invalid; clearing session.');
          await _clearSession();
        }
        return false;
      }

      // Server 5xx: DO NOT clear session!
      AppLogger.w('Server returned ${response.statusCode} during token refresh; keeping session intact.');
      return false;
    } on DioException catch (e) {
      // Network timeout, connection error, DNS failure, offline:
      // NEVER CLEAR SESSION ON NETWORK ISSUES!
      AppLogger.w('Network error during token refresh (${e.type}); keeping session intact.');
      return false;
    } catch (e) {
      AppLogger.w('Token refresh failed: $e; keeping session intact.');
      return false;
    }
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

      // 1. Check Admin Role
      try {
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
        } else {
          isAdmin.value = false;
        }
      } catch (_) {
        isAdmin.value = false;
      }

      // 2. Check Staff Permissions
      try {
        final staffRes = await _authDio.get(
          '/rest/v1/staff_permissions',
          queryParameters: {'user_id': 'eq.$userId', 'select': '*'},
          options: Options(headers: {
            'Authorization': 'Bearer $token',
            'apikey': ApiConstants.anonKey,
          }),
        );
        if (staffRes.statusCode == 200 && staffRes.data is List && (staffRes.data as List).isNotEmpty) {
          final sData = (staffRes.data as List).first as Map<String, dynamic>;
          final hasAnyPerm = sData['can_orders'] == true ||
              sData['can_products'] == true ||
              sData['can_replacements'] == true ||
              sData['can_block'] == true ||
              sData['can_moderate_comments'] == true;
          isStaff.value = hasAnyPerm;
          staffPermissions.value = hasAnyPerm ? sData : null;
        } else {
          isStaff.value = false;
          staffPermissions.value = null;
        }
      } catch (_) {
        isStaff.value = false;
        staffPermissions.value = null;
      }

      currentUser.value = UserModel(
        id: userId,
        fullName: userName.value.isNotEmpty ? userName.value : null,
        phone: userPhone.value.isNotEmpty ? userPhone.value : null,
        avatarUrl: userAvatar.value.isNotEmpty ? userAvatar.value : null,
        pointsBalance: pointsBalance.value,
        isAdmin: isAdmin.value,
        isStaff: isStaff.value,
        staffPermissions: staffPermissions.value,
      );

      _cacheUserProfile({
        'user_id': userId,
        'email': userEmail.value,
        'full_name': userName.value,
        'phone': userPhone.value,
        'avatar_url': userAvatar.value,
        'points_balance': pointsBalance.value,
        'is_admin': isAdmin.value,
        'is_staff': isStaff.value,
        'staff_permissions': staffPermissions.value,
      });
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

  Future<bool> updateAvatar(String newAvatarUrl) async {
    final userId = await _secureStorage.read(AppConstants.secureKeyUserId);
    final token = await _secureStorage.read(AppConstants.secureKeyAccessToken);
    if (userId == null || token == null) return false;

    try {
      final res = await _authDio.patch(
        '/rest/v1/profiles',
        queryParameters: {'id': 'eq.$userId'},
        data: {'avatar_url': newAvatarUrl.trim()},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'apikey': ApiConstants.anonKey,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        userAvatar.value = newAvatarUrl.trim();
        currentUser.value = currentUser.value?.copyWith(avatarUrl: newAvatarUrl.trim());
        return true;
      }
    } catch (e) {
      AppLogger.e('Error updating avatar', e);
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
      // Start realtime notifications & FCM
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().startListening(userId);
      }
    }
  }

  Future<void> signOut() async {
    try {
      final accessToken = await _secureStorage.read(AppConstants.secureKeyAccessToken);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _authDio.post(
          '/auth/v1/logout?scope=local',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
      }
    } catch (_) {}

    await _clearSession();
  }

  Future<void> _clearSession() async {
    // Stop realtime & FCM
    if (Get.isRegistered<NotificationService>()) {
      await Get.find<NotificationService>().stopListening();
    }

    await _secureStorage.deleteAll();
    _clearCachedProfile();
    isLoggedIn.value = false;
    currentUser.value = null;
    userEmail.value = '';
    userName.value = '';
    userPhone.value = '';
    userAvatar.value = '';
    pointsBalance.value = 0;
    isAdmin.value = false;
    isStaff.value = false;
    staffPermissions.value = null;

    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().clearLocalCache();
    }
    if (Get.isRegistered<FavoritesService>()) {
      Get.find<FavoritesService>().clearLocalCache();
    }
  }

  void _cacheUserProfile(Map<String, dynamic> profile) {
    try {
      if (Get.isRegistered<StorageService>()) {
        Get.find<StorageService>().write(_keyCachedProfile, profile);
      }
    } catch (_) {}
  }

  void _restoreCachedProfile(String userId) {
    try {
      if (Get.isRegistered<StorageService>()) {
        final data = Get.find<StorageService>().read<Map>(_keyCachedProfile);
        if (data != null) {
          final profile = Map<String, dynamic>.from(data);
          final fn = profile['full_name'] as String? ?? '';
          final ph = profile['phone'] as String? ?? '';
          final av = profile['avatar_url'] as String? ?? '';
          final em = profile['email'] as String? ?? '';
          final pts = profile['points_balance'] as int? ?? 0;
          final adm = profile['is_admin'] as bool? ?? false;
          final stf = profile['is_staff'] as bool? ?? false;

          if (fn.isNotEmpty) userName.value = fn;
          if (ph.isNotEmpty) userPhone.value = ph;
          if (av.isNotEmpty) userAvatar.value = av;
          if (em.isNotEmpty) userEmail.value = em;
          pointsBalance.value = pts;
          isAdmin.value = adm;
          isStaff.value = stf;
          if (profile['staff_permissions'] is Map) {
            staffPermissions.value = Map<String, dynamic>.from(profile['staff_permissions'] as Map);
          }

          currentUser.value = UserModel(
            id: userId,
            fullName: userName.value.isNotEmpty ? userName.value : null,
            avatarUrl: userAvatar.value.isNotEmpty ? userAvatar.value : null,
            phone: userPhone.value.isNotEmpty ? userPhone.value : null,
            pointsBalance: pointsBalance.value,
            isAdmin: isAdmin.value,
          );
        }
      }
    } catch (_) {}
  }

  void _clearCachedProfile() {
    try {
      if (Get.isRegistered<StorageService>()) {
        Get.find<StorageService>().remove(_keyCachedProfile);
      }
    } catch (_) {}
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
