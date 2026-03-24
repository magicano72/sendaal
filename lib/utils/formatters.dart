import 'package:intl/intl.dart';

/// Shared formatting helpers used across the app
class Formatters {
  Formatters._();

  static final _currency =
      NumberFormat.currency(locale: 'ar_EG', symbol: 'EGP ', decimalDigits: 0);

  static final _shortCurrency =
      NumberFormat.compactCurrency(locale: 'en', symbol: '');

  /// Format a number as EGP currency: "EGP 50,000"
  static String currency(double amount) => _currency.format(amount);

  /// Format a number compactly: "50K", "1.2M"
  static String compact(double amount) => _shortCurrency.format(amount).trim();

  /// Format a DateTime as a relative time string: "2 hours ago", "Yesterday"
  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy hh:mm a').format(dt);
  }
}
