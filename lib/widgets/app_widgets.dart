import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/models/notification_model.dart' as notification_model;
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PrimaryButton
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Full-width primary action button with optional loading state
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5.w,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                  Text(
                    label,
                    style: TextStyles.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SearchField
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hint;
  final VoidCallback? onContactsTap;

  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hint = 'Search by username or phone...',
    this.onContactsTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onContactsTap != null)
                  IconButton(
                    icon: const Icon(Icons.contacts, color: AppTheme.primary),
                    onPressed: onContactsTap,
                  ),
                if (hasText)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primary),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NotificationTile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotificationTile extends StatelessWidget {
  final notification_model.Notification notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppTheme.surface
              : AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification type icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: _typeColor(notification.type).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _typeIcon(notification.type),
                color: _typeColor(notification.type),
                size: 18.r,
              ),
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style:
                        (notification.isRead
                                ? TextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  )
                                : TextStyles.bodySmallBold)
                            .copyWith(color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    notification.body,
                    style: TextStyles.label.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead)
              Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.only(top: 4.h),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'access_request':
        return Icons.person_add_outlined;
      case 'access_approved':
        return Icons.check_circle_outline;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'access_request':
        return AppTheme.primary;
      case 'access_approved':
        return AppTheme.success;
      case 'system':
        return AppTheme.accent;
      default:
        return AppTheme.primary;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AmountInputField
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String currency;

  const AmountInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.currency = 'EGP',
  });

  @override
  Widget build(BuildContext context) {
    final displayCurrency = currency.isNotEmpty ? currency : 'EGP';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount ($displayCurrency)',
          style: TextStyles.bodySmallBold.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: TextStyles.h1Bold.copyWith(
            fontSize: 28.sp,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '$displayCurrency  ',
            prefixStyle: TextStyles.bodyRegular.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            errorText: errorText,
            hintText: '0.00',
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EmptyState
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.r, color: AppTheme.primary),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyles.bodyBold.copyWith(
                fontSize: 17.sp,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: TextStyles.bodySmallBold.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UserTile — compact user list item
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class UserTile extends StatelessWidget {
  final String displayName;
  final String username;
  final String? profileImage;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.displayName,
    required this.username,
    this.profileImage,
    this.onTap,
  });

  ImageProvider<Object>? _buildAvatarProvider() {
    if (profileImage == null || profileImage!.isEmpty) return null;
    final uri = Uri.tryParse(profileImage!);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return NetworkImage(profileImage!);
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _buildAvatarProvider();

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
      leading: CircleAvatar(
        radius: 24.r,
        backgroundColor: AppTheme.primary.withOpacity(0.1),
        backgroundImage: avatarProvider,
        child: avatarProvider == null
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyles.bodyBold.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              )
            : null,
      ),
      title: Text(displayName, style: TextStyles.bodySmallBold),
      subtitle: Text(
        '@$username',
        style: TextStyles.label.copyWith(color: AppTheme.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.primary, size: 20.r),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━═══
// ErrorBanner
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: TextStyles.bodySmallBold),
            ),
        ],
      ),
    );
  }
}
