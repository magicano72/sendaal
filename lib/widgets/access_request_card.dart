import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/models/user_model.dart';
import '../core/router/app_router.dart';
import '../core/theme/text_style.dart';
import '../models/access_request_model.dart';
import '../providers/access_request_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
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
    final isPending = request.status == AccessStatus.pending;
    final currentUser = ref.watch(authProvider).user;

    // Fetch user info (requester if received, receiver if sent)
    final userIdToFetch = isReceived ? request.requesterId : request.receiverId;
    final isRequester = currentUser?.id == request.requesterId;
    final isReceiver = currentUser?.id == request.receiverId;

    final canOpenDetails = () {
      if (isRequester) return request.status == AccessStatus.approved;
      if (isReceiver) return userIdToFetch.isNotEmpty;
      return false;
    }();

    final showActions = isReceived && isPending && isReceiver;
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
        showActions: showActions,
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
        showActions: showActions,
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
    required bool showActions,
  }) {
    final statusColor = _getStatusColor();
    final subtitle = isReceived
        ? 'Requested access\n${(request.createdAt.toString().split('.').first)}'
        : 'Access request sent\n${(request.createdAt.toString().split('.').first)}';
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
                showActions
                    ? _buildActionButtons(context, ref)
                    : _buildStatusFooter(
                        context,
                        ref,
                        statusColor,
                        canOpenDetails,
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
        request.status.name.toUpperCase(),
        style: TextStyles.captionBold.copyWith(
          fontSize: 11.sp,
          color: statusColor,
        ),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
        child: FilledButton(
            onPressed: () => _approveRequest(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D7AE8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text('Approve', style: TextStyles.bodySmallBold),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectRequest(context, ref, request.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: const Color(0xFFF7F8FA),
            ),
            child: Text('Decline', style: TextStyles.bodySmallBold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFooter(
    BuildContext context,
    WidgetRef ref,
    Color statusColor,
    bool canOpenDetails,
  ) {
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

  Color _getStatusColor() {
    switch (request.status) {
      case AccessStatus.pending:
        return Colors.orange;
      case AccessStatus.approved:
        return const Color(0xFF24B177);
      case AccessStatus.rejected:
        return Colors.red;
    }
  }

  String _formatRequestNumber(String id) {
    if (id.isEmpty) return '#0000';
    final trimmed = id.length > 6 ? id.substring(0, 6) : id;
    return '#$trimmed';
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

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    Navigator.pushNamed(
      context,
      AppRoutes.requesterDetails,
      arguments: request,
    );
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.rejectRequest(requestId);
    final currentUser = ref.read(authProvider).user;

    if (success && currentUser != null) {
      await Future.wait([
        notifier.loadReceivedRequests(currentUser.id),
        notifier.loadSentRequests(currentUser.id),
      ]);
    }

    if (success && context.mounted) {
      AppSnackBar.success(context, 'Access request rejected');
    } else if (!success && context.mounted) {
      final errorMsg = ref.read(accessRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Failed to reject request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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
