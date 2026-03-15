import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'text_style.dart';

/// Sendaal App Theme built from design tokens (colors, spacing, typography).
class AppColors {
  static const primary = Color(0xFF1773CF);
  static const secondary = Color(0xFFF0F7FF);
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFE5E7EB);
}

class AppSpacing {
  // Base spacing unit = 4px
  static double get unit => 4.w;
  static double get x1 => unit;
  static double get x2 => 2 * unit;
  static double get x3 => 3 * unit;
  static double get x4 => 4 * unit; // 16px
  static double get x5 => 5 * unit;
  static double get x6 => 6 * unit; // 24px
}

class AppTheme {
  AppTheme._();

  // Backwards compatibility for existing references
  static const primary = AppColors.primary;
  static const secondary = AppColors.secondary;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const accent = AppColors.primary; // legacy alias
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const success = AppColors.success;
  static const error = AppColors.error;
  static const divider = AppColors.divider;
  static const border = AppColors.border;

  static ThemeData get lightTheme {
    final radius = 12.r;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: TextStyles.h1Bold,
        headlineMedium: TextStyles.h2Semi,
        bodyLarge: TextStyles.bodyRegular,
        bodyMedium: TextStyles.bodySmall,
        labelSmall: TextStyles.captionRegular,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyles.h2Medium.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: TextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          shadowColor: Colors.black.withOpacity(0.05),
          elevation: 3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          textStyle: TextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          shadowColor: Colors.black.withOpacity(0.05),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        labelStyle: TextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.border),
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
