import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';

/// Centralized SnackBar helper — use instead of ScaffoldMessenger directly
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bg = AppTheme.textPrimary;
    if (isError) bg = AppTheme.error;
    if (isSuccess) bg = AppTheme.success;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyles.label.copyWith(color: Colors.white),
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
        ),
      );
  }

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);

  static void success(BuildContext context, String message) =>
      show(context, message, isSuccess: true);
}
