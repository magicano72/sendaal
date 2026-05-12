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
  static const warning = Color(0xFFF59E0B);
}

class AppPalette {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.error,
    required this.border,
    required this.divider,
    required this.warning,
    required this.navIndicator,
    required this.hover,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color error;
  final Color border;
  final Color divider;
  final Color warning;
  final Color navIndicator;
  final Color hover;
}

class AppPalettes {
  AppPalettes._();

  static const light = AppPalette(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    success: AppColors.success,
    error: AppColors.error,
    border: AppColors.border,
    divider: AppColors.divider,
    warning: AppColors.warning,
    navIndicator: Color(0xFFE7F0FF),
    hover: AppColors.secondary,
  );

  static const dark = AppPalette(
    primary: Color(0xFF5EA8FF),
    secondary: Color(0xFF121A42),
    background: Color(0xFF0C102F),
    surface: Color(0xFF12183A),
    surfaceElevated: Color(0xFF18204A),
    textPrimary: Color(0xFFF7FAFF),
    textSecondary: Color(0xFFA8B3CF),
    success: Color(0xFF35D399),
    error: Color(0xFFFF6B7A),
    border: Color(0xFF263057),
    divider: Color(0xFF20294E),
    warning: Color(0xFFFFC46B),
    navIndicator: Color(0xFF203561),
    hover: Color(0xFF1A2552),
  );
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

  static AppPalette _activePalette = AppPalettes.light;

  static AppPalette get colors => _activePalette;
  static bool get isDark => identical(_activePalette, AppPalettes.dark);

  static void setActiveBrightness(Brightness brightness) {
    _activePalette =
        brightness == Brightness.dark ? AppPalettes.dark : AppPalettes.light;
  }

  // Backwards compatibility for existing references
  static Color get primary => colors.primary;
  static Color get secondary => colors.secondary;
  static Color get background => colors.background;
  static Color get surface => colors.surface;
  static Color get surfaceElevated => colors.surfaceElevated;
  static Color get accent => colors.primary; // legacy alias
  static Color get textPrimary => colors.textPrimary;
  static Color get textSecondary => colors.textSecondary;
  static Color get success => colors.success;
  static Color get error => colors.error;
  static Color get divider => colors.divider;
  static Color get border => colors.border;
  static Color get warning => colors.warning;

  static Color get primaryColor => primary;
  static Color get accentColor => accent;
  static Color get errorColor => error;
  static Color get warningColor => warning;
  static Color get successColor => success;
  static Color get backgroundColor => background;
  static Color get surfaceColor => surface;
  static Color get textPrimaryColor => textPrimary;
  static Color get textSecondaryColor => textSecondary;
  static Color get borderColor => border;
  static Color get dividerColor => divider;

  static ThemeData get lightTheme {
    return buildTheme(palette: AppPalettes.light, brightness: Brightness.light);
  }

  static ThemeData buildTheme({
    required AppPalette palette,
    required Brightness brightness,
  }) {
    final radius = 12.r;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        secondary: palette.secondary,
        background: palette.background,
        surface: palette.surface,
        error: palette.error,
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: TextTheme(
        displayLarge: TextStyles.h1Bold.copyWith(color: palette.textPrimary),
        headlineMedium: TextStyles.h2Semi.copyWith(color: palette.textPrimary),
        bodyLarge: TextStyles.bodyRegular.copyWith(color: palette.textPrimary),
        bodyMedium: TextStyles.bodySmall.copyWith(color: palette.textPrimary),
        labelSmall: TextStyles.captionRegular.copyWith(
          color: palette.textSecondary,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isDark ? Colors.black.withOpacity(0.25) : null,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyles.h2Medium.copyWith(
          color: palette.textPrimary,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: TextStyles.bodyRegular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shadowColor: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
          elevation: isDark ? 1 : 3,
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
          textStyle: TextStyles.bodyRegular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shadowColor: Colors.black.withOpacity(0.05),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.primary, width: 1.5.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.error),
        ),
        hintStyle: TextStyles.bodySmall.copyWith(
          color: palette.textSecondary,
        ),
        labelStyle: TextStyles.bodySmall.copyWith(
          color: palette.textSecondary,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.primary,
        selectionColor: palette.primary.withOpacity(isDark ? 0.32 : 0.22),
        selectionHandleColor: palette.primary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: palette.surface,
          hintStyle: TextStyles.bodySmall.copyWith(
            color: palette.textSecondary,
          ),
          labelStyle: TextStyles.bodySmall.copyWith(
            color: palette.textSecondary,
          ),
        ),
        textStyle: TextStyles.bodySmall.copyWith(color: palette.textPrimary),
        menuStyle: MenuStyle(
          backgroundColor: MaterialStateProperty.all(palette.surfaceElevated),
          surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: isDark ? 0 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: palette.border),
        ),
        shadowColor: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyles.h2Medium.copyWith(
          color: palette.textPrimary,
        ),
        contentTextStyle: TextStyles.bodySmall.copyWith(
          color: palette.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        selectedColor: palette.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.navIndicator,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyles.labelBold.copyWith(
            color: isSelected ? palette.primary : palette.textSecondary,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected ? palette.primary : palette.textSecondary,
            size: 24,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isDark ? palette.textPrimary : Colors.white;
          }
          return palette.textSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return palette.primary.withOpacity(isDark ? 0.42 : 0.5);
          }
          return palette.border;
        }),
      ),
    );
  }
}
