// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AccountCard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
import '../models/financial_account_model.dart';
import '../models/system_limit_model.dart';
import 'provider_logo.dart';

class AccountCard extends StatelessWidget {
  final FinancialAccount account;
  final bool showToggle;
  final bool showStar;
  final bool dense;
  final ValueChanged<bool>? onToggleVisibility;
  final VoidCallback? onStar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.showToggle = false,
    this.showStar = false,
    this.dense = false,
    this.onToggleVisibility,
    this.onStar,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawType = account.accountTypeName.isNotEmpty
        ? account.accountTypeName
        : account.type.name;
    final label = rawType.isNotEmpty
        ? AppConstants.displayLabel(rawType)
        : account.providerName.isNotEmpty
        ? account.providerName
        : account.type.name;
    final system =
        AppConstants.systemLimitFor(rawType) ?? _fallbackSystem(account);
    final title = account.accountTitle.trim().isNotEmpty
        ? account.accountTitle.trim()
        : label;
    final subtitleParts = <String>[
      account.providerName.isNotEmpty ? account.providerName : label,
      if (account.accountIdentifier.trim().isNotEmpty)
        account.accountIdentifier.trim(),
      if (account.currency?.isNotEmpty == true) account.currency!,
    ];
    final subtitle = subtitleParts.join('\n');
    final verticalPadding = dense ? 10.h : 12.h;
    final horizontalPadding = dense ? 14.w : 16.w;
    final bottomMargin = dense ? 8.h : 10.h;

    // Star icon (20.r) + padding (8.w * 2) + a little breathing room
    final starReservedWidth = showStar ? (dense ? 34.w : 36.w) : 0.0;

    final card = Card(
      margin: EdgeInsets.only(bottom: bottomMargin),
      color: account.isFavourite ? AppTheme.primary.withOpacity(0.03) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: account.isFavourite
              ? AppTheme.primary.withOpacity(0.35)
              : Colors.transparent,
          width: account.isFavourite ? 1.2 : 0,
        ),
      ),
      child: Stack(
        children: [
          // ── Main content row ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              // Shrink right edge so the limit badge never slides under star
              horizontalPadding + starReservedWidth,
              verticalPadding,
            ),
            child: Row(
              children: [
                ProviderLogo(
                  logoUuid: account.providerLogo,
                  providerName: account.providerName,
                  size: dense ? 44.w : 46.w,
                ),
                SizedBox(width: 14.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.bodySmallBold.copyWith(
                          fontSize: dense ? 14.sp : 15.sp,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyles.label.copyWith(
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
                    '${account.currency?.isNotEmpty == true ? account.currency : 'EGP'} '
                    '${_fmtAmount(account.defaultLimit.toDouble())}',
                    style: TextStyles.captionMedium.copyWith(
                      fontSize: 11.sp,
                      color: AppTheme.primary,
                    ),
                  ),
                ),

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

          // ── Priority badge — top-left corner tag ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            child: _PriorityBadge(priority: account.priority),
          ),

          // ── Favourite star — vertically centred on the right edge ────────
          if (showStar)
            Positioned(
              top: 0,
              bottom: 0,
              right: 4.w,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onStar,
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        account.isFavourite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: account.isFavourite
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: dense ? 18.r : 20.r,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final tappableCard = onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: onTap,
            child: card,
          );

    if (onEdit == null && onDelete == null) return tappableCard;

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
      child: tappableCard,
    );
  }
}

String _fmtAmount(double v) {
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
  }
  return v.toStringAsFixed(0);
}

class _PriorityBadge extends StatelessWidget {
  final AccountPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (priority) {
      case AccountPriority.high:
        bg = AppColors.border.withOpacity(0.35);
        fg = AppColors.error;
        label = 'High';
        break;
      case AccountPriority.low:
        bg = AppColors.border.withOpacity(0.35);
        fg = AppColors.primary;
        label = 'Low';
        break;
      case AccountPriority.medium:
      default:
        bg = AppTheme.border.withOpacity(0.35);
        fg = AppColors.warning;
        label = 'Medium';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.r),
          bottomRight: Radius.circular(10.r),
        ),
      ),
      child: Text(label, style: TextStyles.captionMedium.copyWith(color: fg)),
    );
  }
}

SystemLimit _fallbackSystem(FinancialAccount account) => SystemLimit(
  id: -1,
  systemName: account.accountTypeName.isNotEmpty
      ? account.accountTypeName
      : account.type.name,
  dailyLimit: account.defaultLimit.toInt(),
  systemImage: null,
);
