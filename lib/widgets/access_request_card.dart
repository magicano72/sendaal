import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/models/user_model.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
import '../models/access_request_model.dart';
import '../providers/access_request_provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/format_util.dart';
import 'delete_confirmation_dialog.dart';
import 'shimmer_widgets.dart';

/// Compact card to display access request on home/search screens.
/// Matches the high-fidelity design with avatar, status chip, and actions.
class AccessRequestCard extends ConsumerWidget {
  final AccessRequest request;
  final bool isReceived; // True if receiver viewing, false if requester viewing

  const AccessRequestCard({
    super.key,
    required this.request,
    this.isReceived = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final isPending = request.status == AccessStatus.pending;
    final isApproved = request.status == AccessStatus.approved;
    final isRevoked = request.isRevoked;

    // Fetch user info (requester if received, receiver if sent)
    final userIdToFetch = isReceived ? request.requesterId : request.receiverId;
    final isRequester = currentUser?.id == request.requesterId;
    final isReceiver = currentUser?.id == request.receiverId;
    final isRevoker =
        (request.revokerId != null && request.revokerId == currentUser?.id);

    final canOpenDetails = () {
      if (isRevoked && !isRevoker) return false;
      if (isRequester) {
        return request.status == AccessStatus.approved || isRevoker;
      }
      if (isReceiver) return userIdToFetch.isNotEmpty;
      return false;
    }();

    final showPendingActions = isPending && isRequester;
    final showManageActions = isApproved && (isRequester || isReceiver);
    final userAsync = ref.watch(userProvider(userIdToFetch));

    return userAsync.when(
      loading: () => ShimmerCard(height: 150.h),
      error: (_, __) => _buildCard(
        context,
        ref,
        displayName: 'User ${userIdToFetch.substring(0, 6)}',
        firstName: null,
        avatarUrl: null,
        canOpenDetails: canOpenDetails,
        showPendingActions: showPendingActions,
        showManageActions: showManageActions,
        isRequester: isRequester,
        isReceiver: isReceiver,
        isRevoked: isRevoked,
        isRevoker: isRevoker,
      ),
      data: (User user) => _buildCard(
        context,
        ref,
        displayName: user.displayName.isNotEmpty
            ? user.displayName
            : user.username,
        firstName: user.firstName,
        avatarUrl: user.avatarUrl,
        canOpenDetails: canOpenDetails,
        showPendingActions: showPendingActions,
        showManageActions: showManageActions,
        isRequester: isRequester,
        isReceiver: isReceiver,
        isRevoked: isRevoked,
        isRevoker: isRevoker,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
    required String? firstName,
    required String? avatarUrl,
    required bool canOpenDetails,
    required bool showPendingActions,
    required bool showManageActions,
    required bool isRequester,
    required bool isReceiver,
    required bool isRevoked,
    required bool isRevoker,
  }) {
    final statusColor = _getStatusColor();
    final subtitle = isReceived
        ? 'Requested access\n${FormatUtils.formatDateTime(request.createdAt)}'
        : 'Access request sent\n${FormatUtils.formatDateTime(request.createdAt)}';
    final allowHide = request.canHide || isReceived;

    return Slidable(
      key: ValueKey('access-${request.id}'),
      closeOnScroll: true,
      endActionPane: allowHide
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.32,
              children: [
                SlidableAction(
                  onPressed: (_) => _confirmDelete(context, ref),
                  backgroundColor: Colors.red.withOpacity(0.12),
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  spacing: 6.w,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18.r),
                    bottomRight: Radius.circular(18.r),
                  ),
                ),
              ],
            )
          : null,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: InkWell(
          onTap: canOpenDetails
              ? () => _openRequesterDetails(context, request)
              : null,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(avatarUrl, firstName ?? displayName),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.bodyBold.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.label.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(statusColor),
                  ],
                ),
                SizedBox(height: 14.h),
                _buildActionArea(
                  context,
                  ref,
                  statusColor: statusColor,
                  canOpenDetails: canOpenDetails,
                  showPendingActions: showPendingActions,
                  showManageActions: showManageActions,
                  isRequester: isRequester,
                  isReceiver: isReceiver,
                  isRevoked: isRevoked,
                  isRevoker: isRevoker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(Color statusColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _statusLabel(),
        style: TextStyles.captionBold.copyWith(
          fontSize: 11.sp,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    WidgetRef ref, {
    required Color statusColor,
    required bool canOpenDetails,
    required bool showPendingActions,
    required bool showManageActions,
    required bool isRequester,
    required bool isReceiver,
    required bool isRevoked,
    required bool isRevoker,
  }) {
    if (isRevoked) {
      return _buildRevokedActions(context, ref, isRevoker);
    }
    if (showPendingActions) {
      return _buildPendingActions(context, ref);
    }
    if (showManageActions) {
      return _buildManageButton(context, ref, isRequesterSide: isRequester);
    }

    return _buildStatusFooter(
      context,
      ref,
      statusColor,
      canOpenDetails,
      isRequester: isRequester,
      isReceiver: isReceiver,
    );
  }

  Widget _buildRevokedActions(
    BuildContext context,
    WidgetRef ref,
    bool isRevoker,
  ) {
    if (isRevoker) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () async {
            final success = await ref
                .read(accessRequestProvider.notifier)
                .cancelRevoke(request.id);
            if (!context.mounted) return;
            if (success != null) {
              AppSnackBar.success(context, 'Revoke cancelled');
              ref.invalidate(
                latestRequestBetweenProvider((
                  request.requesterId,
                  request.receiverId,
                )),
              );
            } else {
              final error =
                  ref.read(accessRequestProvider).error ?? 'Failed to restore';
              AppSnackBar.error(context, error);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Text(
            'Cancel Revoke',
            style: TextStyles.bodySmallBold.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        'Access Denied',
        style: TextStyles.labelBold.copyWith(color: Colors.red.shade600),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 52.r,
      height: 52.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0E7DA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(avatarUrl, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initial,
                  style: TextStyles.bodyBold.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2C3B),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => _openEditSheet(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text('Edit', style: TextStyles.bodySmallBold),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmCancel(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Colors.red.shade50,
            ),
            child: Text('Cancel', style: TextStyles.bodySmallBold),
          ),
        ),
      ],
    );
  }

  Widget _buildManageButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isRequesterSide,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openManageSheet(context, ref, isRequesterSide),
        icon: Icon(Icons.settings_outlined, size: 18.r),
        label: Text(
          'Manage',
          style: TextStyles.bodySmallBold.copyWith(
            color: const Color(0xFF1F2C3B),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D9E6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          backgroundColor: const Color(0xFFF9FBFF),
        ),
      ),
    );
  }

