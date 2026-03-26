import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
import '../models/access_request_model.dart';
import '../models/financial_account_model.dart';
import '../providers/access_request_provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/format_util.dart';
import 'country_flag_icon.dart';
import 'provider_logo.dart';

/// Widget to display a received access request
class AccessRequestTile extends ConsumerWidget {
  final AccessRequest request;

  const AccessRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusData = _statusData;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: statusData.color.withOpacity(0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 22.r,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access Request',
                        style: TextStyles.bodySmallBold.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'ID: ${request.requesterId.substring(0, 8)}…',
                        style: TextStyles.label.copyWith(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusData.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: statusData.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          color: statusData.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        statusData.label,
                        style: TextStyles.label.copyWith(
                          color: statusData.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),
            Divider(height: 1, color: AppTheme.border.withOpacity(0.3)),
            SizedBox(height: 14.h),

            // ── Date row ─────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14.r,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyles.label.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            // ── Actions ───────────────────────────────────────────────
            if (request.status == AccessStatus.pending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _OutlinedActionButton(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      color: Colors.red.shade400,
                      onTap: () => _rejectRequest(context, ref, request.id),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _FilledActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      onTap: () => _openDetails(context),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == AccessStatus.approved) ...[
              SizedBox(height: 14.h),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16.r,
                    color: Colors.green.shade500,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Access Granted',
                    style: TextStyles.label.copyWith(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => FormatUtils.formatDateTime(dt);

  ({Color color, String label}) get _statusData => switch (request.status) {
    AccessStatus.pending => (color: Colors.orange, label: 'Pending'),
    AccessStatus.approved => (color: Colors.green, label: 'Approved'),
    AccessStatus.rejected => (color: Colors.red, label: 'Rejected'),
    AccessStatus.cancelled => (color: Colors.grey, label: 'Cancelled'),
    AccessStatus.revoked => (color: Colors.red, label: 'Revoked'),
    AccessStatus.revokedByRequester =>
      (color: Colors.red, label: 'Revoked'),
    AccessStatus.revokedByReceiver =>
      (color: Colors.red, label: 'Revoked'),
  };

  void _openDetails(BuildContext context) => Navigator.pushNamed(
    context,
    AppRoutes.requesterDetails,
    arguments: request,
  );

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.rejectRequest(requestId);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      AppSnackBar.error(
        context,
        ref.read(accessRequestProvider).error ?? 'Failed to reject',
      );
    }
  }
}

// ─── Small reusable button widgets ────────────────────────────────────────────

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.r),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilledActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilledActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.r),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Send Access Request Dialog ───────────────────────────────────────────────

class SendAccessRequestDialog extends ConsumerStatefulWidget {
  final String recipientId;
  final String recipientName;

