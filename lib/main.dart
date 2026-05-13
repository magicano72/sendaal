import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/local_notification_service.dart';
import 'services/system_limits_service.dart';
import 'widgets/app_lifecycle_observer.dart';
import 'widgets/connectivity_banner.dart';

/// Entry point — loads .env before running the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  await _loadEnvironment();
  await _initializeLocalNotifications();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope wraps the entire app for Riverpod
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const SendaalApp(),
    ),
  );

  unawaited(_warmSystemLimits());
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, st) {
    debugPrint('[Startup] Failed to load .env: $e');
    debugPrintStack(stackTrace: st);
  }
}

Future<void> _initializeLocalNotifications() async {
  try {
    await LocalNotificationService.initialize();
  } catch (e, st) {
    debugPrint('[Startup] Failed to initialize notifications: $e');
    debugPrintStack(stackTrace: st);
  }
}

Future<void> _warmSystemLimits() async {
  try {
    await SystemLimitsService().loadAndCache();
  } catch (e, st) {
    debugPrint('[Startup] Failed to warm system limits: $e');
    debugPrintStack(stackTrace: st);
  }
}

class SendaalApp extends ConsumerStatefulWidget {
  const SendaalApp({super.key});

  @override
  ConsumerState<SendaalApp> createState() => _SendaalAppState();
}

class _SendaalAppState extends ConsumerState<SendaalApp>
    with WidgetsBindingObserver {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  Future<void> _initDeepLinks() async {
    // Handle app launch via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLinks] Failed to process initial link: $e');
    }

    // Listen for links while the app is in foreground/background
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (err) => debugPrint('[DeepLinks] Stream error: $err'),
    );
  }

  void _handleUri(Uri uri) {
    final isCustomScheme =
        uri.scheme == 'sendaal' && uri.host == 'reset-password';
    final isHttpsReset =
        uri.scheme == 'https' &&
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
    final appThemeMode = ref.watch(themeModeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final effectiveBrightness = switch (appThemeMode) {
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.system => platformBrightness,
    };

    AppTheme.setActiveBrightness(effectiveBrightness);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AppLifecycleObserver(
          child: MaterialApp(
            title: 'Sendaal',
            debugShowCheckedModeBanner: false,
            navigatorKey: LocalNotificationService.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: buildDarkTheme(),
            themeMode: appThemeMode.materialMode,
            themeAnimationDuration: const Duration(milliseconds: 280),
            themeAnimationCurve: Curves.easeOutCubic,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRoutes.splash,
            builder: (context, child) => ConnectivityBanner(
              child: KeyedSubtree(
                key: ValueKey(
                  '${appThemeMode.storageValue}-${effectiveBrightness.name}',
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
