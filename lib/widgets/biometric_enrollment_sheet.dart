import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../widgets/app_widgets.dart';

/// Biometric enrollment prompt after PIN setup
/// Shows user the benefits of biometric login and offers enable/skip
class BiometricEnrollmentBottomSheet extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback onSkip;
  final bool isLoading;

  const BiometricEnrollmentBottomSheet({
    super.key,
    required this.onEnable,
    required this.onSkip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle ──────────────────────────────────────────────────────
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),

                // ── Icon ─────────────────────────────────────────────────────────
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 40.w,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(height: 20.h),

                // ── Title ────────────────────────────────────────────────────────
                Text(
                  'Enable biometric login?',
                  style: TextStyles.h2Semi.copyWith(
                    fontSize: 22.sp,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),

                // ── Description ─────────────────────────────────────────────────
                Text(
                  'Use your fingerprint or face to quickly access your account. Your biometric data stays secure on your device.',
                  style: TextStyles.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // ── Benefits ─────────────────────────────────────────────────────
                _BenefitItem(
                  icon: Icons.speed,
                  title: 'Faster access',
                  subtitle: 'Log in instantly without entering your PIN',
                ),
                SizedBox(height: 12.h),
                _BenefitItem(
                  icon: Icons.security,
                  title: 'Secure',
                  subtitle: 'Your device handles all biometric verification',
                ),
                SizedBox(height: 24.h),

                // ── Buttons ──────────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Enable biometric',
                    onPressed: isLoading ? null : onEnable,
                    isLoading: isLoading,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'Not now',
                    onPressed: isLoading ? null : onSkip,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Benefit item with icon and text
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24.w, color: AppTheme.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyBold.copyWith(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyles.captionRegular.copyWith(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
