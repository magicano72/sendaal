import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/router/app_router.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  LocalNotificationService.handleNotificationTap(response.payload);
}

class LocalNotificationService {
  LocalNotificationService._();

  static const String _androidLargeIconAsset = 'assets/images/app-logo.png';

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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final hasPermission = await _ensureNotificationPermission();
    if (!hasPermission) return;
    final largeIcon = await _loadAndroidLargeIcon();

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: largeIcon,
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

  static Future<AndroidBitmap<Object>?> _loadAndroidLargeIcon() async {
    try {
      final data = await rootBundle.load(_androidLargeIconAsset);
      return ByteArrayAndroidBitmap(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static void handleNotificationTap(String? payload) {
    Future<void>.microtask(() async {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      if (ApiClient.instance.hasToken) {
        navigator.pushNamed(AppRoutes.notifications);
        return;
      }

      navigator.pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    });
  }

  static Future<bool> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showNotificationSettingsPrompt();
      return false;
    }

    final proceed = await _showNotificationRationale();
    if (!proceed) return false;

    final result = await Permission.notification.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied || result.isRestricted) {
      await _showNotificationSettingsPrompt();
    }
    return false;
  }

  static Future<bool> _showNotificationRationale() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return true;
    final result = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Allow notifications'),
        content: const Text(
          'Turn on notifications to get updates about activity on your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _showNotificationSettingsPrompt() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final goToSettings = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Enable notifications in Settings'),
        content: const Text(
          'Notifications are blocked. Open Settings to allow notifications for Sendaal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (goToSettings == true) {
      await openAppSettings();
    }
  }
}
