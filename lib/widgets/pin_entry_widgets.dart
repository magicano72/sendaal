import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';

class PinDots extends StatelessWidget {
  final int length;
  final int filled;

  const PinDots({
    super.key,
    required this.length,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: 18.r,
          height: 18.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : Colors.white,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.border,
              width: 1.8,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  final VoidCallback? onBiometricPressed;
  final ValueChanged<String> onNumberPressed;
  final VoidCallback onDeletePressed;
  final bool showBiometricButton;

  const PinKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometricButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];

    return Column(
      children: [
        Wrap(
          spacing: 18.w,
          runSpacing: 18.h,
          alignment: WrapAlignment.center,
          children: labels
              .map(
                (label) => _PinKey(
                  label: label,
                  onTap: () => onNumberPressed(label),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 18.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionKey(
              icon: Icons.fingerprint_rounded,
              visible: showBiometricButton,
              onTap: onBiometricPressed,
            ),
            SizedBox(width: 18.w),
            _PinKey(label: '0', onTap: () => onNumberPressed('0')),
            SizedBox(width: 18.w),
            _ActionKey(
              icon: Icons.backspace_outlined,
              visible: true,
              onTap: onDeletePressed,
            ),
          ],
        ),
      ],
    );
  }
}

class PinScreenScaffold extends StatelessWidget {
  final Widget child;

  const PinScreenScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFD), Color(0xFFEFF4FA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 420.w),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const PinSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyles.h1Semi.copyWith(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84.w,
      height: 72.h,
      child: Material(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(22.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyles.h2Semi.copyWith(
                fontSize: 30.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool visible;

  const _ActionKey({
    required this.icon,
    required this.onTap,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84.w,
      height: 72.h,
      child: visible
          ? Material(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(22.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(22.r),
                onTap: onTap,
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 30.r,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
