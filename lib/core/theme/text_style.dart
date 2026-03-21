// lib/core/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography tokens for the app.
/// Use these instead of creating new `TextStyle` instances.
class TextStyles {
  static TextStyle _inter(double size, FontWeight weight, double height) =>
      GoogleFonts.inter(fontSize: size.sp, fontWeight: weight, height: height);

  // Headings
  static final TextStyle h1Bold = _inter(32, FontWeight.w700, 1.2);
  static final TextStyle h1Semi = _inter(28, FontWeight.w600, 1.25);
  static final TextStyle h2Semi = _inter(24, FontWeight.w600, 1.25);
  static final TextStyle h2Medium = _inter(20, FontWeight.w600, 1.3);

  // Body
  static final TextStyle bodyLarge = _inter(18, FontWeight.w400, 1.45);
  static final TextStyle bodyRegular = _inter(16, FontWeight.w400, 1.4);
  static final TextStyle bodyBold = _inter(16, FontWeight.w600, 1.4);
  static final TextStyle bodySmall = _inter(14, FontWeight.w400, 1.35);
  static final TextStyle bodySmallBold = _inter(14, FontWeight.w600, 1.35);

  // Labels / Buttons
  static final TextStyle label = _inter(13, FontWeight.w500, 1.3);
  static final TextStyle labelBold = _inter(13, FontWeight.w700, 1.3);
  static final TextStyle button = _inter(15, FontWeight.w600, 1.25);

  // Caption / Helper
  static final TextStyle captionRegular = _inter(12, FontWeight.w400, 1.3);
  static final TextStyle captionMedium = _inter(12, FontWeight.w500, 1.3);
  static final TextStyle captionBold = _inter(12, FontWeight.w600, 1.3);

  /// Apply color depending on theme brightness (light if [dark] is null).
  static TextStyle themedColor(
    BuildContext context, {
    required Color light,
    Color? dark,
    TextStyle base = const TextStyle(),
  }) {
    final brightness = Theme.of(context).brightness;
    return base.copyWith(color: brightness == Brightness.dark ? dark ?? light : light);
  }

  /// Convenience to change only the color of a base style.
  static TextStyle colored(TextStyle style, Color color) => style.copyWith(color: color);

  /// Scale a base style by [factor] (useful for responsive tweaks).
  static TextStyle scaled(TextStyle style, double factor) =>
      style.copyWith(fontSize: (style.fontSize ?? 14) * factor);
}
