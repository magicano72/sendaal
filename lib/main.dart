import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/local_notification_service.dart';
import 'services/system_limits_service.dart';
import 'screens/auth/login_screen.dart';
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

class SendaalApp extends StatelessWidget {
  const SendaalApp({super.key});

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
          builder: (context, child) => ConnectivityBanner(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
