import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:realtime_client/realtime_client.dart';
import '../../app/config/api_constants.dart';
import '../../app/config/app_constants.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import '../widgets/notification_popup.dart';
import 'secure_storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../app/routes/app_routes.dart';
import '../../data/repositories/order_repository.dart';
import '../../modules/orders/views/order_details_view.dart';
import '../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../modules/home/controllers/home_controller.dart';

class NotificationService extends GetxService with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Reactive state ──────────────────────────────────────────────
  final RxInt unreadCount = 0.obs;
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;

  // ── Realtime ────────────────────────────────────────────────────
  RealtimeClient? _realtimeClient;
  RealtimeChannel? _notifChannel;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _bannersChannel;
  String? _currentUserId;

  // ── Orders stream (orders_view listens to this) ─────────────────
  final StreamController<void> _ordersUpdateController =
      StreamController<void>.broadcast();
  Stream<void> get ordersUpdates => _ordersUpdateController.stream;

  // ── FCM token refresh subscription ──────────────────────────────
  StreamSubscription<String>? _tokenRefreshSub;

  // ── Cold start pending notification data ────────────────────────
  Map<String, dynamic>? _pendingColdStartData;

  // ──────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────
  Future<NotificationService> init() async {
    // 1. Local notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2. FCM foreground listener
    FirebaseMessaging.onMessage.listen(_handleForegroundFcm);

    // 2b. FCM background tap — user tapped a push while app was backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmMessageTap);

    // 2c. Cold start detection — user launched app from local notification or FCM push
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload != null) {
      try {
        _pendingColdStartData = jsonDecode(
            launchDetails!.notificationResponse!.payload!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      _pendingColdStartData = initialMessage.data;
    }

    // 3. Request notification permission & configure iOS presentation
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.w('Notification permission was denied by the user');
      unawaited(_logNotificationEvent(
        eventType: 'permission_denied',
        status: 'warning',
        title: 'رفض إذن الإشعارات من المستخدم',
        message: 'المستخدم رفض منح إذن الإشعارات في نظام التشغيل.',
        errorDetails: 'AuthorizationStatus.denied',
      ));
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Lifecycle observer (reconnect on resume)
    WidgetsBinding.instance.addObserver(this);

    return this;
  }

  // ──────────────────────────────────────────────────────────────────
  // App lifecycle — reconnect Realtime when app resumes
  // ──────────────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      fetchUnreadCount();
      registerFcmToken();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Start listening — called after login / session restore
  // ──────────────────────────────────────────────────────────────────
  Future<void> startListening(String userId) async {
    if (_currentUserId == userId && _realtimeClient != null) return;
    await stopListening();
    _currentUserId = userId;

    final token = await Get.find<SecureStorageService>()
        .read(AppConstants.secureKeyAccessToken);

    // ── Realtime client ───────────────────────────────────────────
    final wsBase = ApiConstants.baseUrl.replaceFirst('https://', 'wss://');
    final wsUrl = '$wsBase/realtime/v1';

    _realtimeClient = RealtimeClient(
      wsUrl,
      params: {'apikey': ApiConstants.anonKey},
    );
    if (token != null) _realtimeClient!.setAuth(token);

    // ── Channel: notifications (INSERT → popup + badge) ───────────
    _notifChannel = _realtimeClient!
        .channel('notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (PostgresChangePayload payload) {
            _handleNewNotification(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            fetchUnreadCount();
          },
        );
    _notifChannel!.subscribe();

    // ── Channel: orders (UPDATE → auto‑refresh orders list) ───────
    _ordersChannel = _realtimeClient!
        .channel('orders-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            _ordersUpdateController.add(null);
          },
        );
    _ordersChannel!.subscribe();

    // ── Channel: banners (Live reload banners on home) ────────────
    _bannersChannel = _realtimeClient!
        .channel('public-banners')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'banners',
          callback: (_) {
            AppLogger.d('Realtime banners table update detected');
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().refreshBanners();
            }
          },
        );
    _bannersChannel!.subscribe();

    // ── FCM token registration ────────────────────────────────────
    await registerFcmToken();

    // ── Initial data fetch ────────────────────────────────────────
    await fetchUnreadCount();
    await fetchNotifications();
  }

  // ──────────────────────────────────────────────────────────────────
  // Stop listening — called on logout
  // ──────────────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    if (_notifChannel != null) {
      _realtimeClient?.removeChannel(_notifChannel!);
      _notifChannel = null;
    }
    if (_ordersChannel != null) {
      _realtimeClient?.removeChannel(_ordersChannel!);
      _ordersChannel = null;
    }
    if (_bannersChannel != null) {
      _realtimeClient?.removeChannel(_bannersChannel!);
      _bannersChannel = null;
    }
    _realtimeClient?.disconnect();
    _realtimeClient = null;
    _currentUserId = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    unreadCount.value = 0;
    notifications.clear();
  }

  // ──────────────────────────────────────────────────────────────────
  // Update Realtime auth token (after token refresh)
  // ──────────────────────────────────────────────────────────────────
  void updateRealtimeAuth(String accessToken) {
    _realtimeClient?.setAuth(accessToken);
  }

  // ── Notification Deduplication Tracking ──────────────────────────
  final Set<String> _processedNotifKeys = <String>{};

  List<String> _extractDedupKeys({
    String? notifId,
    String? orderId,
    String? status,
    String? type,
    String? title,
    String? body,
    String? messageId,
  }) {
    final keys = <String>[];
    if (notifId != null && notifId.trim().isNotEmpty) {
      keys.add('notif:${notifId.trim()}');
    }
    if (orderId != null && orderId.trim().isNotEmpty) {
      final oId = orderId.trim();
      final effectiveType = type?.trim() ?? 'order';
      keys.add('order:$effectiveType:$oId');
      if (status != null && status.trim().isNotEmpty) {
        keys.add('order_status:$effectiveType:$oId:${status.trim()}');
      }
      if (title != null && title.trim().isNotEmpty) {
        keys.add('order_title:$effectiveType:$oId:${title.trim()}');
      }
    }
    if (title != null && title.trim().isNotEmpty) {
      final sanitizedTitle = title.trim();
      final sanitizedBody = body?.trim() ?? '';
      keys.add('content:$sanitizedTitle:$sanitizedBody');
    }
    if (messageId != null && messageId.trim().isNotEmpty) {
      keys.add('fcm:${messageId.trim()}');
    }
    return keys;
  }

  bool _isAnyKeyProcessed(List<String> keys) {
    return keys.any((k) => _processedNotifKeys.contains(k));
  }

  void _recordAllKeys(List<String> keys) {
    for (final k in keys) {
      if (k.isNotEmpty) {
        _processedNotifKeys.add(k);
      }
    }
    Timer(const Duration(minutes: 2), () {
      for (final k in keys) {
        _processedNotifKeys.remove(k);
      }
    });
  }

  int _deriveTrayId({String? orderId, String? notifId, String? title, String? type}) {
    if (type != null && type.trim().isNotEmpty && orderId != null && orderId.trim().isNotEmpty) {
      return ('${type.trim()}:${orderId.trim()}'.hashCode & 0x7FFFFFFF);
    }
    if (orderId != null && orderId.trim().isNotEmpty) {
      return (orderId.trim().hashCode & 0x7FFFFFFF);
    }
    if (notifId != null && notifId.trim().isNotEmpty) {
      return (notifId.trim().hashCode & 0x7FFFFFFF);
    }
    if (title != null && title.trim().isNotEmpty) {
      return (title.trim().hashCode & 0x7FFFFFFF);
    }
    return DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  }

  // ──────────────────────────────────────────────────────────────────
  // Handle new notification from Realtime INSERT
  // ──────────────────────────────────────────────────────────────────
  void _handleNewNotification(Map<String, dynamic> row) {
    if (row['read_at'] != null) return;

    final notifId = row['id'] as String? ?? '';
    final orderId = row['order_id'] as String? ?? '';
    final status = row['status'] as String? ?? '';
    final type = row['type'] as String? ?? '';
    final title = row['title'] as String? ?? '';
    final body = row['body'] as String? ?? '';

    final keys = _extractDedupKeys(
      notifId: notifId,
      orderId: orderId,
      status: status,
      type: type,
      title: title,
      body: body,
    );

    final isDuplicate = _isAnyKeyProcessed(keys);
    _recordAllKeys(keys);

    if (isDuplicate) {
      AppLogger.d('Realtime notification ignored (duplicate detected): $keys');
      return;
    }

    // Deduplicate in reactive notifications list
    final existingIdx = notifId.isNotEmpty
        ? notifications.indexWhere((n) => n['id'] == notifId)
        : -1;
    if (existingIdx == -1) {
      unreadCount.value++;
      notifications.insert(0, row);
    }

    // If promo notification, reload banners immediately so they appear live
    if (row['type'] == 'promo') {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshBanners();
      }
    }

    // Only show system tray notification if not already shown
    if (title.isNotEmpty) {
      final trayId = _deriveTrayId(orderId: orderId, notifId: notifId, title: title, type: type);
      showLocalNotification(
        id: trayId,
        title: title,
        body: body,
        payload: jsonEncode({
          'order_id': row['order_id'],
          'type': row['type'],
          'notification_id': row['id'],
        }),
      );
    }

    // In‑app popup
    NotificationPopup.show(
      title: title,
      body: body,
      type: row['type'] as String?,
      notifId: row['id'] as String? ?? '',
      orderId: orderId.isNotEmpty ? orderId : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Handle foreground FCM message
  // ──────────────────────────────────────────────────────────────────
  void _handleForegroundFcm(RemoteMessage message) {
    AppLogger.d('FCM foreground: ${message.notification?.title}');
    final orderId = message.data['order_id'] as String?;
    final notifId = message.data['notification_id'] as String?;
    final status = message.data['status'] as String?;
    final type = message.data['type'] as String?;
    final title = message.notification?.title ?? message.data['title'] as String? ?? '';
    final body = message.notification?.body ?? message.data['body'] as String? ?? '';
    final messageId = message.messageId;

    final keys = _extractDedupKeys(
      notifId: notifId,
      orderId: orderId,
      status: status,
      type: type,
      title: title,
      body: body,
      messageId: messageId,
    );

    final isDuplicate = _isAnyKeyProcessed(keys);
    _recordAllKeys(keys);

    // If already processed by Realtime, DO NOT show duplicate tray notification!
    if (isDuplicate) {
      AppLogger.d('FCM foreground ignored (already handled by Realtime): $keys');
      return;
    }

    if (title.isNotEmpty) {
      final trayId = _deriveTrayId(orderId: orderId, notifId: notifId, title: title, type: type);
      showLocalNotification(
        id: trayId,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Device info & logging helpers
  // ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    String appVer = '1.1.0';
    try {
      final info = await PackageInfo.fromPlatform();
      appVer = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    final isIos = Platform.isIOS;
    return {
      'client': 'flutter',
      'platform': isIos ? 'ios' : 'android',
      'os_version': Platform.operatingSystemVersion,
      'device_model': isIos ? 'iPhone / iOS Device' : 'Android Device',
      'app_version': appVer,
    };
  }

  Future<void> _logNotificationEvent({
    required String eventType,
    required String status,
    String? platform,
    String? title,
    String? message,
    String? errorDetails,
    Map<String, dynamic>? deviceInfo,
    String? tokenPreview,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final dio = Get.find<DioClient>().dio;
      final plat = platform ?? (Platform.isIOS ? 'ios' : 'android');
      final info = deviceInfo ?? await _collectDeviceInfo();

      await dio.post(
        ApiConstants.rpcLogNotificationEvent,
        data: {
          'p_event_type': eventType,
          'p_status': status,
          'p_platform': plat,
          'p_title': title,
          'p_message': message,
          'p_error_details': errorDetails,
          'p_device_info': info,
          'p_token_preview': tokenPreview,
          'p_metadata': metadata ?? {},
        },
      );
    } catch (e) {
      AppLogger.w('Failed to post notification log event: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // FCM token registration with full diagnostic logging
  // ──────────────────────────────────────────────────────────────────
  Future<void> registerFcmToken() async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final deviceInfo = await _collectDeviceInfo();

    try {
      // On iOS, APNs token must be resolved before FCM token can be generated
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          // Retry for up to 5 seconds for APNs registration to complete
          for (var i = 0; i < 5; i++) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) break;
          }
        }
        if (apnsToken == null) {
          AppLogger.w('APNs token is not ready yet on iOS after 5 seconds');
          await _logNotificationEvent(
            eventType: 'apns_failed',
            status: 'failure',
            platform: 'ios',
            title: 'تعذر استلام APNs Token في iPhone',
            message: 'لم يتمكن جهاز الآيفون من الحصول على APNs Token من خوادم Apple بعد 5 محاولات.',
            errorDetails: 'FirebaseMessaging.getAPNSToken() returned null.',
            deviceInfo: deviceInfo,
          );
          Future.delayed(const Duration(seconds: 5), () => registerFcmToken());
          return;
        }
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (tokenErr) {
        AppLogger.e('Failed to get FCM token', tokenErr);
        await _logNotificationEvent(
          eventType: 'fcm_failed',
          status: 'failure',
          platform: platform,
          title: 'فشل استخراج FCM Token من Firebase',
          message: 'حدث استثناء أثناء محاولة استخراج رمز الجهاز من Firebase.',
          errorDetails: tokenErr.toString(),
          deviceInfo: deviceInfo,
        );
        return;
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        AppLogger.w('FCM token is null or empty');
        await _logNotificationEvent(
          eventType: 'fcm_failed',
          status: 'failure',
          platform: platform,
          title: 'رمز FCM فارغ من Firebase',
          message: 'أرجعت خدمة Firebase قيمة فارغة لرمز الإشعارات.',
          errorDetails: 'getToken() returned null or empty string',
          deviceInfo: deviceInfo,
        );
        return;
      }

      final preview = fcmToken.length > 14
          ? '${fcmToken.substring(0, 8)}...${fcmToken.substring(fcmToken.length - 6)}'
          : fcmToken.substring(0, 8);

      AppLogger.d('FCM token obtained ($preview)');

      final dio = Get.find<DioClient>().dio;
      try {
        await dio.post(
          ApiConstants.rpcRegisterDeviceToken,
          data: {
            'p_token': fcmToken,
            'p_platform': platform,
            'p_device_info': deviceInfo,
          },
        );
        AppLogger.d('FCM token registered successfully');
      } catch (postErr) {
        AppLogger.e('Failed to register device token via RPC', postErr);
        await _logNotificationEvent(
          eventType: 'token_registration_failed',
          status: 'failure',
          platform: platform,
          title: 'فشل حفظ التوكن في السيرفر',
          message: 'فشل اتصال حفظ التوكن مع قاعدة البيانات.',
          errorDetails: postErr.toString(),
          tokenPreview: preview,
          deviceInfo: deviceInfo,
        );
      }

      // Listen for token refresh
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await dio.post(
            ApiConstants.rpcRegisterDeviceToken,
            data: {
              'p_token': newToken,
              'p_platform': platform,
              'p_device_info': deviceInfo,
            },
          );
          AppLogger.d('FCM token refreshed and registered');
        } catch (e) {
          AppLogger.e('Failed to re-register refreshed FCM token', e);
          await _logNotificationEvent(
            eventType: 'token_registration_failed',
            status: 'failure',
            platform: platform,
            title: 'فشل تحديث التوكن في السيرفر',
            message: 'حدث خطأ أثناء حفظ التوكن الجديد بعد تجديده تلقائياً.',
            errorDetails: e.toString(),
            deviceInfo: deviceInfo,
          );
        }
      });
    } catch (e) {
      AppLogger.e('Failed to register FCM token', e);
      await _logNotificationEvent(
        eventType: 'token_registration_failed',
        status: 'failure',
        platform: platform,
        title: 'خطأ عام أثناء تسجيل التوكن',
        message: 'حدث استثناء غير معالج أثناء تسجيل توكن الإشعارات.',
        errorDetails: e.toString(),
        deviceInfo: deviceInfo,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Notification tap handler (local tray notification tapped)
  // ──────────────────────────────────────────────────────────────────
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.d('Notification tapped: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      handleNotificationNavigation(
        type: data['type'] as String?,
        orderId: data['order_id'] as String?,
        productId: data['product_id'] as String?,
        bannerId: (data['banner_id'] as String?) ?? (data['status'] as String?),
        status: data['status'] as String?,
      );
    } catch (e) {
      AppLogger.e('Failed to parse notification payload', e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // FCM message tap handler (push tapped while backgrounded/terminated)
  // ──────────────────────────────────────────────────────────────────
  void _handleFcmMessageTap(RemoteMessage message) {
    AppLogger.d('FCM message tap: ${message.data}');
    handleNotificationNavigation(
      type: message.data['type'] as String?,
      orderId: message.data['order_id'] as String?,
      productId: message.data['product_id'] as String?,
      bannerId: (message.data['banner_id'] as String?) ?? (message.data['status'] as String?),
      status: message.data['status'] as String?,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Centralized notification deep-link navigation
  // ──────────────────────────────────────────────────────────────────
  Future<void> handleNotificationNavigation({
    String? type,
    String? orderId,
    String? productId,
    String? bannerId,
    String? status,
  }) async {
    final effectiveBannerId = (bannerId != null && bannerId.isNotEmpty)
        ? bannerId
        : ((status != null && status.isNotEmpty && status.length > 20) ? status : null);

    AppLogger.d('Navigating for notification: type=$type, orderId=$orderId, productId=$productId, bannerId=$effectiveBannerId');

    // Fallback: if type is missing but orderId is provided, treat as order_status
    final resolvedType = (type == null || type.isEmpty)
        ? (orderId != null && orderId.isNotEmpty ? 'order_status' : '')
        : type;

    switch (resolvedType) {
      case 'order_status':
      case 'admin_new_order':
        if (orderId != null && orderId.isNotEmpty) {
          try {
            if (Get.isRegistered<OrderRepository>()) {
              final repo = Get.find<OrderRepository>();
              final order = await repo.fetchOrderById(orderId);
              if (order != null) {
                Get.to(
                  () => OrderDetailsView(order: order),
                  transition: Transition.fade,
                );
                return;
              }
            }
          } catch (e) {
            AppLogger.e('Failed to fetch order for notification', e);
          }
          // Fallback: go to orders list
          Get.toNamed(AppRoutes.orders);
        } else {
          Get.toNamed(AppRoutes.orders);
        }
        break;

      case 'promo':
      case 'banner_comment':
      case 'banner_reply':
        Get.toNamed(
          AppRoutes.reels,
          arguments: effectiveBannerId != null && effectiveBannerId.isNotEmpty
              ? {'targetBannerId': effectiveBannerId}
              : null,
        );
        break;

      case 'new_product':
      case 'product':
        if (productId != null && productId.isNotEmpty) {
          Get.toNamed(
            AppRoutes.productDetails,
            arguments: productId,
            preventDuplicates: false,
          );
        } else {
          if (Get.isRegistered<MainNavController>()) {
            Get.find<MainNavController>().changeTab(1);
            Get.until((route) => Get.currentRoute == AppRoutes.mainNav);
          } else {
            Get.offAllNamed(AppRoutes.mainNav);
          }
        }
        break;

      case 'replacement_status':
        Get.toNamed(AppRoutes.replacements);
        break;

      case 'account_status':
        // Navigate to main nav account tab (tab index 4)
        if (Get.isRegistered<MainNavController>()) {
          Get.find<MainNavController>().changeTab(4);
          Get.until((route) => Get.currentRoute == AppRoutes.mainNav);
        } else {
          Get.offAllNamed(AppRoutes.mainNav);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (Get.isRegistered<MainNavController>()) {
              Get.find<MainNavController>().changeTab(4);
            }
          });
        }
        break;

      case 'admin_broadcast':
        Get.toNamed(AppRoutes.notifications);
        break;

      default:
        // Unknown type — go to notifications list
        Get.toNamed(AppRoutes.notifications);
        break;
    }
  }

  /// Called after splash screen completes and MainNav is mounted
  void checkAndExecutePendingNotification() {
    if (_pendingColdStartData != null) {
      final data = _pendingColdStartData!;
      _pendingColdStartData = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        handleNotificationNavigation(
          type: data['type'] as String?,
          orderId: data['order_id'] as String?,
          productId: data['product_id'] as String?,
          bannerId: (data['banner_id'] as String?) ?? (data['status'] as String?),
          status: data['status'] as String?,
        );
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Data fetching
  // ──────────────────────────────────────────────────────────────────
  Future<void> fetchUnreadCount() async {
    if (_currentUserId == null) return;
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'user_id': 'eq.$_currentUserId',
          'read_at': 'is.null',
          'select': 'id',
          'order': 'created_at.desc',
          'limit': 200,
        },
      );
      if (res.statusCode == 200 && res.data is List) {
        unreadCount.value = (res.data as List).length;
      }
    } catch (e) {
      AppLogger.e('Failed to fetch unread count', e);
    }
  }

  Future<void> fetchNotifications({int limit = 30}) async {
    if (_currentUserId == null) return;
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'user_id': 'eq.$_currentUserId',
          'select':
              'id,order_id,title,body,status,type,read_at,created_at',
          'order': 'created_at.desc',
          'limit': limit,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 206) &&
          res.data is List) {
        notifications.value =
            List<Map<String, dynamic>>.from(res.data as List);
      }
    } catch (e) {
      AppLogger.e('Failed to fetch notifications', e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Mark read
  // ──────────────────────────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    try {
      final dio = Get.find<DioClient>().dio;
      final now = DateTime.now().toUtc().toIso8601String();
      await dio.patch(
        ApiConstants.notifications,
        queryParameters: {'id': 'eq.$notifId'},
        data: {'read_at': now},
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );

      final idx = notifications.indexWhere((n) => n['id'] == notifId);
      if (idx >= 0) {
        notifications[idx] = {...notifications[idx], 'read_at': now};
        notifications.refresh();
      }
      await fetchUnreadCount();
    } catch (e) {
      AppLogger.e('Failed to mark notification read', e);
    }
  }

  Future<void> markAllRead() async {
    if (_currentUserId == null) return;
    try {
      final dio = Get.find<DioClient>().dio;
      final now = DateTime.now().toUtc().toIso8601String();
      await dio.patch(
        ApiConstants.notifications,
        queryParameters: {
          'user_id': 'eq.$_currentUserId',
          'read_at': 'is.null',
        },
        data: {'read_at': now},
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );

      for (var i = 0; i < notifications.length; i++) {
        if (notifications[i]['read_at'] == null) {
          notifications[i] = {...notifications[i], 'read_at': now};
        }
      }
      notifications.refresh();
      unreadCount.value = 0;
    } catch (e) {
      AppLogger.e('Failed to mark all read', e);
    }
  }

  Future<void> markOrderNotificationsRead(String orderId) async {
    if (_currentUserId == null) return;
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        ApiConstants.notifications,
        queryParameters: {
          'user_id': 'eq.$_currentUserId',
          'order_id': 'eq.$orderId',
          'read_at': 'is.null',
        },
        data: {'read_at': DateTime.now().toUtc().toIso8601String()},
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );
      await fetchUnreadCount();
    } catch (e) {
      AppLogger.e('Failed to mark order notifications read', e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Show local notification (system tray)
  // ──────────────────────────────────────────────────────────────────
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ali_parts_channel',
      'Ali Parts Notifications',
      channelDescription: 'Order updates and promotional offers',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // Keep backward‑compatible alias
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) =>
      showLocalNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );

  // ──────────────────────────────────────────────────────────────────
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
    _ordersUpdateController.close();
    super.onClose();
  }
}
