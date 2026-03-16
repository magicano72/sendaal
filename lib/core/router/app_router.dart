import 'package:Sendaal/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

import '../../core/models/index.dart' hide AccessRequest;
import '../../models/access_request_model.dart';
import '../../screens/accounts/accounts_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/contacts/contact_details_screen.dart';
import '../../screens/contacts/device_contacts_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/edit_account_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/recipient/recipient_screen.dart';
import '../../screens/requests/all_requests_screen.dart';
import '../../screens/requests/requester_details_screen.dart';
import '../../screens/transfer/transfer_screen.dart';
import '../../screens/transfer/transfer_success_screen.dart';

/// Named route constants — avoids magic strings throughout the app
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String accounts = '/accounts';
  static const String profile = '/profile';
  static const String editAccount = '/edit-account';
  static const String search = '/search';
  static const String recipient = '/recipient';
  static const String transfer = '/transfer';
  static const String transferSuccess = '/transfer-success';
  static const String notifications = '/notifications';
  static const String deviceContacts = '/device-contacts';
  static const String contactDetails = '/contact-details';
  static const String requesterDetails = '/requester-details';
  // Backwards-compatible alias
  static const String allAccessRequests = '/all-requests';
  static const String allRequests = '/all-requests';
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
      case AppRoutes.accounts:
        return _fade(const AccountsScreen());
      case AppRoutes.profile:
        return _fade(const ProfileScreen());
      case AppRoutes.editAccount:
        final account = settings.arguments as FinancialAccount;
        return _fade(EditAccountScreen(account: account));
      case AppRoutes.search:
        return _fade(const HomeScreen());
      case AppRoutes.recipient:
        final user = settings.arguments as User;
        return _fade(RecipientScreen(recipient: user));
      case AppRoutes.transfer:
        final args = settings.arguments as TransferArgs;
        return _fade(TransferScreen(args: args));
      case AppRoutes.transferSuccess:
        return _fade(const TransferSuccessScreen());
      case AppRoutes.notifications:
        return _fade(const NotificationsScreen());
      case AppRoutes.requesterDetails:
        final request = settings.arguments as AccessRequest;
        return _fade(RequesterDetailsScreen(request: request));
      case AppRoutes.allAccessRequests:
      case AppRoutes.allRequests:
        return _fade(const AllRequestsScreen());
      case AppRoutes.deviceContacts:
        return _fade(const DeviceContactsScreen());
      case AppRoutes.contactDetails:
        final user = settings.arguments as User;
        return _fade(ContactDetailsScreen(contact: user));
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
