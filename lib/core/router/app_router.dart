import 'package:flutter/material.dart';

import '../../core/models/index.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/recipient/recipient_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/transfer/transfer_screen.dart';

/// Named route constants — avoids magic strings throughout the app
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String recipient = '/recipient';
  static const String transfer = '/transfer';
  static const String notifications = '/notifications';
}

/// Central router configuration.
/// Uses a simple named-route strategy with Navigator 1.0 style routing.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _fade(const LoginScreen());
      case AppRoutes.register:
        return _fade(const RegisterScreen());
      case AppRoutes.home:
        return _fade(const MainShell());
      case AppRoutes.profile:
        return _fade(const ProfileScreen());
      case AppRoutes.search:
        return _fade(const SearchScreen());
      case AppRoutes.recipient:
        final user = settings.arguments as User;
        return _fade(RecipientScreen(recipient: user));
      case AppRoutes.transfer:
        final args = settings.arguments as TransferArgs;
        return _fade(TransferScreen(args: args));
      case AppRoutes.notifications:
        return _fade(const NotificationsScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 220),
  );
}

/// Arguments bundle for the Transfer screen
class TransferArgs {
  final User recipient;
  final List<SplitSuggestion> suggestions;
  final List<FinancialAccount> accounts;

  const TransferArgs({
    required this.recipient,
    required this.suggestions,
    required this.accounts,
  });
}
