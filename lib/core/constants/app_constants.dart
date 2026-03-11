/// App-wide constants for Sendaal

class AppConstants {
  AppConstants._();

  // ── Account type limits (used in Smart Split algorithm) ───────────────────
  static const Map<String, double> accountTypeLimits = {
    'instapay': 50000,
    'digital_wallet': 30000,
    'bank_account': 100000,
    'telda': 20000,
    'other': 10000,
  };

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
