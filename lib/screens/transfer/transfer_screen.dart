import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/split_suggestion_model.dart';
import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Transfer Instructions Screen
///
/// Displays the split result with copy-to-clipboard actions for each account.
/// This replaces deep linking for the MVP phase.
class TransferScreen extends ConsumerWidget {
  final TransferArgs args;

  const TransferScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = args.suggestions;
    final recipient = args.recipient;

    // Calculate total
    final total = suggestions.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Instructions')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // ── Summary card ──────────────────────────────────────────────────
          _SummaryCard(recipient: recipient, total: total),
          SizedBox(height: 20.h),

          // ── Instructions ──────────────────────────────────────────────────
          Text(
            'Follow these steps to complete your transfer:',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 14.h),

          // ── Transfer tiles ────────────────────────────────────────────────
          ...suggestions.asMap().entries.map(
            (entry) =>
                _TransferTile(step: entry.key + 1, suggestion: entry.value),
          ),

          SizedBox(height: 28.h),

          // ── Done button ───────────────────────────────────────────────────
          PrimaryButton(
            label: 'Done',
            backgroundColor: AppTheme.success,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.transferSuccess);
            },
          ),

          SizedBox(height: 16.h),

          // Disclaimer
          Center(
            child: Text(
              'Complete transfers manually in each payment app.',
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final User recipient;
  final double total;

  const _SummaryCard({required this.recipient, required this.total});

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = recipient.avatarUrl;
    final bool hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      recipient.displayName.isNotEmpty
                          ? recipient.displayName[0].toUpperCase()
                          : (recipient.initials.isNotEmpty
                                ? recipient.initials[0]
                                : '?'),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.displayName.isNotEmpty
                        ? recipient.displayName
                        : 'Recipient',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    recipient.username.isNotEmpty
                        ? '@${recipient.username}'
                        : '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} EGP',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual transfer tile ─────────────────────────────────────────────────

class _TransferTile extends StatelessWidget {
  final int step;
  final SplitSuggestion suggestion;

  const _TransferTile({required this.step, required this.suggestion});

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
        content: Text('$label copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header
            Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Amount badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _amountStr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Copy row: Account number
            _CopyRow(
              icon: Icons.tag,
              label: 'Account / Phone',
              value: suggestion.accountIdentifier,
              onCopy: () => _copy(
                context,
                suggestion.accountIdentifier,
                'Account number',
              ),
            ),
            SizedBox(height: 8.h),

            // Copy row: Amount
            _CopyRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: _amountStr,
              onCopy: () => _copy(context, _amountStr, 'Amount'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: AppTheme.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onCopy,
          icon: Icon(Icons.copy, size: 14.r),
          label: Text('Copy', style: TextStyle(fontSize: 13.sp)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          ),
        ),
      ],
    );
  }
}
