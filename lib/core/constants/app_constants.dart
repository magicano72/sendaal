/// App-wide constants for Sendaal

class AppConstants {
  AppConstants._();

  // ── Account type limits (used in Smart Split algorithm) ───────────────────
  static Map<String, double> accountTypeLimits = const {};

  /// Replace the in-memory limits with values fetched from the backend.
  static void updateAccountTypeLimits(Map<String, double> limits) {
    if (limits.isNotEmpty) {
      accountTypeLimits = Map.unmodifiable(limits);
    }
  }

  /// Helper to read a limit with automatic fallback.
  static double limitForAccountType(String type) {
    final key = type.toLowerCase();
    return accountTypeLimits[key] ?? 0;
  }

  /// Display label for dynamic account types with sensible fallbacks.
  static String displayLabel(String type) {
    final key = type.toLowerCase();
    final known = accountTypeLabels[key];
    if (known != null) return known;

    // Fallback: title-case the key and replace underscores with spaces.
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }

  // ── Account type display labels ───────────────────────────────────────────
  static const Map<String, String> accountTypeLabels = {
    'instapay': 'InstaPay',
    'digital_wallet': 'Digital Wallet',
    'bank_account': 'Bank Account',
    'telda': 'Telda',
    'other': 'Other',
  };

  // ── Account type icons (Material icon codepoints as strings) ─────────────
  static const Map<String, String> accountTypeIcons = {
    'instapay': 'flash_on',
    'digital_wallet': 'digital_wallet',
    'bank_account': 'account_balance',
    'telda': 'credit_card',
    'other': 'payment',
  };

  // ── Notification types ────────────────────────────────────────────────────
  static const String notifAccessRequest = 'access_request';
  static const String notifAccessApproved = 'access_approved';
  static const String notifSystem = 'system';

  // ── Access request statuses ───────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
}
