import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
// Shadow helper removed; using standard outline for compatibility.

/// Reusable, modern InputDecoration for dropdown fields.
InputDecoration dropdownDecoration({
  required String label,
  Color? backgroundColor,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
}) {
  final fill = backgroundColor ?? AppTheme.surface;
  final radius = BorderRadius.circular(12.r);

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyles.labelBold.copyWith(color: AppTheme.textSecondary),
    floatingLabelStyle: TextStyles.labelBold.copyWith(color: AppTheme.primary),
    filled: true,
    fillColor: fill,
    hoverColor: fill.withOpacity(0.94),
    contentPadding:
        contentPadding ??
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    suffixIcon:
        suffixIcon ??
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textSecondary,
        ),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.error, width: 1.2),
    ),
  );
}
