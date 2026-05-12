import 'package:Sendaal/core/theme/app_theme.dart';
import 'package:Sendaal/core/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          backgroundColor: backgroundColor ?? AppTheme.textPrimary,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppTheme.error,
      icon: Icons.error_outline,
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppTheme.success,
      icon: Icons.check_circle_outline,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppTheme.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppTheme.primary,
      icon: Icons.info_outline,
    );
  }
}
