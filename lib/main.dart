import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

/// Entry point — loads .env before running the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
    // ProviderScope wraps the entire app for Riverpod
    const ProviderScope(child: SendaalApp()),
  );
}

class SendaalApp extends StatelessWidget {
  const SendaalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sendaal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.login,
    );
  }
}
