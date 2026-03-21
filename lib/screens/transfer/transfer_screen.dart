import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/split_suggestion_model.dart';
import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../widgets/app_widgets.dart';

/// Transfer Instructions Screen
///
/// Enhanced UI inspired by the provided mock to keep actions clear,
/// copyable, and consistent with the design system.
class TransferScreen extends ConsumerWidget {
  final TransferArgs args;

  const TransferScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = args.suggestions;
    final recipient = args.recipient;
    final total = suggestions.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Instructions')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TransferHeroCard(recipient: recipient, total: total),
              SizedBox(height: 22.h),
              Text(
                'Follow these steps',
                style: TextStyles.bodyBold.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Complete your transfer manually in the payment app.',
                style: TextStyles.label.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              ...suggestions.asMap().entries.map(
                (entry) => _TransferStepCard(
                  step: entry.key + 1,
                  suggestion: entry.value,
                ),
              ),
              SizedBox(height: 24.h),
              PrimaryButton(
                label: 'Done',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.transferSuccess);
                },
              ),
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  'Complete transfers manually in each payment app.',
                  style: TextStyles.captionRegular.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero card ───────────────────────────────────────────────────────────────

class _TransferHeroCard extends StatelessWidget {
  final User recipient;
  final double total;

  const _TransferHeroCard({required this.recipient, required this.total});

  String get _displayName =>
      recipient.displayName.isNotEmpty ? recipient.displayName : 'Recipient';

  String? get _username =>
      recipient.username.isNotEmpty ? '@${recipient.username}' : null;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = recipient.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final initials = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : '?';
    final amountLabel =
        '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} EGP';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    initials,
                    style: TextStyles.bodySmallBold.copyWith(
                      color: AppTheme.primary,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: TextStyles.bodySmallBold.copyWith(
                    fontSize: 15.sp,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_username != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _username!,
                    style: TextStyles.label.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL',
                style: TextStyles.captionMedium.copyWith(
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                amountLabel,
                style: TextStyles.bodySmallBold.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Instruction step card ───────────────────────────────────────────────────

class _TransferStepCard extends StatelessWidget {
  final int step;
  final SplitSuggestion suggestion;

  const _TransferStepCard({required this.step, required this.suggestion});

  String get _label =>
      AppConstants.accountTypeLabels[suggestion.type.name] ??
      suggestion.type.name;

  String get _amountStr {
    final v = suggestion.amount;
    return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} EGP';
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBadge(step: step),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open $_label & enter details',
                      style: TextStyles.bodySmallBold.copyWith(
                        fontSize: 15.sp,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Manual transfer for this split',
                      style: TextStyles.captionRegular.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  _amountStr,
                  style: TextStyles.labelBold.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _CopyPill(
            label: 'Account / Phone',
            value: suggestion.accountIdentifier,
            onCopy: () =>
                _copy(context, suggestion.accountIdentifier, 'Account / phone'),
          ),
          SizedBox(height: 10.h),
          _CopyPill(
            label: 'Transfer amount',
            value: _amountStr,
            onCopy: () => _copy(context, _amountStr, 'Amount'),
          ),
        ],
      ),
    );
  }
}

class _CopyPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CopyPill({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyles.captionMedium.copyWith(
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyles.bodySmallBold.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppTheme.border),
              ),
              child: IconButton(
                onPressed: onCopy,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18.r,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;

  const _StepBadge({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyles.labelBold.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