  Widget _buildStatusFooter(
    BuildContext context,
    WidgetRef ref,
    Color statusColor,
    bool canOpenDetails, {
    required bool isRequester,
    required bool isReceiver,
  }) {
    if (request.status == AccessStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: canOpenDetails
              ? () => _openRequesterDetails(context, request)
              : null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFFD1D9E6),
              style: BorderStyle.solid,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            backgroundColor: const Color(0xFFF9FBFF),
          ),
          child: Text(
            'View Log Details',
            style: TextStyles.bodySmallBold.copyWith(
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
      );
    }

    if (request.status == AccessStatus.rejected && request.canHide) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _confirmDelete(context, ref),
          icon: Icon(Icons.delete_outline, size: 16.r, color: statusColor),
          label: Text(
            'Delete',
            style: TextStyles.labelBold.copyWith(color: statusColor),
          ),
        ),
      );
    }

    if (request.status == AccessStatus.cancelled) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Text(
          'Request cancelled by requester',
          style: TextStyles.labelBold.copyWith(color: statusColor),
        ),
      );
    }

    if (request.status == AccessStatus.revoked ||
        request.status == AccessStatus.revokedByRequester ||
        request.status == AccessStatus.revokedByReceiver) {
      //final who = request.status == AccessStatus.revokedByRequester
      //     ? 'Requester'
      //     : 'Receiver';
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Text(
          //$who
          'revoked access',
          style: TextStyles.labelBold.copyWith(color: statusColor),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Text(
        request.status == AccessStatus.rejected
            ? 'Request rejected'
            : 'Awaiting response',
        style: TextStyles.labelBold.copyWith(color: statusColor),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'Cancel Request?',
        description: 'Are you sure you want to cancel this request?',
        confirmLabel: 'Cancel request',
        cancelLabel: 'Keep request',
        confirmColor: Colors.red,
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(accessRequestProvider.notifier)
        .cancelRequest(
          requesterId: request.requesterId,
          receiverId: request.receiverId,
        );

    if (!context.mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Request cancelled');
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        await Future.wait([
          ref
              .read(accessRequestProvider.notifier)
              .loadReceivedRequests(currentUser.id),
          ref
              .read(accessRequestProvider.notifier)
              .loadSentRequests(currentUser.id),
        ]);
      }
    } else {
      AppSnackBar.error(context, 'Failed to cancel request');
    }
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    await _openAccessEditor(
      context,
      ref,
      isRequesterSide: true,
      title: 'Edit access request',
      initialAccessType: request.requestAccessType,
      allowRevoke: false,
    );
  }

  Future<void> _openManageSheet(
    BuildContext context,
    WidgetRef ref,
    bool isRequesterSide,
  ) async {
    final initialAccessType = isRequesterSide
        ? request.requestAccessType
        : (request.approvedAccessType ?? 'full');

    await _openAccessEditor(
      context,
      ref,
      isRequesterSide: isRequesterSide,
      title: 'Manage shared access',
      initialAccessType: initialAccessType,
      allowRevoke: true,
    );
  }

  Future<void> _openAccessEditor(
    BuildContext context,
    WidgetRef ref, {
    required bool isRequesterSide,
    required String title,
    required String initialAccessType,
    required bool allowRevoke,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      AppSnackBar.error(context, 'User not authenticated');
      return;
    }

    await ref.read(accountsProvider.notifier).loadAccounts(currentUser.id);
    final accountsState = ref.read(accountsProvider);
    final side = isRequesterSide ? 'requester' : 'receiver';
    final existingLinks = await ref
        .read(accessRequestProvider.notifier)
        .getRequestAccounts(requestId: request.id, side: side);

    final selectedIds = existingLinks
        .map((a) => a.financialAccount.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    String accessType = initialAccessType.isNotEmpty
        ? initialAccessType
        : 'full';
    String? errorText;
    bool isSaving = false;

    await showModalBottomSheet(
      backgroundColor: AppColors.background,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final accounts = accountsState.accounts;
            final isCustom = accessType == 'custom';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 18.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyles.bodyBold.copyWith(fontSize: 16.sp),
                        ),
                      ),
                      IconButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _accessTypeSelector(
                    accessType: accessType,
                    onChanged: (value) {
                      setState(() {
                        accessType = value;
                        if (value == 'full') {
                          selectedIds.clear();
                          errorText = null;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  if (isCustom)
                    _accountChecklist(accountsState, selectedIds, setState),
                  if (errorText != null) ...[
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: TextStyles.labelBold.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (accessType == 'custom' && selectedIds.isEmpty) {
                              setState(
                                () => errorText =
                                    'Select at least one account or switch to Full access.',
                              );
                              return;
                            }
                            setState(() {
                              isSaving = true;
                              errorText = null;
                            });

                            final updated = await ref
                                .read(accessRequestProvider.notifier)
                                .updateAccessType(
                                  request: request,
                                  isRequesterSide: isRequesterSide,
                                  accessType: accessType,
                                  selectedAccountIds: isCustom
                                      ? selectedIds.toList()
                                      : const [],
                                );
                            if (!sheetContext.mounted) return;
                            setState(() => isSaving = false);

                            if (updated != null) {
                              Navigator.of(sheetContext).pop();
                              AppSnackBar.success(context, 'Access updated');
                            } else {
                              setState(
                                () => errorText =
                                    ref.read(accessRequestProvider).error ??
                                    'Failed to update',
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.h),
                      backgroundColor: AppTheme.primary,
                    ),
                    child: isSaving
                        ? SizedBox(
                            height: 18.r,
                            width: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                  if (allowRevoke) ...[
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final confirmed = await _confirmRevoke(
                                sheetContext,
                              );
                              if (confirmed != true) return;
                              setState(() => isSaving = true);
                              final currentUserId = ref
                                  .read(authProvider)
                                  .user
                                  ?.id;
                              if (currentUserId == null ||
                                  currentUserId.isEmpty) {
                                setState(() {
                                  isSaving = false;
                                  errorText = 'User not authenticated';
                                });
                                return;
                              }
                              final updated = await ref
                                  .read(accessRequestProvider.notifier)
                                  .revokeAccess(
                                    request: request,
                                    isRequesterSide: isRequesterSide,
                                    currentUserId: currentUserId,
                                  );
                              if (!sheetContext.mounted) return;
                              setState(() => isSaving = false);
                              if (updated != null) {
                                Navigator.of(sheetContext).pop();
                                AppSnackBar.success(context, 'Access revoked');
                                ref.invalidate(
                                  latestRequestBetweenProvider((
                                    request.requesterId,
                                    request.receiverId,
                                  )),
                                );
                              } else {
                                setState(
                                  () => errorText =
                                      ref.read(accessRequestProvider).error ??
                                      'Failed to revoke access',
                                );
                              }
                            },
                      child: Text(
                        'Revoke access',
                        style: TextStyles.bodySmallBold.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _accessTypeSelector({
    required String accessType,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Full'),
            selected: accessType == 'full',
            onSelected: (_) => onChanged('full'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ChoiceChip(
            label: const Text('Custom'),
            selected: accessType == 'custom',
            onSelected: (_) => onChanged('custom'),
          ),
        ),
      ],
    );
  }

  Widget _accountChecklist(
    AccountsState accountsState,
    Set<String> selectedIds,
    void Function(void Function()) setState,
  ) {
    if (accountsState.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const CircularProgressIndicator(),
      );
    }

    if (accountsState.error != null) {
      return Text(
        accountsState.error!,
        style: TextStyles.labelBold.copyWith(color: Colors.red),
      );
    }

    if (accountsState.accounts.isEmpty) {
      return Text(
        'No accounts available to share.',
        style: TextStyles.labelBold.copyWith(color: Colors.red),
      );
    }

    return Column(
      children: accountsState.accounts.map((account) {
        final selected = selectedIds.contains(account.id);
        return CheckboxListTile(
          value: selected,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) {
            setState(() {
              if (selected) {
                selectedIds.remove(account.id);
              } else {
                selectedIds.add(account.id);
              }
            });
          },
          title: Text(
            account.accountTitle.isNotEmpty
                ? account.accountTitle
                : account.providerName,
            style: TextStyles.bodySmallBold,
          ),
          subtitle: Text(
            account.accountIdentifier.isNotEmpty
                ? account.accountIdentifier
                : account.accountTypeName,
            style: TextStyles.label,
          ),
        );
      }).toList(),
    );
  }

  Future<bool?> _confirmRevoke(BuildContext context) {
    final contactName = isReceived ? 'Requester' : 'Receiver';
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'Revoke access?',
        description:
            'Are you sure you want to revoke access? $contactName will no longer see your accounts.',
        confirmLabel: 'Revoke',
        cancelLabel: 'Keep access',
        confirmColor: Colors.red,
      ),
    );
  }

  Color _getStatusColor() {
    switch (request.status) {
      case AccessStatus.pending:
        return Colors.orange;
      case AccessStatus.approved:
        return const Color(0xFF24B177);
      case AccessStatus.rejected:
        return Colors.red;
      case AccessStatus.cancelled:
        return Colors.grey;
      case AccessStatus.revoked:
      case AccessStatus.revokedByRequester:
      case AccessStatus.revokedByReceiver:
        return Colors.deepOrange.shade400;
    }
  }

  String _statusLabel() {
    switch (request.status) {
      case AccessStatus.pending:
        return 'PENDING';
      case AccessStatus.approved:
        return 'APPROVED';
      case AccessStatus.rejected:
        return 'REJECTED';
      case AccessStatus.cancelled:
        return 'CANCELLED';
      case AccessStatus.revoked:
      case AccessStatus.revokedByRequester:
      case AccessStatus.revokedByReceiver:
        return 'REVOKED';
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'Confirm Delete',
        description:
            'Are you sure you want to delete this request? This action cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
      ),
    );

    if (confirmed == true) {
      await _clearRequest(context, ref);
    }
  }

  Future<void> _clearRequest(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.hideRequest(
      requestId: request.id,
      isReceived: isReceived,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request hidden from your view'
                : 'Unable to hide request',
          ),
          backgroundColor: success ? Colors.blueGrey : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openRequesterDetails(
    BuildContext context,
    AccessRequest accessRequest,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.requesterDetails,
      arguments: accessRequest,
    );
  }
}
