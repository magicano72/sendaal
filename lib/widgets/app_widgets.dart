import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/constants/app_constants.dart';
import '../core/models/notification_model.dart' as notification_model;
import '../core/theme/app_theme.dart';
import '../models/financial_account_model.dart';

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
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hint = 'Search by username or phone...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: AppTheme.primary),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AccountCard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AccountCard extends StatelessWidget {
  final FinancialAccount account;
  final bool showToggle;
  final bool showStar;
  final ValueChanged<bool>? onToggleVisibility;
  final VoidCallback? onStar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    this.showToggle = false,
    this.showStar = false,
    this.onToggleVisibility,
    this.onStar,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        AppConstants.accountTypeLabels[account.type.name] ?? account.type.name;

    final card = Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Account type icon circle
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _accountIcon(account.type),
                color: AppTheme.primary,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),

            // Label + identifier
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    account.accountIdentifier,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Limit badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${_fmtAmount(account.defaultLimit.toDouble())} EGP',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Star action
            if (showStar) ...[
              SizedBox(width: 4.w),
              IconButton(
                icon: Icon(
                  account.priority == 0 ? Icons.star : Icons.star_border,
                  color: account.priority == 0
                      ? AppTheme.primary
                      : AppTheme.primary,
                  size: 20.r,
                ),
                onPressed: onStar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],

            // Visibility toggle
            if (showToggle) ...[
              SizedBox(width: 4.w),
              Switch.adaptive(
                value: account.isVisible,
                onChanged: onToggleVisibility,
                activeColor: AppTheme.primary,
              ),
            ],
          ],
        ),
      ),
    );

    // If no swipe actions are provided, return plain card
    if (onEdit == null && onDelete == null) return card;

    return Slidable(
      key: ValueKey('account-${account.id}'),
      closeOnScroll: true,
      startActionPane: onEdit == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.26,
              children: [
                SlidableAction(
                  onPressed: (_) => onEdit!.call(),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
              ],
            ),
      endActionPane: onDelete == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.26,
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete!.call(),
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                ),
              ],
            ),
      child: card,
    );
  }

  IconData _accountIcon(AccountType type) {
    switch (type.name) {
      case 'instapay':
        return Icons.flash_on;
      case 'digital_wallet':
        return Icons.phone_android;
      case 'bank_account':
        return Icons.account_balance;
      case 'telda':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _fmtAmount(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
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
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13.sp,
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

  const AmountInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount (EGP)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: 'EGP  ',
            prefixStyle: TextStyle(
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
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 14.sp, color: AppTheme.primary),
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
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              )
            : null,
      ),
      title: Text(
        displayName,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary),
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
              style: TextStyle(color: AppColors.error, fontSize: 13.sp),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
        ],
      ),
    );
  }
}
