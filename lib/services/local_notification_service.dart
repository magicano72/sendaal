import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/router/app_router.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  LocalNotificationService.handleNotificationTap(response.payload);
}

class LocalNotificationService {
  LocalNotificationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sendaal_general',
    'Sendaal Notifications',
    description: 'General notifications for Sendaal users',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android channel setup
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      id.hashCode & 0x7fffffff,
      title,
      body,
      details,
      payload: payload ?? id,
    );
  }

  static void handleNotificationTap(String? payload) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamed(AppRoutes.notifications);
  }
}
