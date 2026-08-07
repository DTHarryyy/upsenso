import 'dart:async';

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
  }) : _messaging = messaging,
       _localNotifications = localNotifications;

  // Firebase must not be resolved until after the platform guard. On web we
  // intentionally do not initialize Firebase or use FCM, and resolving
  // FirebaseMessaging.instance there throws before the service can no-op.
  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _subscribedLowStockTopic;
  String? _subscribedPlanAlertsTopic;
  bool _initialized = false;

  static const _lowStockChannel = AndroidNotificationChannel(
    'low_stock_alerts',
    'Low stock alerts',
    description: 'Alerts when inventory reaches its reorder level.',
    importance: Importance.high,
  );
  static const _planAlertsChannel = AndroidNotificationChannel(
    'plan_alerts',
    'Plan alerts',
    description: 'Alerts when business resources exceed plan limits.',
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

  /// Billing managers join this business-scoped topic for plan-limit alerts.
  static String planAlertsTopic(String businessId) {
    final safeId = businessId.replaceAll(RegExp(r'[^A-Za-z0-9_.~-]'), '');
    if (safeId.isEmpty) {
      throw ArgumentError.value(businessId, 'businessId', 'must not be blank');
    }
    return 'plan-alerts-$safeId';
  }

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Requests notification permission and starts foreground-message handling.
  /// Safe to call repeatedly and intentionally a no-op on unsupported targets.
  Future<void> initialize() async {
    if (_initialized || !_isSupported) return;

    final localNotifications = _localNotifications ??=
        FlutterLocalNotificationsPlugin();
    final messaging = _messaging ??= FirebaseMessaging.instance;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_lowStockChannel);
    await androidPlugin?.createNotificationChannel(_planAlertsChannel);

    await messaging.requestPermission(alert: true, badge: true, sound: true);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FCM] Foreground message error: $error\n$stackTrace');
      },
    );
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (_) => _resubscribeCurrentTopics().catchError(
        (Object error, StackTrace stackTrace) =>
            debugPrint('[FCM] Topic re-subscribe failed: $error\n$stackTrace'),
      ),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FCM] Token refresh error: $error\n$stackTrace');
      },
    );
    _initialized = true;
  }

  /// Configures permission-scoped topics for the active tenant.
  Future<void> configureTopics({
    required String? businessId,
    required bool mayViewStockLevels,
    required bool mayManageBilling,
  }) async {
    await initialize();
    if (!_isSupported) return;

    final messaging = _messaging!;
    final lowStockTarget = businessId != null && mayViewStockLevels
        ? lowStockTopic(businessId)
        : null;
    final planAlertsTarget = businessId != null && mayManageBilling
        ? planAlertsTopic(businessId)
        : null;

    _subscribedLowStockTopic = await _replaceTopic(
      messaging: messaging,
      current: _subscribedLowStockTopic,
      target: lowStockTarget,
    );
    _subscribedPlanAlertsTopic = await _replaceTopic(
      messaging: messaging,
      current: _subscribedPlanAlertsTopic,
      target: planAlertsTarget,
    );
  }

  Future<String?> _replaceTopic({
    required FirebaseMessaging messaging,
    required String? current,
    required String? target,
  }) async {
    if (current == target) return current;
    if (current != null) {
      await messaging.unsubscribeFromTopic(current);
    }
    if (target != null) {
      await messaging.subscribeToTopic(target);
    }
    return target;
  }

  Future<void> _resubscribeCurrentTopics() async {
    final messaging = _messaging;
    if (messaging == null) return;
    for (final topic in [
      _subscribedLowStockTopic,
      _subscribedPlanAlertsTopic,
    ]) {
      if (topic != null) await messaging.subscribeToTopic(topic);
    }
  }

  Future<void> clear() => configureTopics(
    businessId: null,
    mayViewStockLevels: false,
    mayManageBilling: false,
  );

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final localNotifications = _localNotifications;
    if (localNotifications == null) return;

    final isPlanAlert = message.data['type'] == 'plan_limit';
    final notification = message.notification;
    final title =
        notification?.title ??
        (isPlanAlert ? 'Plan limit reached' : 'Low stock alert');
    final body =
        notification?.body ??
        message.data['body'] ??
        (isPlanAlert
            ? 'A business resource has reached its plan limit.'
            : 'An item has reached its reorder level.');
    final channel = isPlanAlert ? _planAlertsChannel : _lowStockChannel;
    await localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
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
    await _tokenRefreshSubscription?.cancel();
    _foregroundSubscription = null;
    _tokenRefreshSubscription = null;
    _initialized = false;
  }
}
