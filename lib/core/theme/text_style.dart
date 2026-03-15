// lib/core/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyles {
  static TextStyle _inter(double size, FontWeight weight, double height) =>
      GoogleFonts.inter(fontSize: size.sp, fontWeight: weight, height: height);

  // Headings
  static TextStyle h1Bold = _inter(32, FontWeight.w700, 1.2);
  static TextStyle h1Semi = _inter(28, FontWeight.w600, 1.25);

  // Subheadings
  static TextStyle h2Semi = _inter(24, FontWeight.w600, 1.25);
  static TextStyle h2Medium = _inter(20, FontWeight.w600, 1.3);

  // Body
  static TextStyle bodyRegular = _inter(16, FontWeight.w400, 1.4);
  static TextStyle bodySmall = _inter(14, FontWeight.w400, 1.4);

  // Caption / Small
  static TextStyle captionRegular = _inter(12, FontWeight.w400, 1.35);
  static TextStyle captionMedium = _inter(12, FontWeight.w500, 1.35);
}
