/// All Directus API endpoint paths in one place.
/// If a path changes, update it here only.
class Endpoints {
  Endpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/users';

  // Users
  static const String users = '/users';
  static const String currentUser = '/users/me';
  static String userById(String id) => '/users/$id';

  // Financial Accounts
  static const String financialAccounts = '/items/financial_accounts';
  static const String systemLimits = '/items/system_limits';
  static const String countries = '/items/countries';
  static const String providerAvailability = '/items/provider_availability';

  // Access Requests
  static const String accessRequests = '/items/access_requests';
  static String accessRequestById(String id) => '/items/access_requests/$id';
  static const String accessRequestAccounts = '/items/access_request_accounts';

  // Notifications
  static const String notifications = '/items/notifications';
  static String notificationById(String id) => '/items/notifications/$id';

  // Phone number verification (Directus extension)
  static const String phoneValidatorBase = '/phone-number-validator';
  static const String requestPhoneVerification =
      '$phoneValidatorBase/request-verification';
  static const String verifyPhoneOtp = '$phoneValidatorBase/verify-otp';
  static const String resendPhoneOtp = '$phoneValidatorBase/resend-otp';
  static const String phoneVerificationStatus = '$phoneValidatorBase/status';

  // Password reset
  static const String requestPasswordReset = '/auth/password/request';
  static const String resetPassword = '/auth/password/reset';
}
