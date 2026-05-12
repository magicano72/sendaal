import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart' as design;

class AppTheme {
  // Colors
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _accentColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _warningColor = Color(0xFFFB923C);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimaryColor = Color(0xFF1F2937);
  static const Color _textSecondaryColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _dividerColor = Color(0xFFF3F4F6);

  static Color get primaryColor =>
      design.AppTheme.isDark ? design.AppTheme.primary : _primaryColor;
  static Color get primaryDark =>
      design.AppTheme.isDark ? design.AppTheme.primary : _primaryDark;
  static Color get accentColor =>
      design.AppTheme.isDark ? design.AppTheme.accent : _accentColor;
  static Color get errorColor =>
      design.AppTheme.isDark ? design.AppTheme.error : _errorColor;
  static Color get warningColor =>
      design.AppTheme.isDark ? design.AppTheme.warning : _warningColor;
  static Color get successColor =>
      design.AppTheme.isDark ? design.AppTheme.success : _successColor;
  static Color get backgroundColor =>
      design.AppTheme.isDark ? design.AppTheme.background : _backgroundColor;
  static Color get surfaceColor =>
      design.AppTheme.isDark ? design.AppTheme.surface : _surfaceColor;
  static Color get textPrimaryColor =>
      design.AppTheme.isDark ? design.AppTheme.textPrimary : _textPrimaryColor;
  static Color get textSecondaryColor => design.AppTheme.isDark
      ? design.AppTheme.textSecondary
      : _textSecondaryColor;
  static Color get borderColor =>
      design.AppTheme.isDark ? design.AppTheme.border : _borderColor;
  static Color get dividerColor =>
      design.AppTheme.isDark ? design.AppTheme.divider : _dividerColor;

  // Compatibility aliases for widgets that use the newer centralized names.
  static Color get primary => primaryColor;
  static Color get secondary =>
      design.AppTheme.isDark ? design.AppTheme.secondary : _dividerColor;
  static Color get background => backgroundColor;
  static Color get surface => surfaceColor;
  static Color get surfaceElevated =>
      design.AppTheme.isDark ? design.AppTheme.surfaceElevated : _surfaceColor;
  static Color get accent => accentColor;
  static Color get textPrimary => textPrimaryColor;
  static Color get textSecondary => textSecondaryColor;
  static Color get success => successColor;
  static Color get error => errorColor;
  static Color get divider => dividerColor;
  static Color get border => borderColor;
  static Color get warning => warningColor;

  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: surfaceColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: md, vertical: md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: md, vertical: md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        side: BorderSide(color: primaryColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dividerColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: errorColor),
      ),
      hintStyle: GoogleFonts.poppins(color: textSecondaryColor, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      color: surfaceColor,
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: md,
    ),
  );
}
