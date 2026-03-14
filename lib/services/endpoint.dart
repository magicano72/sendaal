/// All Directus API endpoint paths in one place.
/// If a path changes, update it here only.
class Endpoints {
  Endpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/users';

  // ── Users ─────────────────────────────────────────────────────────────────
  static const String users = '/users';
  static const String currentUser = '/users/me';
  static String userById(String id) => '/users/$id';

  // ── Financial Accounts ────────────────────────────────────────────────────
  static const String financialAccounts = '/items/financial_accounts';
  static const String systemLimits = '/items/system_limits';

  // ── Access Requests ───────────────────────────────────────────────────────
  static const String accessRequests = '/items/access_requests';
  static String accessRequestById(String id) => '/items/access_requests/$id';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/items/notifications';
  static String notificationById(String id) => '/items/notifications/$id';
}
