import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../models/access_request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/access_request_provider.dart';
import '../providers/user_provider.dart';
import 'shimmer_widgets.dart';

/// Compact card to display access request on home/search screens.
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
    final canHide = request.canHide;
    final statusColor = _getStatusColor();
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
    final labelText = isReceived ? 'From: @' : 'To: @';

    return userAsync.when(
      loading: () => const ShimmerCard(height: 140),
      error: (error, stackTrace) {
        // Fallback UI if user fetch fails
        return _buildCard(
          context,
          ref,
          userName: 'User ${userIdToFetch.substring(0, 8)}...',
          canHide: canHide,
          statusColor: statusColor,
          isReceived: isReceived,
          labelText: labelText,
          canOpenDetails: canOpenDetails,
          showActions: showActions,
        );
      },
      data: (user) => _buildCard(
        context,
        ref,
        userName: user.username,
        canHide: canHide,
        statusColor: statusColor,
        isReceived: isReceived,
        labelText: labelText,
        canOpenDetails: canOpenDetails,
        showActions: showActions,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref, {
    required String userName,
    required bool canHide,
    required Color statusColor,
    required bool isReceived,
    required String labelText,
    required bool canOpenDetails,
    required bool showActions,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: InkWell(
        onTap: canOpenDetails ? () => _openRequesterDetails(context, request) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isReceived ? 'Access Request' : 'Request Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: canOpenDetails
                                  ? AppTheme.textHint
                                  : AppTheme.textHint.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$labelText$userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      request.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons - ONLY show if received and pending
              if (showActions)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(context, ref, request.id),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'Reject',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _approveRequest(context, ref, request.id),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          'Approve',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          request.status.name == 'approved'
                              ? 'Access granted'
                              : request.status.name == 'rejected'
                                  ? 'Request rejected'
                                  : 'Request pending',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: request.status.name == 'approved'
                                    ? AppTheme.success
                                    : request.status.name == 'rejected'
                                        ? AppTheme.error
                                        : AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    if (canHide)
                      TextButton.icon(
                        onPressed: () => _clearRequest(context, ref),
                        icon: const Icon(Icons.hide_source, size: 16),
                        label: const Text('Hide'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (request.status) {
      case AccessStatus.pending:
        return Colors.orange;
      case AccessStatus.approved:
        return Colors.green;
      case AccessStatus.rejected:
        return Colors.red;
    }
  }

  static String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final requestDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (requestDate == today) {
      return 'Today';
    } else if (requestDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${requestDate.year}-${requestDate.month.toString().padLeft(2, '0')}-${requestDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.approveRequest(requestId);
    final currentUser = ref.read(authProvider).user;

    if (success && currentUser != null) {
      await Future.wait([
        notifier.loadReceivedRequests(currentUser.id),
        notifier.loadSentRequests(currentUser.id),
      ]);
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request approved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (!success && context.mounted) {
      final errorMsg = ref.read(accessRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Failed to approve request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
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
    final currentUser = ref.read(authProvider).user;

    if (success && currentUser != null) {
      await Future.wait([
        notifier.loadReceivedRequests(currentUser.id),
        notifier.loadSentRequests(currentUser.id),
      ]);
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request rejected'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
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
