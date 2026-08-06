import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Owns the client side of Firebase Cloud Messaging.
///
/// Low-stock sends are addressed to a business topic rather than a device
/// token. That makes sign-in, token rotation, and a device being replaced
/// transparent to the sender. Topics are deliberately scoped to the current
/// tenant and removed on logout/account switching.
class FcmNotificationService {
  FcmNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _subscribedTopic;
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'low_stock_alerts',
    'Low stock alerts',
    description: 'Alerts when inventory reaches its reorder level.',
    importance: Importance.high,
  );

  /// Sanitised stable FCM topic for a business UUID.
  static String lowStockTopic(String businessId) {
    final safeId = businessId.replaceAll(RegExp(r'[^A-Za-z0-9_.~-]'), '');
    if (safeId.isEmpty) {
      throw ArgumentError.value(businessId, 'businessId', 'must not be blank');
    }
    return 'low-stock-$safeId';
  }

  static bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Requests notification permission and starts foreground-message handling.
  /// Safe to call repeatedly and intentionally a no-op on unsupported targets.
  Future<void> initialize() async {
    if (_initialized || !_isSupported) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FCM] Foreground message error: $error\n$stackTrace');
      },
    );
    _initialized = true;
  }

  /// Joins the current business's topic only for users who may see stock
  /// levels. A previous business is always left before the new one is joined.
  Future<void> configureLowStockTopic({
    required String? businessId,
    required bool mayViewStockLevels,
  }) async {
    await initialize();
    if (!_isSupported) return;

    final target = businessId != null && mayViewStockLevels
        ? lowStockTopic(businessId)
        : null;
    if (_subscribedTopic == target) return;

    final previous = _subscribedTopic;
    if (previous != null) {
      await _messaging.unsubscribeFromTopic(previous);
      _subscribedTopic = null;
    }
    if (target != null) {
      await _messaging.subscribeToTopic(target);
      _subscribedTopic = target;
    }
  }

  Future<void> clear() =>
      configureLowStockTopic(businessId: null, mayViewStockLevels: false);

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Low stock alert';
    final body =
        notification?.body ??
        message.data['body'] ??
        'An item has reached its reorder level.';
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock_alerts',
          'Low stock alerts',
          channelDescription:
              'Alerts when inventory reaches its reorder level.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: message.data['variant_id']?.toString(),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
    _initialized = false;
  }
}
