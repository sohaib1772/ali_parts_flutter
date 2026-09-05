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
  String? _currentUserId;

  // ── Orders stream (orders_view listens to this) ─────────────────
  final StreamController<void> _ordersUpdateController =
      StreamController<void>.broadcast();
  Stream<void> get ordersUpdates => _ordersUpdateController.stream;

  // ── FCM token refresh subscription ──────────────────────────────
  StreamSubscription<String>? _tokenRefreshSub;

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

    // 3. Request notification permission
    await FirebaseMessaging.instance.requestPermission(
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
      keys.add('order:$oId');
      if (status != null && status.trim().isNotEmpty) {
        keys.add('order_status:$oId:${status.trim()}');
      }
      if (title != null && title.trim().isNotEmpty) {
        keys.add('order_title:$oId:${title.trim()}');
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

  int _deriveTrayId({String? orderId, String? notifId, String? title}) {
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

    // Only show system tray notification if not already shown
    if (title.isNotEmpty) {
      final trayId = _deriveTrayId(orderId: orderId, notifId: notifId, title: title);
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
      final trayId = _deriveTrayId(orderId: orderId, notifId: notifId, title: title);
      showLocalNotification(
        id: trayId,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // FCM token registration
  // ──────────────────────────────────────────────────────────────────
  Future<void> registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      AppLogger.d('FCM token obtained (${fcmToken.substring(0, 12)}...)');

      final dio = Get.find<DioClient>().dio;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await dio.post(
        ApiConstants.rpcRegisterDeviceToken,
        data: {'p_token': fcmToken, 'p_platform': platform},
      );
      AppLogger.d('FCM token registered');

      // Listen for token refresh
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await dio.post(
            ApiConstants.rpcRegisterDeviceToken,
            data: {'p_token': newToken, 'p_platform': platform},
          );
          AppLogger.d('FCM token refreshed');
        } catch (e) {
          AppLogger.e('Failed to re-register FCM token', e);
        }
      });
    } catch (e) {
      AppLogger.e('Failed to register FCM token', e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Notification tap handler
  // ──────────────────────────────────────────────────────────────────
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.d('Notification tapped: ${response.payload}');
    // Navigation could be added here based on payload
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
