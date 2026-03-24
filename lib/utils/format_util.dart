import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _displayDatePattern = 'dd MMM yyyy hh:mm a';

/// String formatting and parsing utilities
class FormatUtils {
  /// Shared display pattern: "30 Mar 2026 02:55 PM"
  static const displayPattern = _displayDatePattern;

  /// Format currency value with commas
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  /// Format currency without decimals
  static String formatCurrencyInt(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return phone;

    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  /// Format date to the shared display pattern
  static String formatDate(DateTime date) {
    return DateFormat(_displayDatePattern).format(date);
  }

  /// Format time to the shared display pattern
  static String formatTime(DateTime dateTime) {
    return DateFormat(_displayDatePattern).format(dateTime);
  }

  /// Format date and time to the shared display pattern
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(_displayDatePattern).format(dateTime);
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Replace underscores with spaces and capitalize
  static String formatLabel(String label) {
    return capitalize(label.replaceAll('_', ' '));
  }
}

/// Validation utilities
class ValidationUtils {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\d{10,}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\D'), ''));
  }

  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  static bool isValidUsername(String username) {
    return username.length >= 3 && username.length <= 20;
  }

  static bool isValidAmount(double amount) {
    return amount > 0;
  }
}

/// Device utilities
class DeviceUtils {
  static bool get isMobile => true; // Placeholder

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
}
