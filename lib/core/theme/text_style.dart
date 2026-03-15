// lib/core/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextStyles {
  static const _fontFamily = 'Inter';

  // Headings
  static TextStyle h1Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static TextStyle h1Semi = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  // Subheadings
  static TextStyle h2Semi = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static TextStyle h2Medium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body
  static TextStyle bodyRegular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Caption / Small
  static TextStyle captionRegular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static TextStyle captionMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );
}