  const SendAccessRequestDialog({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  ConsumerState<SendAccessRequestDialog> createState() =>
      _SendAccessRequestDialogState();
}

class _SendAccessRequestDialogState
    extends ConsumerState<SendAccessRequestDialog> {
  String? errorMessage;
  bool isLoading = false;
  String _accessType = 'full';
  final Set<String> _selectedAccountIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(accountsProvider.notifier).loadAccounts(user.id);
      }
    });
  }

  bool get _canSend =>
      _accessType.isNotEmpty &&
      (_accessType == 'full' || _selectedAccountIds.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final accessRequest = ref.watch(accessRequestProvider);
    final accountsState = ref.watch(accountsProvider);
    final isBusy = isLoading || accessRequest.isCreating;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Dialog header ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 16.w, 18.h),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border(
                bottom: BorderSide(color: AppTheme.border.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 18.r,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Access',
                        style: TextStyles.bodySmallBold.copyWith(
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        'To ${widget.recipientName}',
                        style: TextStyles.label.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20.r,
                    color: AppTheme.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    minimumSize: Size(34.r, 34.r),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15.r,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Choose how much of your accounts ${widget.recipientName} can see.',
                            style: TextStyles.label.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),
                  _buildAccessTypeSelector(),

                  if (_accessType == 'custom') ...[
                    SizedBox(height: 16.h),
                    _buildAccountList(accountsState),
                  ],

                  if (errorMessage != null) ...[
                    SizedBox(height: 14.h),
                    _buildErrorBox(),
                  ],

                  if (auth.user != null && errorMessage == null) ...[
                    SizedBox(height: 14.h),
                    _buildRejectionWarning(context, auth.user!.id),
                  ],

                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),

          // ── Footer actions ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: (!_canSend || isBusy)
                        ? null
                        : () => _submit(auth),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.primary.withOpacity(
                        0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: isBusy
                        ? SizedBox(
                            height: 18.r,
                            width: 18.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 16.r,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Send Request',
                                style: TextStyles.bodySmallBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(dynamic auth) async {
    final user = auth.user;
    if (user == null) return;

    setState(() => isLoading = true);

    final selectedIds = _accessType == 'custom'
        ? _selectedAccountIds.toList()
        : const <String>[];

    final (success, errorMsg) = await ref
        .read(accessRequestProvider.notifier)
        .createAccessRequest(
          requesterId: user.id,
          receiverId: widget.recipientId,
          requestAccessType: _accessType,
          selectedAccountIds: selectedIds,
        );

    if (!mounted) return;

    if (success) {
      AppSnackBar.success(context, 'Access request sent successfully');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, success);
      });
    } else {
      final isDuplicate = errorMsg?.contains('pending request') ?? false;
      if (isDuplicate && mounted) {
        AppSnackBar.info(
          context,
          'You already have a pending request. Please wait for approval or cancel it first.',
        );
        Navigator.pop(context, null);
        return;
      }
      setState(() {
        errorMessage = errorMsg ?? 'Failed to send request';
        isLoading = false;
      });
    }
  }

  // ── Access type selector ───────────────────────────────────────────────────

  Widget _buildAccessTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Access Type', style: TextStyles.bodySmallBold),
        SizedBox(height: 10.h),
        Row(
          children: [
            _accessTypeChip(
              label: 'Full Access',
              value: 'full',
              description: 'Share all accounts',
              icon: Icons.all_inclusive_rounded,
            ),
            SizedBox(width: 10.w),
            _accessTypeChip(
              label: 'Custom',
              value: 'custom',
              description: 'Pick specific accounts',
              icon: Icons.tune_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _accessTypeChip({
    required String label,
    required String value,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _accessType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _accessType = value;
          if (_accessType == 'full') _selectedAccountIds.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.border.withOpacity(0.4),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      icon,
                      size: 15.r,
                      color: isSelected ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15.r,
                      color: Colors.white.withOpacity(0.9),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                label,
                style: TextStyles.bodySmallBold.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                description,
                style: TextStyles.label.copyWith(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Account list ───────────────────────────────────────────────────────────

  Widget _buildAccountList(AccountsState accountsState) {
    if (accountsState.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26.r,
                height: 26.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Loading accounts…',
                style: TextStyles.label.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (accountsState.error != null) {
      return _StatusBanner(
        color: Colors.red,
        icon: Icons.error_outline_rounded,
        message: accountsState.error!,
      );
    }

    if (accountsState.accounts.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppTheme.border.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 34.r,
              color: AppTheme.textSecondary.withOpacity(0.4),
            ),
            SizedBox(height: 10.h),
            Text(
              'No accounts available',
              style: TextStyles.bodySmallBold.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'You need at least one financial account to share.',
              textAlign: TextAlign.center,
              style: TextStyles.label.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Select Accounts', style: TextStyles.bodySmallBold),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _selectedAccountIds.isEmpty
                    ? 'None selected'
                    : '${_selectedAccountIds.length} selected',
                key: ValueKey(_selectedAccountIds.length),
                style: TextStyles.label.copyWith(
                  color: _selectedAccountIds.isEmpty
                      ? AppTheme.textSecondary
                      : AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: _selectedAccountIds.isEmpty
                  ? Colors.red.withOpacity(0.35)
                  : AppTheme.border.withOpacity(0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: accountsState.accounts.asMap().entries.map((entry) {
              final isLast = entry.key == accountsState.accounts.length - 1;
              return Column(
                children: [
                  _accountTile(entry.value),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.border.withOpacity(0.2),
                      indent: 16.w,
                      endIndent: 16.w,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _selectedAccountIds.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: 8.h, left: 2.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13.r,
                        color: Colors.red.shade400,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Pick at least one account to continue.',
                        style: TextStyles.label.copyWith(
                          color: Colors.red.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _accountTile(FinancialAccount account) {
    final selected = _selectedAccountIds.contains(account.id);
    final title = account.accountTitle.isNotEmpty
        ? account.accountTitle
        : account.providerName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      color: selected ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: () => _toggleAccount(account.id),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              ProviderLogo(
                logoUuid: account.providerLogo,
                providerName: account.providerName,
                size: 40.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bodySmallBold.copyWith(fontSize: 13.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        CountryFlagIcon(
                          countryCode: account.countryCode,
                          size: 16.w,
                        ),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            account.providerName,
                            style: TextStyles.label.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            account.accountTypeName.isNotEmpty
                                ? account.accountTypeName
                                : account.type.name,
                            style: TextStyles.label.copyWith(
                              fontSize: 10.sp,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (account.accountIdentifier.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        account.accountIdentifier,
                        style: TextStyles.label.copyWith(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.border.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14.r, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error & warning banners ────────────────────────────────────────────────

  Widget _buildErrorBox() {
    return _StatusBanner(
      color: Colors.red,
      icon: Icons.error_outline_rounded,
      message: errorMessage ?? 'Failed to send request',
      onClose: () => setState(() => errorMessage = null),
    );
  }

  void _toggleAccount(String accountId) => setState(() {
    if (_selectedAccountIds.contains(accountId)) {
      _selectedAccountIds.remove(accountId);
    } else {
      _selectedAccountIds.add(accountId);
    }
  });

  Widget _buildRejectionWarning(BuildContext context, String userId) {
    final accessService = ref.read(accessServiceProvider);

    return FutureBuilder<int>(
      future: accessService.getRejectionCount(
        requesterId: userId,
        receiverId: widget.recipientId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }

        final count = snapshot.data!;
        if (count >= 3) {
          return _StatusBanner(
            color: Colors.red,
            icon: Icons.block_rounded,
            message:
                'You have reached the rejection limit and can no longer send requests to this user.',
          );
        }

        final remaining = 3 - count;
        final color = remaining == 1 ? Colors.red : Colors.orange;

        return _StatusBanner(
          color: color,
          icon: Icons.warning_amber_rounded,
          message:
              'This user has rejected your request $count time${count != 1 ? 's' : ''}. '
              'You have $remaining more attempt${remaining != 1 ? 's' : ''} before being permanently blocked.',
        );
      },
    );
  }
}

// ─── Reusable status banner ────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final VoidCallback? onClose;

  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(icon, size: 16.r, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.label.copyWith(
                color: color.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
          if (onClose != null) ...[
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: 16.r, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
