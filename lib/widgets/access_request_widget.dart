import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
import '../models/access_request_model.dart';
import '../providers/access_request_provider.dart';
import '../providers/auth_provider.dart';

/// Widget to display a received access request
class AccessRequestTile extends ConsumerWidget {
  final AccessRequest request;

  const AccessRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Requester info + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access Request',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'From: ${request.requesterId.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyles.captionBold.copyWith(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16.r),
                SizedBox(width: 8.w),
                Text(
                  '${request.createdAt.year}-${request.createdAt.month.toString().padLeft(2, '0')}-${request.createdAt.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Action buttons (only if pending)
            if (request.status == AccessStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(context, ref, request.id),
                      icon: Icon(Icons.close, size: 18.r),
                      label: Text('Reject', style: TextStyles.label),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _approveRequest(context, ref, request.id),
                      icon: Icon(Icons.check, size: 18.r),
                      label: Text('Approve', style: TextStyles.label),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  request.status == AccessStatus.approved
                      ? '✓ Access Granted'
                      : '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: request.status == AccessStatus.approved
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (request.status) {
      case AccessStatus.pending:
        return Colors.orange;
      case AccessStatus.approved:
        return Colors.green;
      case AccessStatus.rejected:
        return Colors.red;
    }
  }

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.approveRequest(requestId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request approved'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && context.mounted) {
      AppSnackBar.error(
        context,
        ref.read(accessRequestProvider).error ?? 'Failed to approve',
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.rejectRequest(requestId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (!success && context.mounted) {
      AppSnackBar.error(
        context,
        ref.read(accessRequestProvider).error ?? 'Failed to reject',
      );
    }
  }
}

/// Dialog to send an access request
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final accessRequest = ref.watch(accessRequestProvider);

    return AlertDialog(
      title: const Text('Request Access'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request access to ${widget.recipientName}\'s accounts?'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'They will be able to approve or reject your request',
                style: TextStyles.captionRegular.copyWith(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Show error message if request failed
            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyles.captionRegular.copyWith(
                              fontSize: 12.sp,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (errorMessage != null) SizedBox(height: 16.h),
            // Show rejection count warning if applicable
            if (auth.user != null && errorMessage == null)
              _buildRejectionWarning(context, auth.user!.id),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        if (errorMessage != null)
          FilledButton(
            onPressed: () {
              setState(() {
                errorMessage = null;
              });
            },
            child: const Text('Try Again'),
          )
        else
          FilledButton(
            onPressed: (isLoading || accessRequest.isCreating)
                ? null
                : () async {
                    if (auth.user != null) {
                      setState(() => isLoading = true);

                      final (success, errorMsg) = await ref
                          .read(accessRequestProvider.notifier)
                          .createAccessRequest(
                            requesterId: auth.user!.id,
                            receiverId: widget.recipientId,
                          );

                      if (mounted) {
                        if (success) {
                          // Show success snackbar
                          AppSnackBar.success(
                            context,
                            'Access request sent successfully',
                          );
                          // Defer navigation until after the current frame
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pop(context, success);
                            }
                          });
                        } else {
                          final duplicatePending =
                              errorMsg?.contains('pending request') ?? false;

                          if (duplicatePending && mounted) {
                            // Show required snackbar and leave button untouched
                            AppSnackBar.info(
                              context,
                              'You already have a pending request. Please wait for approval or cancel it first.',
                            );

                            Navigator.pop(context, null);
                            return;
                          }

                          // Other errors - allow retry inline
                          setState(() {
                            errorMessage = errorMsg ?? 'Failed to send request';
                            isLoading = false;
                          });
                        }
                      }
                    }
                  },
            child: (isLoading || accessRequest.isCreating)
                ? SizedBox(
                    height: 16.w,
                    width: 16.w,
                    child: CircularProgressIndicator(strokeWidth: 2.w),
                  )
                : Text('Send Request', style: TextStyles.bodySmallBold),
          ),
      ],
    );
  }

  /// Build rejection warning if user has been rejected by this receiver
  Widget _buildRejectionWarning(BuildContext context, String userId) {
    final accessService = ref.read(accessServiceProvider);

    return FutureBuilder<int>(
      future: accessService.getRejectionCount(
        requesterId: userId,
        receiverId: widget.recipientId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final rejectionCount = snapshot.data ?? 0;

        if (rejectionCount == 0) {
          return const SizedBox.shrink();
        }

        if (rejectionCount >= 3) {
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'You have reached the rejection limit. You cannot send more requests to this user.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          );
        }

        final remaining = 3 - rejectionCount;
        final warningColor = remaining == 1 ? Colors.red : Colors.orange;

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: warningColor.withOpacity(0.1),
            border: Border.all(color: warningColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_outlined, color: warningColor, size: 20.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'This user has rejected your request $rejectionCount time${rejectionCount != 1 ? 's' : ''}. You have $remaining more attempt${remaining != 1 ? 's' : ''} before being permanently blocked.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: warningColor.shade700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
