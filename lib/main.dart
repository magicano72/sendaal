import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'services/local_notification_service.dart';
import 'services/system_limits_service.dart';
import 'widgets/connectivity_banner.dart';

/// Entry point — loads .env before running the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await LocalNotificationService.initialize();
  await SystemLimitsService().loadAndCache();
  runApp(
    // ProviderScope wraps the entire app for Riverpod
    const ProviderScope(child: SendaalApp()),
  );
}

class SendaalApp extends StatefulWidget {
  const SendaalApp({super.key});

  @override
  State<SendaalApp> createState() => _SendaalAppState();
}

class _SendaalAppState extends State<SendaalApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle app launch via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      print('[DeepLinks] Failed to process initial link: $e');
    }

    // Listen for links while the app is in foreground/background
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (err) => print('[DeepLinks] Stream error: $err'),
    );
  }

  void _handleUri(Uri uri) {
    final isCustomScheme =
        uri.scheme == 'sendaal' && uri.host == 'reset-password';
    final isHttpsReset = uri.scheme == 'https' &&
        uri.host == 'sendaal-directus.csiwm3.easypanel.host' &&
        uri.path.startsWith('/reset-password');
    if (!isCustomScheme && !isHttpsReset) return;
    final token = uri.queryParameters['token'];
    Future.microtask(() {
      final nav = LocalNotificationService.navigatorKey.currentState;
      if (nav == null) return;
      nav.pushNamed(AppRoutes.resetPassword, arguments: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Sendaal',
          debugShowCheckedModeBanner: false,
          navigatorKey: LocalNotificationService.navigatorKey,
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRoutes.login,
          builder: (context, child) =>
              ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
