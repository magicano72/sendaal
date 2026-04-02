import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/models/user_model.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';

class ContactCard extends StatelessWidget {
  final User user;
  final String subtitle;
  final bool isFavorite;
  final String actionLabel;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final bool showFullName;

  const ContactCard({
    super.key,
    required this.user,
    required this.subtitle,
    required this.isFavorite,
    required this.actionLabel,
    required this.onTap,
    this.onAction,
    this.onFavoriteToggle,
    this.width = 150,
    this.showFullName = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final initials = (user.firstName?.trim().isNotEmpty ?? false)
        ? user.firstName!.trim()[0].toUpperCase()
        : user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';

    final primary = showFullName
        ? (user.firstName?.trim().isNotEmpty == true
              ? user.firstName!.trim()
              : (user.displayName.isNotEmpty
                    ? user.displayName
                    : user.username))
        : (user.username.isNotEmpty
              ? '@${user.username}'
              : (user.phoneNumber ?? '?'));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            initials,
                            style: TextStyles.bodyBold.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const Spacer(),
                  if (onFavoriteToggle != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 18.r,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.bodySmallBold.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.captionRegular.copyWith(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    side: BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: onAction ?? onTap,
                  child: Text(
                    actionLabel,
                    style: TextStyles.captionBold.copyWith(fontSize: 12.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
